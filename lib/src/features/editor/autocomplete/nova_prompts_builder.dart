import "package:flutter/widgets.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/dart.dart";
import "package:re_highlight/languages/javascript.dart";
import "package:re_highlight/languages/json.dart";
import "package:re_highlight/languages/php.dart";
import "package:re_highlight/languages/python.dart";
import "package:re_highlight/re_highlight.dart";

import "language_members.dart";
import "language_snippets.dart";

/// Extracts identifier-like words from editor text.
final RegExp _identifierPattern = RegExp(r"[A-Za-z_][A-Za-z0-9_]{2,}");

/// Upper bound for document-word prompts merged into a single result.
const int _maxDocumentWords = 300;

/// Combines three prompt sources for a re_highlight [Mode] language:
/// (a) the language's own keywords, via an internal
/// [DefaultCodeAutocompletePromptsBuilder] (which reads the `keyword`,
/// `built_in`, `literal` and `type` lists from [Mode.keywords]),
/// (b) the single-line snippets from [languageSnippets] for [languageId],
/// passed as `directPrompts` so they share the same prefix matching,
/// (c) identifier words from the edited text, wrapped as
/// [CodeKeywordPrompt] and appended after the delegate results.
///
/// Composition is used instead of subclassing because
/// [DefaultCodeAutocompletePromptsBuilder] is an abstract factory whose
/// implementation (`_DefaultCodeAutocompletePromptsBuilder`) is private.
class NovaPromptsBuilder implements CodeAutocompletePromptsBuilder {
  /// Creates a builder for [language], selecting snippets by [languageId].
  ///
  /// When [languageId] is null, it is derived from [language] by identity
  /// comparison against the known re_highlight modes.
  NovaPromptsBuilder({Mode? language, String? languageId})
      : language = language,
        languageId =
            normalizeLanguageId(languageId) ?? _idForMode(language),
        _snippets = snippetsForLanguage(
            normalizeLanguageId(languageId) ?? _idForMode(language)) {
    _delegate = DefaultCodeAutocompletePromptsBuilder(
      language: this.language,
      directPrompts: _snippets,
    );
  }

  /// The highlight mode used for keyword extraction. May be null, in which
  /// case only snippets and document words are suggested.
  final Mode? language;

  /// Canonical snippet language id (for example "python"), or null when the
  /// language is unknown and no snippets apply.
  final String? languageId;

  /// Optional full document text scanned for identifier words.
  ///
  /// The [CodeAutocompletePromptsBuilder.build] contract only exposes the
  /// current [CodeLine], so when this is null the scan falls back to the
  /// current line. The wiring step can assign the whole buffer here to get
  /// true document-wide suggestions.
  String? documentText;

  final List<CodePrompt> _snippets;
  late final DefaultCodeAutocompletePromptsBuilder _delegate;

  static String? _idForMode(Mode? mode) {
    if (mode == null) {
      return null;
    }
    if (identical(mode, langPython)) {
      return "python";
    }
    if (identical(mode, langJavascript)) {
      return "javascript";
    }
    if (identical(mode, langPhp)) {
      return "php";
    }
    if (identical(mode, langDart)) {
      return "dart";
    }
    if (identical(mode, langJson)) {
      return "json";
    }
    return normalizeLanguageId(mode.name);
  }

  /// Matches `receiver.partial|` at the caret (VS Code member completion).
  static final RegExp _memberPattern =
      RegExp(r"([A-Za-z_$][A-Za-z0-9_$]*)\.([A-Za-z_$][A-Za-z0-9_$]*)?$");

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    // Member completions win over keywords: `console.` offers log/error/…
    final memberResult = _memberCompletion(codeLine.text, selection);
    if (memberResult != null) {
      return memberResult;
    }
    final CodeAutocompleteEditingValue? base =
        _delegate.build(context, codeLine, selection);
    final String input = base?.input ?? _extractInput(codeLine.text, selection);
    if (input.isEmpty) {
      return base;
    }
    if (base == null) {
      // No keyword or snippet matched (and we are not inside a string
      // literal): still offer snippet aliases and document words.
      if (_isInsideString(codeLine.text, selection)) {
        return null;
      }
      final List<CodePrompt> fallback = [
        ..._snippets.where((CodePrompt prompt) => prompt.match(input)),
        ..._documentWordPrompts(
          source: documentText ?? codeLine.text,
          input: input,
          excludedWords: _wordsOf(_snippets),
        ),
      ];
      if (fallback.isEmpty) {
        return null;
      }
      return CodeAutocompleteEditingValue(
        input: input,
        prompts: fallback,
        index: 0,
      );
    }
    final List<CodePrompt> words = _documentWordPrompts(
      source: documentText ?? codeLine.text,
      input: input,
      excludedWords: _wordsOf(base.prompts),
    );
    if (words.isEmpty) {
      return base;
    }
    return base.copyWith(prompts: [...base.prompts, ...words]);
  }

  /// Detects a member access (`receiver.partial`) immediately before the
  /// caret and returns its prompts, or null to use the normal flow.
  CodeAutocompleteEditingValue? _memberCompletion(
    String lineText,
    CodeLineSelection selection,
  ) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    if (_isInsideString(lineText, selection)) {
      return null;
    }
    final match = _memberPattern.firstMatch(lineText.substring(0, end));
    // Anchor at the caret: the match must end exactly where typing stopped.
    if (match == null || match.end != end) {
      return null;
    }
    final prompts = memberPrompts(
      languageId,
      match.group(1)!,
      match.group(2) ?? "",
    );
    if (prompts == null) {
      return null;
    }
    return CodeAutocompleteEditingValue(
      input: match.group(2) ?? "",
      prompts: prompts,
      index: 0,
    );
  }

  /// Collects identifier words from [source] that match [input], skipping
  /// words already suggested and capping the result at [_maxDocumentWords].
  List<CodePrompt> _documentWordPrompts({
    required String source,
    required String input,
    required Set<String> excludedWords,
  }) {
    final Set<String> seen = <String>{...excludedWords};
    final List<CodePrompt> prompts = <CodePrompt>[];
    for (final RegExpMatch match in _identifierPattern.allMatches(source)) {
      if (prompts.length >= _maxDocumentWords) {
        break;
      }
      final String word = match.group(0)!;
      // Pure numbers cannot match the pattern (it must start with a letter
      // or underscore); the guard below documents the contract explicitly.
      if (int.tryParse(word) != null) {
        continue;
      }
      final CodePrompt prompt = CodeKeywordPrompt(word: word);
      if (!prompt.match(input)) {
        continue;
      }
      if (!seen.add(word)) {
        continue;
      }
      prompts.add(prompt);
    }
    return prompts;
  }

  static Set<String> _wordsOf(List<CodePrompt> prompts) {
    return prompts.map((CodePrompt prompt) => prompt.word).toSet();
  }

  /// Replicates the delegate's typed-prefix extraction for the fallback
  /// path. Unlike upstream (ASCII letters plus underscore only) digits are
  /// accepted as well so identifiers such as "var2" keep working.
  static String _extractInput(String lineText, CodeLineSelection selection) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    int start = end - 1;
    while (start >= 0 && _isWordChar(lineText.codeUnitAt(start))) {
      start--;
    }
    return lineText.substring(start + 1, end);
  }

  static bool _isWordChar(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        (codeUnit >= 48 && codeUnit <= 57) ||
        codeUnit == 95;
  }

  /// Mirrors the delegate's string-literal guard: a quote character on both
  /// sides of the caret suppresses suggestions.
  static bool _isInsideString(String lineText, CodeLineSelection selection) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    final String before = lineText.substring(0, end);
    final String after = lineText.substring(end);
    return (before.contains("'") || before.contains("\"")) &&
        (after.contains("'") || after.contains("\""));
  }
}
