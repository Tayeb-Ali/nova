import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// Thrown for any AI request failure (network, timeout, bad response).
class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => 'AiException: $message';
}

/// Minimal OpenAI-compatible chat completions client.
///
/// POSTs `{baseUrl}/chat/completions` with `{model, messages}` and
/// `Authorization: Bearer <apiKey>`, returning the first choice content.
class AiClient {
  final Dio dio;

  /// Default per-request timeout.
  static const Duration timeout = Duration(seconds: 30);

  AiClient({Dio? dio}) : dio = dio ?? Dio();

  /// Sends a chat completion request and returns the content string.
  ///
  /// Throws [AiException] on network errors, timeouts, or malformed
  /// responses.
  Future<String> call({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int? maxTokens,
  }) async {
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = '$normalizedBase/chat/completions';

    final Map<String, Object> data = <String, Object>{
      'model': model,
      'messages': messages,
    };
    if (maxTokens != null) {
      data['max_tokens'] = maxTokens;
    }

    try {
      final Response<dynamic> res = await dio
          .post<dynamic>(
            url,
            data: data,
            options: Options(
              headers: <String, String>{
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              sendTimeout: timeout,
              receiveTimeout: timeout,
            ),
          )
          .timeout(timeout);

      final dynamic body = res.data;
      if (body is Map<String, dynamic>) {
        final dynamic choices = body['choices'];
        if (choices is List && choices.isNotEmpty) {
          final dynamic first = choices.first;
          if (first is Map<String, dynamic>) {
            final dynamic message = first['message'];
            if (message is Map<String, dynamic>) {
              final dynamic content = message['content'];
              if (content is String && content.isNotEmpty) {
                return content;
              }
            }
            // Some providers return `text` instead of message.content.
            final dynamic text = first['text'];
            if (text is String && text.isNotEmpty) {
              return text;
            }
          } else if (first is Map) {
            final dynamic message = first['message'];
            if (message is Map) {
              final dynamic content = message['content'];
              if (content is String && content.isNotEmpty) {
                return content;
              }
            }
          }
        }
        // Error payload from provider, e.g. {error: {message: ...}}.
        final dynamic err = body['error'];
        if (err is Map && err['message'] is String) {
          throw AiException(err['message'] as String);
        }
      }
      throw const AiException('Empty or malformed AI response');
    } on AiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on TimeoutException {
      throw const AiException('AI request timed out');
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('AI request failed: $e');
    }
  }

  /// Streams `content` deltas (`choices[0].delta.content`) using the OpenAI
  /// SSE format (`data: {...}` lines, `[DONE]` terminator).
  ///
  /// Sends `"stream": true`. Throws [AiException] on the same conditions as
  /// [call]; cancelling [cancelToken] surfaces as
  /// `AiException('AI request cancelled')` so callers handle it uniformly.
  Stream<String> stream({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int? maxTokens,
    CancelToken? cancelToken,
  }) async* {
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = '$normalizedBase/chat/completions';

    final Map<String, Object> data = <String, Object>{
      'model': model,
      'messages': messages,
      'stream': true,
    };
    if (maxTokens != null) {
      data['max_tokens'] = maxTokens;
    }

    late final Response<ResponseBody> res;
    try {
      res = await dio
          .post<ResponseBody>(
            url,
            data: data,
            cancelToken: cancelToken,
            options: Options(
              headers: <String, String>{
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.stream,
              sendTimeout: timeout,
              // Streaming responses stay open; no receive timeout.
            ),
          )
          .timeout(timeout);
    } on AiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on TimeoutException {
      throw const AiException('AI request timed out');
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('AI request failed: $e');
    }

    final Stream<List<int>>? bytes = res.data?.stream;
    if (bytes == null) {
      throw const AiException('Empty or malformed AI response');
    }
    var pending = '';
    try {
      // bind (not transform): Stream<Uint8List> is a Stream<List<int>> for
      // bind's parameter but not for transform's generic.
      await for (final String text in utf8.decoder.bind(bytes)) {
        if (cancelToken?.isCancelled ?? false) {
          throw const AiException('AI request cancelled');
        }
        pending += text;
        final List<String> lines = pending.split('\n');
        pending = lines.removeLast();
        for (final String line in lines) {
          final _SseLine parsed = _parseSseLine(line);
          if (parsed.done) return;
          if (parsed.content != null && parsed.content!.isNotEmpty) {
            yield parsed.content!;
          }
        }
      }
    } on AiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('AI request failed: $e');
    }
  }

  /// Parses one SSE line into content or a terminator.
  static _SseLine _parseSseLine(String line) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(':')) {
      return const _SseLine(null, false);
    }
    final String payload = trimmed.startsWith('data:')
        ? trimmed.substring('data:'.length).trim()
        : trimmed;
    if (payload == '[DONE]') return const _SseLine(null, true);
    if (!payload.startsWith('{')) return const _SseLine(null, false);
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final dynamic err = decoded['error'];
        if (err is Map && err['message'] is String) {
          throw AiException(err['message'] as String);
        }
        final dynamic choices = decoded['choices'];
        if (choices is List && choices.isNotEmpty) {
          final dynamic first = choices.first;
          if (first is Map<String, dynamic>) {
            final dynamic delta = first['delta'];
            if (delta is Map<String, dynamic>) {
              final dynamic content = delta['content'];
              if (content is String) return _SseLine(content, false);
            }
          }
        }
      }
    } catch (e) {
      if (e is AiException) rethrow;
      // Non-JSON data line: ignore.
    }
    return const _SseLine(null, false);
  }

  static AiException _mapDioException(DioException e) {
    final String? providerMessage = _providerMessage(e.response?.data);
    if (providerMessage != null && providerMessage.isNotEmpty) {
      return AiException(providerMessage);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AiException('AI request timed out');
      case DioExceptionType.connectionError:
        return AiException('AI connection failed: ${e.message ?? e.error}');
      case DioExceptionType.badResponse:
        return AiException(
          'AI request failed (${e.response?.statusCode ?? 'unknown'}): '
          '${e.message ?? 'bad response'}',
        );
      case DioExceptionType.cancel:
        return const AiException('AI request cancelled');
      case DioExceptionType.badCertificate:
        return const AiException('AI request failed: bad certificate');
      case DioExceptionType.unknown:
        if (e.error is TimeoutException) {
          return const AiException('AI request timed out');
        }
        return AiException('AI request failed: ${e.message ?? e.error}');
    }
  }

  static String? _providerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic err = data['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
      final dynamic msg = data['message'];
      if (msg is String) return msg;
    } else if (data is Map) {
      final dynamic err = data['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
    }
    return null;
  }
}

/// One parsed SSE line: streamed content, or the `[DONE]` terminator.
class _SseLine {
  const _SseLine(this.content, this.done);

  final String? content;
  final bool done;
}

