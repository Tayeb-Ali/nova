import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/ai/ai_client.dart';
import 'package:nova/src/features/ai/ai_providers.dart';

import 'ai_client_test.dart' show FakeAdapter;

const _sse =
    'data: {"choices":[{"delta":{"content":"Hello"}}]}\n'
    'data: {"choices":[{"delta":{"content":" world"}}]}\n'
    'data: [DONE]\n';

AiClient _sseClient() {
  final adapter = FakeAdapter(rawBody: _sse, json: {});
  return AiClient(dio: Dio()..httpClientAdapter = adapter);
}

void main() {
  test('runStream accumulates chunks and clears loading', () async {
    final container = ProviderContainer(
      overrides: [aiClientProvider.overrideWithValue(_sseClient())],
    );
    addTearDown(container.dispose);

    final states = <AiState>[];
    container.listen(aiStateProvider, (_, next) => states.add(next));

    await container.read(aiStateProvider.notifier).runStream(
          baseUrl: 'https://x/v1',
          apiKey: 'k',
          model: 'm',
          messages: const [
            {'role': 'user', 'content': 'x'},
          ],
        );

    final done = container.read(aiStateProvider);
    expect(done.loading, isFalse);
    expect(done.result, 'Hello world');
    expect(done.error, isEmpty);
    // Intermediate growth was published, not just the final string.
    expect(states.any((s) => s.result == 'Hello'), isTrue);
  });

  test('runStream surfaces provider errors', () async {
    final adapter = FakeAdapter(
      rawBody: 'data: {"error":{"message":"bad key"}}\n',
      json: {},
    );
    final container = ProviderContainer(
      overrides: [
        aiClientProvider.overrideWithValue(
          AiClient(dio: Dio()..httpClientAdapter = adapter),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(aiStateProvider.notifier).runStream(
          baseUrl: 'https://x/v1',
          apiKey: 'k',
          model: 'm',
          messages: const [
            {'role': 'user', 'content': 'x'},
          ],
        );

    final done = container.read(aiStateProvider);
    expect(done.loading, isFalse);
    expect(done.error, 'bad key');
  });

  test('cancel with nothing in flight is safe', () {
    final container = ProviderContainer(
      overrides: [aiClientProvider.overrideWithValue(_sseClient())],
    );
    addTearDown(container.dispose);

    container.read(aiStateProvider.notifier).cancel();
    expect(container.read(aiStateProvider).loading, isFalse);
  });
}
