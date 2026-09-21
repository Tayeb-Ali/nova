import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/src/features/ai/ai_client.dart';

/// Capturing fake adapter to verify request shape without network.
class FakeAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  String? lastBodyString;
  final int statusCode;
  final Map<String, dynamic> json;
  final DioException? throwError;

  FakeAdapter({required this.json, this.statusCode = 200, this.throwError});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (throwError != null) {
      throw throwError!;
    }
    // Capture encoded body for shape assertions.
    if (options.data is Map) {
      lastBodyString = jsonEncode(options.data);
    } else {
      lastBodyString = options.data?.toString();
    }
    return ResponseBody.fromString(
      jsonEncode(json),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> successJson(String content) => {
  'choices': [
    {
      'message': {'role': 'assistant', 'content': content},
    },
  ],
};

void main() {
  test(
    'sends POST to baseUrl/chat/completions with model+messages+auth',
    () async {
      final adapter = FakeAdapter(json: successJson('hello'));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = AiClient(dio: dio);

      final result = await client.call(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
        model: 'gpt-4o-mini',
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
      );

      expect(result, 'hello');
      expect(adapter.lastOptions, isNotNull);
      expect(adapter.lastOptions!.method, 'POST');
      expect(
        adapter.lastOptions!.uri.toString(),
        'https://api.openai.com/v1/chat/completions',
      );
      expect(adapter.lastOptions!.headers['Authorization'], 'Bearer test-key');
      final body = jsonDecode(adapter.lastBodyString!) as Map<String, dynamic>;
      expect(body['model'], 'gpt-4o-mini');
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
    },
  );

  test('trims trailing slash on baseUrl and includes max_tokens', () async {
    final adapter = FakeAdapter(json: successJson('ok'));
    final dio = Dio()..httpClientAdapter = adapter;
    final client = AiClient(dio: dio);

    await client.call(
      baseUrl: 'https://example.com/v1/',
      apiKey: 'k',
      model: 'm',
      messages: [
        {'role': 'user', 'content': 'x'},
      ],
      maxTokens: 123,
    );

    expect(
      adapter.lastOptions!.uri.toString(),
      'https://example.com/v1/chat/completions',
    );
    final body = jsonDecode(adapter.lastBodyString!) as Map<String, dynamic>;
    expect(body['max_tokens'], 123);
  });

  test('maps DioException connection error to AiException', () async {
    final dio = Dio()..httpClientAdapter = FakeAdapter(json: {});
    dio.httpClientAdapter = FakeAdapter(
      json: {},
      throwError: DioException(
        requestOptions: RequestOptions(path: 'x'),
        type: DioExceptionType.connectionError,
        message: 'no net',
      ),
    );
    final client = AiClient(dio: dio);

    expect(
      () => client.call(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'k',
        model: 'm',
        messages: [
          {'role': 'user', 'content': 'x'},
        ],
      ),
      throwsA(isA<AiException>()),
    );
  });

  test(
    'maps timeout DioException to AiException with timeout message',
    () async {
      final adapter = FakeAdapter(
        json: {},
        throwError: DioException(
          requestOptions: RequestOptions(path: 'x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final client = AiClient(dio: Dio()..httpClientAdapter = adapter);

      try {
        await client.call(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'k',
          model: 'm',
          messages: [
            {'role': 'user', 'content': 'x'},
          ],
        );
        fail('expected AiException');
      } on AiException catch (e) {
        expect(e.message.toLowerCase(), contains('timed out'));
      }
    },
  );

  test('maps malformed response to AiException', () async {
    final adapter = FakeAdapter(json: {'unexpected': true});
    final client = AiClient(dio: Dio()..httpClientAdapter = adapter);

    expect(
      () => client.call(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'k',
        model: 'm',
        messages: [
          {'role': 'user', 'content': 'x'},
        ],
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('surfaces provider error message', () async {
    final adapter = FakeAdapter(
      json: {
        'error': {'message': 'invalid key'},
      },
    );
    final client = AiClient(dio: Dio()..httpClientAdapter = adapter);

    try {
      await client.call(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'bad',
        model: 'm',
        messages: [
          {'role': 'user', 'content': 'x'},
        ],
      );
      fail('expected AiException');
    } on AiException catch (e) {
      expect(e.message, 'invalid key');
    }
  });
}
