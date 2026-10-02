import 'package:flutter_test/flutter_test.dart';
import 'package:nova/src/features/ai/ai_client.dart';
import 'package:nova/src/features/ai/ai_completion_provider.dart';
import 'package:re_editor/re_editor.dart';

/// Fake client capturing calls without network.
class _FakeAiClient extends AiClient {
  _FakeAiClient({this.result = 'ok', this.error, this.delay = Duration.zero});

  final String result;
  final Object? error;
  final Duration delay;
  int calls = 0;

  @override
  Future<String> call({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int? maxTokens,
  }) async {
    calls++;
    if (delay > Duration.zero) await Future.delayed(delay);
    if (error != null) throw error!;
    return result;
  }
}

AiCompletionProvider _provider(
  _FakeAiClient client, {
  String apiKey = 'k',
  Duration timeout = const Duration(seconds: 3),
}) {
  return AiCompletionProvider(
    client: client,
    baseUrl: 'https://example.com/v1',
    apiKey: apiKey,
    model: 'm',
    timeout: timeout,
  );
}

String _longDoc() => 'void main() {\n  print("hello");\n}\n';

void main() {
  group('suggest', () {
    test('returns trimmed canned text', () async {
      final client = _FakeAiClient(result: '  print(x)  ');
      final result = await _provider(client).suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(result, 'print(x)');
      expect(client.calls, 1);
    });

    test('strips markdown fences', () async {
      final client = _FakeAiClient(result: '```dart\nfoo()\n```');
      final result = await _provider(client).suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(result, 'foo()');
    });

    test('empty or whitespace-only response resolves null', () async {
      for (final raw in <String>['', '   ', '```\n```']) {
        final client = _FakeAiClient(result: raw);
        expect(
          await _provider(client).suggest(
            language: 'dart',
            prefix: _longDoc(),
            suffix: '',
          ),
          isNull,
        );
      }
    });

    test('provider error resolves null and never throws', () async {
      final client = _FakeAiClient(error: const AiException('nope'));
      expect(
        await _provider(client).suggest(
          language: 'dart',
          prefix: _longDoc(),
          suffix: '',
        ),
        isNull,
      );
    });

    test('unexpected error resolves null and never throws', () async {
      final client = _FakeAiClient(error: StateError('boom'));
      expect(
        await _provider(client).suggest(
          language: 'dart',
          prefix: _longDoc(),
          suffix: '',
        ),
        isNull,
      );
    });

    test('slow client hits the short timeout and resolves null', () async {
      final client = _FakeAiClient(
        result: 'late',
        delay: const Duration(milliseconds: 500),
      );
      final result = await _provider(
        client,
        timeout: const Duration(milliseconds: 50),
      ).suggest(language: 'dart', prefix: _longDoc(), suffix: '');
      expect(result, isNull);
    });

    test('blank API key never calls the client', () async {
      final client = _FakeAiClient(result: 'x');
      final result = await _provider(client, apiKey: '  ').suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(result, isNull);
      expect(client.calls, 0);
    });

    test('mutes after 3 straight failures until reset', () async {
      final client = _FakeAiClient(error: const AiException('down'));
      final provider = _provider(client);
      for (var i = 0; i < 3; i++) {
        expect(
          await provider.suggest(
            language: 'dart',
            prefix: _longDoc(),
            suffix: '',
          ),
          isNull,
        );
      }
      expect(provider.isMuted, isTrue);
      expect(client.calls, 3);
      // Muted: no further network.
      expect(
        await provider.suggest(
          language: 'dart',
          prefix: _longDoc(),
          suffix: '',
        ),
        isNull,
      );
      expect(client.calls, 3);
      // Next file open clears the backoff.
      provider.reset();
      expect(provider.isMuted, isFalse);
      await provider.suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(client.calls, 4);
    });

    test('a success clears the failure streak', () async {
      final client = _FakeAiClient(error: const AiException('down'));
      final provider = _provider(client);
      await provider.suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      await provider.suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(provider.isMuted, isFalse);
      // Flip to success: streak resets, two more failures stay unmuted.
      final ok = _FakeAiClient(result: 'x');
      final provider2 = _provider(ok);
      await provider2.suggest(
        language: 'dart',
        prefix: _longDoc(),
        suffix: '',
      );
      expect(provider2.isMuted, isFalse);
    });
  });

  group('AiCompletionPolicy.shouldFetch', () {
    test('gates on flag, size, and word boundary', () {
      final doc = '${'x' * 60}foo';
      expect(
        AiCompletionPolicy.shouldFetch(
          enabled: false,
          documentText: doc,
          prefix: doc,
        ),
        isFalse,
      );
      expect(
        AiCompletionPolicy.shouldFetch(
          enabled: true,
          documentText: 'tiny',
          prefix: 'tiny',
        ),
        isFalse,
      );
      expect(
        AiCompletionPolicy.shouldFetch(
          enabled: true,
          documentText: doc,
          prefix: '',
        ),
        isFalse,
      );
      for (final tail in <String>[' ', '\n', '(', '.', ':']) {
        expect(
          AiCompletionPolicy.shouldFetch(
            enabled: true,
            documentText: doc,
            prefix: '${'x' * 60}$tail',
          ),
          isFalse,
          reason: 'tail $tail',
        );
      }
      for (final tail in <String>['o', '_', '2']) {
        expect(
          AiCompletionPolicy.shouldFetch(
            enabled: true,
            documentText: doc,
            prefix: '${'x' * 60}$tail',
          ),
          isTrue,
          reason: 'tail $tail',
        );
      }
    });
  });

  group('buildMessages', () {
    test('caps lines and chars and marks the caret', () {
      final prefix = List<String>.generate(100, (i) => 'line $i').join('\n');
      final suffix = 'y' * 2000;
      final messages = AiCompletionProvider.buildMessages(
        language: 'dart',
        prefix: prefix,
        suffix: suffix,
      );
      expect(messages.length, 2);
      final user = messages[1]['content']!;
      expect(user, contains('Language: dart'));
      expect(user, contains('<caret>'));
      expect(user, isNot(contains('line 0')));
      expect(user, contains('line 99'));
      final afterCaret = user.split('<caret>')[1];
      expect(afterCaret.length, lessThanOrEqualTo(1001));
    });

    test('caps a huge single-line prefix', () {
      final prefix = 'z' * 5000;
      final messages = AiCompletionProvider.buildMessages(
        language: 'python',
        prefix: prefix,
        suffix: '',
      );
      final user = messages[1]['content']!;
      final beforeCaret = user.split('<caret>')[0];
      expect(
        beforeCaret.length,
        lessThanOrEqualTo(
          'Language: python\n'.length +
              AiCompletionPolicy.maxPrefixChars,
        ),
      );
    });
  });

  group('sanitize', () {
    test('caps length at 300 chars', () {
      final out = AiCompletionProvider.sanitize('a' * 400)!;
      expect(out.length, lessThanOrEqualTo(300));
    });

    test('null on empty after stripping', () {
      expect(AiCompletionProvider.sanitize('   '), isNull);
      expect(AiCompletionProvider.sanitize('```\n```'), isNull);
    });
  });

  group('promptFor', () {
    test('joins typed input with the continuation as an AI row', () {
      final prompt = AiCompletionProvider.promptFor(
        input: 'prin',
        suggestion: 'tln(x)',
      );
      expect(prompt, isA<CodeFieldPrompt>());
      expect(prompt.word, 'println(x)');
      expect((prompt as CodeFieldPrompt).type, 'AI');
    });

    test('does not double echoed input', () {
      final prompt = AiCompletionProvider.promptFor(
        input: 'print',
        suggestion: 'print(x)',
      );
      expect(prompt.word, 'print(x)');
    });
  });
}
