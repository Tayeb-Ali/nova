import "../../core/services/search_service.dart";
import "go_lsp_manager.dart";
import "lsp_client.dart";

/// Jump target resolved by [DefinitionService]: 0-based [line] in [path].
/// Follows the `open(path, initialLine:)` contract used across the
/// workspace (search hits, now go-to-definition).
class DefinitionTarget {
  const DefinitionTarget({required this.path, required this.line});

  final String path;
  final int line;
}

/// Extract the symbol under [offset] in [lineText] (`foo` in `foo(`,
/// `input` in `$request->inp`). A leading `$` (PHP variables) is stripped;
/// returns null when the caret is not on a word.
String? wordAtCaret(String lineText, int offset) {
  final int end = offset.clamp(0, lineText.length);
  bool isWordChar(int c) =>
      (c >= 65 && c <= 90) ||
      (c >= 97 && c <= 122) ||
      (c >= 48 && c <= 57) ||
      c == 95 ||
      c == 36;
  int start = end;
  while (start > 0 && isWordChar(lineText.codeUnitAt(start - 1))) {
    start--;
  }
  int stop = end;
  while (stop < lineText.length && isWordChar(lineText.codeUnitAt(stop))) {
    stop++;
  }
  if (start >= stop) return null;
  var word = lineText.substring(start, stop);
  while (word.startsWith(r"$")) {
    word = word.substring(1);
  }
  return word.isEmpty ? null : word;
}

/// Resolves "go to definition": LSP first, text search as fallback.
///
/// Best-effort by contract: any failure (no server, timeout, no textual
/// match) yields null and callers show a toast — editing never breaks.
class DefinitionService {
  DefinitionService({required this._lsp, required this._search});

  final GoLspManager _lsp;
  final SearchService _search;

  /// Total budget for the LSP attempt (sync + lookup). A wedged server
  /// spawn has no internal timeout, so without this cap a stuck server
  /// would hang the tap forever instead of degrading to text search.
  static const Duration _lspBudget = Duration(seconds: 10);

  /// Resolve the definition of [word] used at ([line], [character],
  /// 0-based) in [filePath]. [currentText] is the unsaved buffer, synced
  /// to the server first so positions stay accurate while typing.
  Future<DefinitionTarget?> resolve({
    required String projectPath,
    required String language,
    required String filePath,
    required int line,
    required int character,
    required String word,
    String? currentText,
  }) async {
    if (word.isEmpty) return null;
    // 1. Language server: exact, scope-aware (methods, imports, generics).
    try {
      final LspLocation? location = await (() async {
        if (currentText != null) {
          await _lsp.didChangeFile(
            projectPath,
            filePath,
            language,
            currentText,
          );
        }
        return _lsp.definitionFor(
          projectPath,
          language,
          filePath,
          line,
          character,
        );
      })().timeout(_lspBudget);
      if (location != null) {
        return DefinitionTarget(path: location.path, line: location.line);
      }
    } catch (_) {
      // Fall through to text search.
    }
    // 2. Text fallback: declaration-shaped lines for [word].
    return _searchText(projectPath, language, filePath, word);
  }

  Future<DefinitionTarget?> _searchText(
    String projectPath,
    String language,
    String filePath,
    String word,
  ) async {
    final String pattern = _definitionPattern(language, word);
    ProjectSearchResult result;
    try {
      result = await _search.search(
        projectPath,
        pattern,
        const SearchOptions(
          regex: true,
          caseSensitive: true,
          maxFiles: 200,
          maxHits: 50,
        ),
      );
    } catch (_) {
      return null;
    }
    if (result.hits.isEmpty) return null;
    // The current file wins (a same-file declaration sits next to the
    // usage); otherwise the first project hit wins.
    SearchHit best = result.hits.first;
    for (final SearchHit hit in result.hits) {
      if (hit.path == filePath) {
        best = hit;
        break;
      }
    }
    return DefinitionTarget(path: best.path, line: best.line - 1);
  }

  /// Single regex matching declaration lines for [word] in [language].
  /// Keyword forms first (`def foo`, `class Foo`), then declarators
  /// (`const foo =`), then C-style signatures (`int foo() {`, which also
  /// covers Java/Kotlin/Dart methods). Lines are matched one by one by
  /// the search service, so `^`/`$` anchor to the line.
  static String _definitionPattern(String language, String word) {
    final String name = RegExp.escape(word);
    final List<String> keywords = _definitionKeywords(language);
    final List<String> alternatives = <String>[
      '(?:${keywords.join("|")})\\s+$name\\b',
      if (_hasConstDeclarator(language))
        '^\\s*(?:const|let|var|val|final)\\s+$name\\s*[:=]',
      if (_hasCFunc(language))
        '^\\s*\\w[\\w\\s:*&<>?]*\\s+$name\\s*\\([^;]*\$',
      // Expression bodies end in `;` (`String greet() => 'hi';`), so the
      // call-site guard above rejects them: match the `=>` explicitly.
      if (_hasArrowBody(language))
        '^\\s*\\w[\\w\\s:*&<>?]*\\s+$name\\s*\\([^)]*\\)\\s*=>',
    ];
    return alternatives.join('|');
  }

  static List<String> _definitionKeywords(String language) {
    switch (language) {
      case 'python':
        return const ['def', 'class'];
      case 'ruby':
        return const ['def', 'class', 'module'];
      case 'php':
        return const ['function', 'class', 'interface', 'trait', 'enum'];
      case 'dart':
        return const ['class', 'mixin', 'extension', 'enum', 'typedef'];
      case 'javascript':
      case 'typescript':
      case 'node':
        return const ['function', 'class', 'interface', 'type', 'enum'];
      case 'java':
        return const ['class', 'interface', 'enum', 'record'];
      case 'kotlin':
        return const ['class', 'interface', 'enum', 'fun', 'object'];
      case 'csharp':
        return const ['class', 'interface', 'enum', 'struct', 'record'];
      case 'swift':
        return const ['func', 'class', 'struct', 'enum', 'protocol'];
      case 'go':
        return const ['func', 'type'];
      case 'rust':
        return const ['fn', 'struct', 'enum', 'trait', 'mod'];
      case 'cpp':
        return const ['class', 'struct', 'enum'];
      case 'c':
        return const ['struct', 'enum'];
      default:
        return const ['function', 'def', 'fn', 'func', 'class'];
    }
  }

  static bool _hasConstDeclarator(String language) {
    switch (language) {
      case 'javascript':
      case 'typescript':
      case 'node':
      case 'dart':
      case 'kotlin':
      case 'swift':
        return true;
      default:
        return false;
    }
  }

  static bool _hasCFunc(String language) {
    switch (language) {
      case 'dart':
      case 'java':
      case 'kotlin':
      case 'csharp':
      case 'swift':
      case 'c':
      case 'cpp':
        return true;
      default:
        return false;
    }
  }

  static bool _hasArrowBody(String language) {
    switch (language) {
      case 'dart':
      case 'csharp':
        return true;
      default:
        return false;
    }
  }
}
