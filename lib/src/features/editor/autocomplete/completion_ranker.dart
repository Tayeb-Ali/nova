import "package:re_editor/re_editor.dart";
import "package:re_highlight/re_highlight.dart";

/// JetBrains-style fuzzy matching and ranking for completion candidates.
///
/// `re_editor`'s built-in [CodePrompt.match] is prefix-only
/// (`word.startsWith(input)`), so typing `prln` never suggests `println`,
/// and `log` after `console.lgo` finds nothing. This helper adds the
/// forgiving matching users expect from JetBrains IDEs while keeping the
/// standard [CodePrompt]/[CodeAutocompleteResult] application mechanism
/// untouched: we only decide *which* prompts are shown and *in what order*.

/// Maximum prompts returned by [rankPrompts] (JetBrains shows ~50 rows).
const int kMaxCompletionPrompts = 50;

/// Scores [word] against the typed [input]. Higher is better, null means
/// no match and the candidate must be hidden.
///
/// Scoring (case-insensitive):
/// * exact match -> excluded by callers (re_editor hides `word == input`);
/// * prefix match -> 100 + length bonus (shorter wins ties);
/// * contiguous substring -> 60 + position bonus (earlier wins);
/// * camelCase / snake_case boundary match -> 75;
/// * ordered subsequence (fuzzy, e.g. `prln` -> `println`) -> 30 - gaps.
int? fuzzyScore(String word, String input) {
  if (input.isEmpty) return 50;
  if (word == input) return null;
  final String w = word.toLowerCase();
  final String q = input.toLowerCase();

  if (w.startsWith(q)) {
    // Shorter completions first: `print` beats `printlnExtra`.
    return 1000 - (word.length - input.length);
  }
  final int sub = w.indexOf(q);
  if (sub >= 0) {
    // Boundary hits (after `_`, `.`, or an upper-case hump in the
    // original word) feel intentional, like JetBrains' middle matching.
    if (_isBoundaryHit(word, sub)) return 750 - sub;
    return 600 - sub;
  }
  // Ordered subsequence with a gap penalty, capped so long words with
  // scattered letters don't outrank real substring hits.
  int wi = 0;
  int gaps = 0;
  int lastHit = -1;
  for (int qi = 0; qi < q.length; qi++) {
    final int hit = w.indexOf(q[qi], wi);
    if (hit < 0) return null;
    if (lastHit >= 0) gaps += hit - lastHit - 1;
    lastHit = hit;
    wi = hit + 1;
  }
  final int score = 300 - gaps * 15 - word.length;
  return score > 0 ? score : 1;
}

/// True when [word] fuzzy-matches [input] (including prefix/substring).
bool fuzzyMatches(String word, String input) => fuzzyScore(word, input) != null;

/// Character offsets in [word] that [input] covers, for popup highlighting.
/// Returns an empty list when there is no match.
List<int> fuzzyMatchIndices(String word, String input) {
  if (input.isEmpty) return const [];
  final String w = word.toLowerCase();
  final String q = input.toLowerCase();
  if (w.startsWith(q)) {
    return List<int>.generate(input.length, (i) => i);
  }
  final int sub = w.indexOf(q);
  if (sub >= 0) {
    return List<int>.generate(input.length, (i) => sub + i);
  }
  final List<int> out = [];
  int wi = 0;
  for (int qi = 0; qi < q.length; qi++) {
    final int hit = w.indexOf(q[qi], wi);
    if (hit < 0) return const [];
    out.add(hit);
    wi = hit + 1;
  }
  return out;
}

bool _isBoundaryHit(String word, int index) {
  if (index <= 0 || index >= word.length) return false;
  final int prev = word.codeUnitAt(index - 1);
  final int curr = word.codeUnitAt(index);
  // After `_`, `.`, `/`, `-`, or a lower->Upper hump (`printLn`).
  if (prev == 95 || prev == 46 || prev == 47 || prev == 45) return true;
  final bool prevLower = prev >= 97 && prev <= 122;
  final bool currUpper = curr >= 65 && curr <= 90;
  return prevLower && currUpper;
}

/// Priority boost per prompt kind, applied on top of [fuzzyScore] so that
/// equally-good text matches order like JetBrains: exact-context members
/// first, then snippets, keywords, and finally document words.
int kindBoost(CodePrompt prompt, {bool memberContext = false}) {
  if (memberContext) {
    if (prompt is CodeFunctionPrompt) return 200;
    if (prompt is CodeFieldPrompt) return 150;
    return 100;
  }
  if (prompt is CodeFunctionPrompt) return 60;
  // Snippets are CodeFieldPrompts flagged via `type == snippetPromptType`,
  // but the ranker stays decoupled from that constant: any field prompt
  // outranks a bare keyword.
  if (prompt is CodeFieldPrompt) return 80;
  return 0;
}

/// Filters [candidates] by [input] with [fuzzyScore] and returns them best
/// first (score + [kindBoost], stable for ties). Exact duplicates
/// (`word == input`) are dropped, mirroring [CodePrompt.match].
List<CodePrompt> rankPrompts(
  List<CodePrompt> candidates,
  String input, {
  bool memberContext = false,
  int limit = kMaxCompletionPrompts,
}) {
  final List<({CodePrompt prompt, int score})> scored = [];
  for (final prompt in candidates) {
    final int? base = fuzzyScore(prompt.word, input);
    if (base == null) continue;
    scored.add((
      prompt: prompt,
      score: base + kindBoost(prompt, memberContext: memberContext),
    ));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return [
    for (int i = 0; i < scored.length && i < limit; i++) scored[i].prompt,
  ];
}

/// All keyword prompts for [language], mirroring the extraction inside
/// `re_editor`'s private `_DefaultCodeAutocompletePromptsBuilder` (it reads
/// the `keyword`, `built_in`, `literal` and `type` lists from
/// [Mode.keywords], which is the only public surface available).
List<CodeKeywordPrompt> extractLanguageKeywords(Mode? language) {
  final dynamic keywords = language?.keywords;
  if (keywords is! Map) return const [];
  final List<CodeKeywordPrompt> out = [];
  for (final key in const ["keyword", "built_in", "literal", "type"]) {
    final dynamic list = keywords[key];
    if (list is List) {
      for (final item in list) {
        if (item is String && item.isNotEmpty) {
          out.add(CodeKeywordPrompt(word: item));
        }
      }
    }
  }
  return out;
}
