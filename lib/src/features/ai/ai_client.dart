import 'dart:async';

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
      final String? providerMessage = _providerMessage(e.response?.data);
      if (providerMessage != null && providerMessage.isNotEmpty) {
        throw AiException(providerMessage);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          throw const AiException('AI request timed out');
        case DioExceptionType.connectionError:
          throw AiException('AI connection failed: ${e.message ?? e.error}');
        case DioExceptionType.badResponse:
          throw AiException(
            'AI request failed (${e.response?.statusCode ?? 'unknown'}): '
            '${e.message ?? 'bad response'}',
          );
        case DioExceptionType.cancel:
          throw const AiException('AI request cancelled');
        case DioExceptionType.badCertificate:
          throw const AiException('AI request failed: bad certificate');
        case DioExceptionType.unknown:
          if (e.error is TimeoutException) {
            throw const AiException('AI request timed out');
          }
          throw AiException('AI request failed: ${e.message ?? e.error}');
      }
    } on TimeoutException {
      throw const AiException('AI request timed out');
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('AI request failed: $e');
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

