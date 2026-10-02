import 'dart:async';

import 'package:re_editor/re_editor.dart';

import 'ai_client.dart';

/// Trigger + budget policy for AI inline completion, kept in one place.
///
/// Conservative by design: suggestions only fire after a typing idle gap,
/// on word characters, in non-trivial files, with capped context and a
/// short timeout so a slow network never blocks typing.
abstract final class AiCompletionPolicy {
  /// Idle gap after the last keystroke before a fetch fires.
  static const Duration debounce = Duration(milliseconds: 800);

  /// Per-fetch network budget (mirrors `kLspRequestTimeout`).
  static const Duration fetchTimeout = Duration(seconds: 3);

  /// Files at or below this length never trigger a fetch.
  static const int minDocumentChars = 50;

  /// Kept prefix context cap (the tail closest to the caret wins).
  static const int maxPrefixChars = 2000;

  /// Kept suffix context cap (the head closest to the caret wins).
  static const int maxSuffixChars = 1000;

  /// Kept prefix lines cap (the lines closest to the caret win).
  static const int maxContextLines = 40;

  /// Longest suggestion kept after sanitizing.
  static const int maxCompletionChars = 300;

  /// Token budget per fetch (a continuation, not a full answer).
  static const int maxTokens = 128;

  /// Straight failures before the provider mutes itself.
  static const int maxConsecutiveFailures = 3;

  /// Whether a fetch may fire: the feature flag is on, the document is
  /// non-trivial, and the caret sits right after a word character (so idle
  /// whitespace, fresh newlines, and just-typed punctuation cost nothing).
  static bool shouldFetch({
    required bool enabled,
    required String documentText,
    required String prefix,
  }) {
    if (!enabled) return false;
    if (documentText.length <= minDocumentChars) return false;
    if (prefix.isEmpty) return false;
    return _isWordChar(prefix.codeUnitAt(prefix.length - 1));
  }

  static bool _isWordChar(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        (codeUnit >= 48 && codeUnit <= 57) ||
        codeUnit == 95;
  }
}

/// AI-backed inline code completion over the existing [AiClient].
///
/// [suggest] returns one trimmed continuation at the caret, or null when
/// there is nothing usable. It NEVER throws: missing API key, timeouts,
/// provider errors, and unexpected exceptions all resolve to null. After
/// [AiCompletionPolicy.maxConsecutiveFailures] straight failures the
/// provider mutes itself (no more network) until [reset], which the editor
/// wiring calls on the next file open.
class AiCompletionProvider {
  AiCompletionProvider({
    AiClient? client,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.timeout = AiCompletionPolicy.fetchTimeout,
    this.maxTokens = AiCompletionPolicy.maxTokens,
  }) : _client = client ?? AiClient();

  final AiClient _client;

  /// Endpoint base URL (from settings).
  final String baseUrl;

  /// API key (from secure storage); blank disables fetching silently.
  final String apiKey;

  /// Model name (from settings).
  final String model;

  /// Per-fetch network budget.
  final Duration timeout;

  /// Token budget per fetch.
  final int maxTokens;

  int _consecutiveFailures = 0;

  /// True once failures muted this provider; cleared by [reset].
  bool get isMuted =>
      _consecutiveFailures >= AiCompletionPolicy.maxConsecutiveFailures;

  /// Clears the failure backoff (called on the next file open).
  void reset() {
    _consecutiveFailures = 0;
  }

  /// Returns the continuation at the caret, or null on any failure.
  ///
  /// [prefix] is the full document text before the caret, [suffix] the
  /// full text after it; both are capped into a compact prompt internally
  /// so huge files are never sent whole.
  Future<String?> suggest({
    required String language,
    required String prefix,
    required String suffix,
  }) async {
    if (isMuted || apiKey.trim().isEmpty) return null;
    try {
      final String raw = await _client
          .call(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            messages: buildMessages(
              language: language,
              prefix: prefix,
              suffix: suffix,
            ),
            maxTokens: maxTokens,
          )
          .timeout(timeout);
      final String? clean = sanitize(raw);
      if (clean == null) {
        _consecutiveFailures++;
        return null;
      }
      _consecutiveFailures = 0;
      return clean;
    } catch (_) {
      _consecutiveFailures++;
      return null;
    }
  }

  /// Builds the compact chat prompt: language + ~40 lines around the
  /// caret with capped characters, marked with a `<caret>` token.
  static List<Map<String, String>> buildMessages({
    required String language,
    required String prefix,
    required String suffix,
  }) {
    final List<String> lines = prefix.split('\n');
    final List<String> kept = lines.length > AiCompletionPolicy.maxContextLines
        ? lines.sublist(lines.length - AiCompletionPolicy.maxContextLines)
        : lines;
    String before = kept.join('\n');
    if (before.length > AiCompletionPolicy.maxPrefixChars) {
      before = before.substring(
        before.length - AiCompletionPolicy.maxPrefixChars,
      );
    }
    final String after = suffix.length > AiCompletionPolicy.maxSuffixChars
        ? suffix.substring(0, AiCompletionPolicy.maxSuffixChars)
        : suffix;
    return <Map<String, String>>[
      const <String, String>{
        'role': 'system',
        'content': 'You complete code. Reply with ONLY the code that '
            'continues at <caret>: no explanations, no markdown fences.',
      },
      <String, String>{
        'role': 'user',
        'content': 'Language: $language\n$before<caret>$after',
      },
    ];
  }

  /// Strips markdown fences, trims, and caps length; null when nothing
  /// usable remains.
  static String? sanitize(String raw) {
    String text = raw.trim();
    if (text.startsWith('```')) {
      final int newline = text.indexOf('\n');
      text = (newline < 0 ? '' : text.substring(newline + 1)).trimLeft();
    }
    text = text.trim();
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3).trimRight();
    }
    text = text.trim();
    if (text.isEmpty) return null;
    if (text.length > AiCompletionPolicy.maxCompletionChars) {
      text = text
          .substring(0, AiCompletionPolicy.maxCompletionChars)
          .trimRight();
    }
    return text.isEmpty ? null : text;
  }

  /// Wraps a [suggestion] continuation as a popup prompt.
  ///
  /// The parked word is `input + suggestion` (unless the model echoed the
  /// typed input, which is not doubled): the popup's fuzzy ranker only
  /// keeps candidates matching the typed input, so a bare continuation
  /// would be filtered out, while the joined form prefix-matches and
  /// ranks first. Accepting it replaces exactly the typed word, which is
  /// the standard [CodeAutocompleteResult] application — zero custom
  /// rendering, with free keyboard/mouse acceptance. The `AI` type shows
  /// as the row detail so the source is visible.
  static CodePrompt promptFor({
    required String input,
    required String suggestion,
  }) {
    final String word =
        input.isNotEmpty && suggestion.startsWith(input)
            ? suggestion
            : '$input$suggestion';
    return CodeFieldPrompt(word: word, type: 'AI');
  }
}
