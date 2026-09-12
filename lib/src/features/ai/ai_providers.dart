import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_client.dart';

/// Secure-storage key for the AI API key.
const String kNovaAiKeyStorageKey = 'nova_ai_key';

/// Shared secure storage instance.
final _storage = FlutterSecureStorage();

/// API key saved by the user, or null if not set.
final aiKeyProvider = FutureProvider<String?>((ref) async {
  return _storage.read(key: kNovaAiKeyStorageKey);
});

/// Injectable AI HTTP client (override in tests).
final aiClientProvider = Provider<AiClient>((ref) => AiClient());

/// UI state for one AI request.
class AiState {
  final bool loading;
  final String result;
  final String error;

  const AiState({
    this.loading = false,
    this.result = '',
    this.error = '',
  });

  AiState copyWith({bool? loading, String? result, String? error}) {
    return AiState(
      loading: loading ?? this.loading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// Runs AI requests and exposes loading/result/error.
class AiNotifier extends StateNotifier<AiState> {
  final AiClient _client;

  AiNotifier(this._client) : super(const AiState());

  Future<void> run({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int? maxTokens,
  }) async {
    state = state.copyWith(loading: true, result: '', error: '');
    try {
      final String content = await _client.call(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        messages: messages,
        maxTokens: maxTokens,
      );
      state = state.copyWith(loading: false, result: content);
    } on AiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clear() {
    state = const AiState();
  }

  void setBusy() {
    state = state.copyWith(loading: true, result: '', error: '');
  }

  void setResult(String content) {
    state = state.copyWith(loading: false, result: content);
  }

  void setError(String message) {
    state = state.copyWith(loading: false, error: message);
  }
}

/// Global AI request state.
final aiStateProvider =
    StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref.watch(aiClientProvider));
});

