import "package:flutter/widgets.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/dart.dart";
import "package:re_highlight/languages/javascript.dart";
import "package:re_highlight/languages/json.dart";
import "package:re_highlight/languages/php.dart";
import "package:re_highlight/languages/python.dart";
import "package:re_highlight/languages/typescript.dart";
import "package:re_highlight/languages/java.dart";
import "package:re_highlight/languages/kotlin.dart";
import "package:re_highlight/languages/go.dart";
import "package:re_highlight/languages/rust.dart";
import "package:re_highlight/languages/c.dart";
import "package:re_highlight/languages/cpp.dart";
import "package:re_highlight/languages/csharp.dart";
import "package:re_highlight/languages/swift.dart";
import "package:re_highlight/languages/ruby.dart";
import "package:re_highlight/languages/sql.dart";
import "package:re_highlight/languages/css.dart";
import "package:re_highlight/languages/scss.dart";
import "package:re_highlight/languages/xml.dart";
import "package:re_highlight/languages/yaml.dart";
import "package:re_highlight/languages/shell.dart";
import "package:re_highlight/languages/gradle.dart";
import "package:re_highlight/languages/dockerfile.dart";
import "package:re_highlight/languages/makefile.dart";
import "package:re_highlight/re_highlight.dart";

import "language_members.dart";
import "completion_ranker.dart";
import "language_snippets.dart";

/// Extracts identifier-like words from editor text.
final RegExp _identifierPattern = RegExp(r"[A-Za-z_][A-Za-z0-9_]{2,}");

/// Upper bound for document-word prompts merged into a single result.
const int _maxDocumentWords = 300;

/// Combines four prompt sources for a re_highlight [Mode] language:
/// (a) the language's own keywords, via an internal
/// [DefaultCodeAutocompletePromptsBuilder] (which reads the `keyword`,
/// `built_in`, `literal` and `type` lists from [Mode.keywords]),
/// (b) the single-line snippets from [languageSnippets] for [languageId],
/// passed as `directPrompts` so they share the same prefix matching,
/// (c) identifier words from the edited text, wrapped as
/// [CodeKeywordPrompt] and appended after the delegate results,
/// (d) cached LSP completions via [externalPrompts] (filled asynchronously
/// by the editor wiring; the sync [build] contract merges them when present).
///
/// Matching is JetBrains-style fuzzy ([fuzzyScore] in `completion_ranker.dart`)
/// instead of the prefix-only [CodePrompt.match]: the delegate still supplies
/// its prefix hits, and every pool is additionally fuzzy-filtered and ranked
/// so `prln` finds `println` and `lgo` still offers `log`.
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

  /// Cached LSP completions merged on top of local candidates.
  ///
  /// The [build] contract is synchronous, so live server results are fetched
  /// elsewhere (debounced, with timeout) and parked here; the next keystroke
  /// merges them into the popup without blocking typing.
  List<CodePrompt> externalPrompts = const [];

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
    if (identical(mode, langTypescript)) {
      return "typescript";
    }
    if (identical(mode, langJava)) {
      return "java";
    }
    if (identical(mode, langKotlin)) {
      return "kotlin";
    }
    if (identical(mode, langGo)) {
      return "go";
    }
    if (identical(mode, langRust)) {
      return "rust";
    }
    if (identical(mode, langC)) {
      return "c";
    }
    if (identical(mode, langCpp)) {
      return "cpp";
    }
    if (identical(mode, langCsharp)) {
      return "csharp";
    }
    if (identical(mode, langSwift)) {
      return "swift";
    }
    if (identical(mode, langRuby)) {
      return "ruby";
    }
    if (identical(mode, langSql)) {
      return "sql";
    }
    if (identical(mode, langCss)) {
      return "css";
    }
    if (identical(mode, langScss)) {
      return "scss";
    }
    if (identical(mode, langXml)) {
      return "xml";
    }
    if (identical(mode, langYaml)) {
      return "yaml";
    }
    if (identical(mode, langShell)) {
      return "shell";
    }
    if (identical(mode, langGradle)) {
      return "gradle";
    }
    if (identical(mode, langDockerfile)) {
      return "dockerfile";
    }
    if (identical(mode, langMakefile)) {
      return "makefile";
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

  /// Matches `receiver->partial|` at the caret (PHP object operator).
  /// The receiver may carry one leading `$` (`$request->input`); it is
  /// stripped for lookup (raw first, then stripped).
  static final RegExp _arrowPattern =
      RegExp(r"([A-Za-z_$][A-Za-z0-9_$]*)->([A-Za-z_$][A-Za-z0-9_$]*)?$");

  /// Matches `receiver::partial|` at the caret (PHP/C++/Rust scope
  /// resolution). The receiver never starts with `$`, so a lone `:`
  /// (ternary/label) or `<...>` generics can never match.
  static final RegExp _scopePattern =
      RegExp(r"([A-Za-z_][A-Za-z0-9_$]*)::([A-Za-z_$][A-Za-z0-9_$]*)?$");

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
    final Set<String> seen = <String>{};
    final List<CodePrompt> merged = <CodePrompt>[];
    if (base != null) {
      for (final prompt in base.prompts) {
        if (seen.add(prompt.word)) merged.add(prompt);
      }
    }
    // Fuzzy extras the prefix-only delegate missed: keywords (re-extracted
    // so subsequence hits like `prln`->`println` surface), snippets under
    // an alias, document words, and cached LSP items.
    final List<CodePrompt> fuzzyPool = <CodePrompt>[
      ...extractLanguageKeywords(language),
      ..._snippets,
      ..._documentWordCandidates(
        source: documentText ?? codeLine.text,
        excludedWords: seen,
      ),
      ...externalPrompts,
    ];
    final List<CodePrompt> ranked = rankPrompts(
      fuzzyPool.where((p) => !seen.contains(p.word)).toList(),
      input,
    );
    for (final prompt in ranked) {
      if (seen.add(prompt.word)) merged.add(prompt);
    }
    if (merged.isEmpty) return null;
    // Final JetBrains-style ordering across all pools.
    final List<CodePrompt> ordered = rankPrompts(merged, input, limit: 50);
    if (ordered.isEmpty) {
      return base ??
          CodeAutocompleteEditingValue(input: input, prompts: merged, index: 0);
    }
    return CodeAutocompleteEditingValue(
      input: input,
      prompts: ordered,
      index: 0,
    );
  }

  /// Detects a member access (`receiver.partial`, `receiver->partial`,
  /// or `receiver::partial`) immediately before the caret and returns its
  /// prompts, or null to use the normal flow.
  /// Matching is fuzzy so `con.lgo` still offers `log`. When several
  /// operators could match at the caret, the rightmost (nearest-caret) one
  /// wins; a match ending elsewhere falls through to the normal flow.
  CodeAutocompleteEditingValue? _memberCompletion(
    String lineText,
    CodeLineSelection selection,
  ) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    if (_isInsideString(lineText, selection)) {
      return null;
    }
    final String before = lineText.substring(0, end);
    final RegExpMatch? dotMatch = _memberPattern.firstMatch(before);
    final RegExpMatch? arrowMatch = _arrowPattern.firstMatch(before);
    final RegExpMatch? scopeMatch = _scopePattern.firstMatch(before);
    // Each pattern is `$`-anchored, so a hit always ends at the caret;
    // the explicit end check keeps the anchor contract obvious.
    RegExpMatch? best;
    bool bestIsArrow = false;
    void consider(RegExpMatch? candidate, bool isArrow) {
      if (candidate == null || candidate.end != end) {
        return;
      }
      if (best == null || candidate.start > best!.start) {
        best = candidate;
        bestIsArrow = isArrow;
      }
    }

    consider(dotMatch, false);
    consider(arrowMatch, true);
    consider(scopeMatch, false);
    final RegExpMatch? match = best;
    if (match == null) {
      return null;
    }
    final String receiver = match.group(1)!;
    final String partial = match.group(2) ?? "";
    List<CodePrompt>? all = MemberRegistry.membersFor(
      languageId,
      receiver,
    );
    // PHP variables carry `$` (`$request->input`) while tables register
    // bare keys (`request`): try the raw receiver first so `$foo` keys
    // keep working, then one stripped `$`.
    if (all == null &&
        bestIsArrow &&
        receiver.startsWith(r"$") &&
        receiver.length > 1) {
      all = MemberRegistry.membersFor(
        languageId,
        receiver.substring(1),
      );
    }
    if (all == null) {
      // Unknown receiver: fall back to the legacy prefix lookup (usually
      // null too) so behavior never regresses.
      List<CodePrompt>? legacy = memberPrompts(languageId, receiver, partial);
      if (legacy == null &&
          bestIsArrow &&
          receiver.startsWith(r"$") &&
          receiver.length > 1) {
        legacy = memberPrompts(
          languageId,
          receiver.substring(1),
          partial,
        );
      }
      if (legacy == null) return null;
      return CodeAutocompleteEditingValue(
        input: partial,
        prompts: legacy,
        index: 0,
      );
    }
    final List<CodePrompt> ranked = rankPrompts(
      all,
      partial,
      memberContext: true,
    );
    if (ranked.isEmpty) return null;
    return CodeAutocompleteEditingValue(
      input: partial,
      prompts: ranked,
      index: 0,
    );
  }

  /// Raw identifier candidates from [source] (unfiltered); fuzzy ranking
  /// happens in [build] so prefix and subsequence hits share one ordering.
  List<CodePrompt> _documentWordCandidates({
    required String source,
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
      if (!seen.add(word)) {
        continue;
      }
      prompts.add(CodeKeywordPrompt(word: word));
    }
    return prompts;
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
