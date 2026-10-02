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
import "completion_assists.dart";
import "completion_ranker.dart";
import "language_snippets.dart";

/// Extracts identifier-like words from editor text (two or more
/// characters: single-letter variables are noise, but `id`, `db`, `os`
/// deserve suggestions like any longer name).
final RegExp _identifierPattern = RegExp(r"[A-Za-z_][A-Za-z0-9_]+");

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

  /// Matches `receiver.postfix|` at the caret, where the receiver may be a
  /// dotted chain (`a.b.if` keeps the whole chain). Same `$`-anchoring
  /// style as the member patterns: the match must end exactly at the caret.
  /// The segment after the LAST dot must be exactly a postfix keyword.
  static final RegExp _postfixPattern = RegExp(
    r"([A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*)"
    r"\.(if|else|for|while|log|not|null)$",
  );

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    // Inside a string literal neither members nor keywords apply. Without
    // this, the delegate's null (its own string guard) would fall through
    // to snippet/document-word suggestions for the quoted text.
    if (_isInsideString(codeLine.text, selection)) {
      return null;
    }
    // Member completions win over keywords: `console.` offers log/error/…
    final memberResult = _memberCompletion(codeLine.text, selection);
    if (memberResult != null) {
      return memberResult;
    }
    // Postfix templates (`expr.if` -> `if (expr) {}`) win over keywords but
    // never over real members: the check above already returned for any
    // receiver whose table fuzzy-matches, and [_postfixCompletion] itself
    // stays silent while the receiver owns a member table at all.
    final postfixResult = _postfixCompletion(codeLine.text, selection);
    if (postfixResult != null) {
      return postfixResult;
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

  /// Detects `receiver.postfixKeyword|` immediately before the caret and
  /// returns the single snippet-style prompt expanding around the receiver,
  /// or null to use the normal flow.
  ///
  /// The offered prompt's word is the full typed text (for example
  /// `expr.if`) so accepting it REPLACES the whole `receiver.keyword`
  /// span; the expansion parks the caret per [postfixExpansion]. Fires
  /// only when the receiver's last segment owns NO member table (real
  /// member completion always wins) and the language supports the
  /// keyword's syntax. The string-literal guard in [build] already ran.
  CodeAutocompleteEditingValue? _postfixCompletion(
    String lineText,
    CodeLineSelection selection,
  ) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    final String before = lineText.substring(0, end);
    final RegExpMatch? match = _postfixPattern.firstMatch(before);
    if (match == null || match.end != end) {
      return null;
    }
    final String receiver = match.group(1)!;
    final String keyword = match.group(2)!;
    // Real members always win: suppress while the immediate receiver (last
    // chain segment) owns a member table. PHP `$x` tries raw, then bare.
    final String immediate = receiver.split(".").last;
    if (_hasMemberTable(immediate)) {
      return null;
    }
    final ({String expansion, int caretOffset})? template =
        postfixExpansion(languageId, receiver, keyword);
    if (template == null) {
      return null;
    }
    final String fullTyped = "$receiver.$keyword";
    return CodeAutocompleteEditingValue(
      input: fullTyped,
      prompts: <CodePrompt>[
        CodeFieldPrompt(
          word: fullTyped,
          type: snippetPromptType,
          customAutocomplete: CodeAutocompleteResult(
            input: "",
            word: template.expansion,
            selection: TextSelection.collapsed(offset: template.caretOffset),
          ),
        ),
      ],
      index: 0,
    );
  }

  /// True when [receiver] owns a member table in the current language
  /// (PHP `$`-prefixed receivers also try the stripped name).
  bool _hasMemberTable(String receiver) {
    if (MemberRegistry.membersFor(languageId, receiver) != null) {
      return true;
    }
    if (receiver.startsWith(r"$") && receiver.length > 1) {
      return MemberRegistry.membersFor(
            languageId,
            receiver.substring(1),
          ) !=
          null;
    }
    return false;
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

  /// String-literal guard: suppresses suggestions while the caret sits
  /// inside `'...'` or `"..."` on the current line.
  ///
  /// Two conditions, both required:
  /// * an ODD count of unescaped quotes before the caret (parity: the
  ///   caret is inside an opened literal; `"a" + x` is even, so code
  ///   between two literals keeps completing — the old "quote on both
  ///   sides" check wrongly suppressed that);
  /// * a quote character after the caret (the literal's closer; this
  ///   keeps completion working in unterminated strings and after lone
  ///   apostrophes such as `// don't`, matching the delegate's contract).
  /// Escaped quotes (`\"`, `\'`) never toggle the parity.
  static bool _isInsideString(String lineText, CodeLineSelection selection) {
    final int end = selection.extentOffset.clamp(0, lineText.length);
    final String before = lineText.substring(0, end);
    final String after = lineText.substring(end);
    if (!after.contains("'") && !after.contains('"')) return false;
    return _hasOddUnescapedQuote(before, "'") ||
        _hasOddUnescapedQuote(before, '"');
  }

  /// Counts [quote] occurrences in [text] that are NOT escaped (preceded
  /// by an even run of backslashes) and reports odd parity.
  static bool _hasOddUnescapedQuote(String text, String quote) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] != quote) continue;
      int slashes = 0;
      int j = i - 1;
      while (j >= 0 && text.codeUnitAt(j) == 92) {
        slashes++;
        j--;
      }
      if (slashes.isEven) count++;
    }
    return count.isOdd;
  }
}
