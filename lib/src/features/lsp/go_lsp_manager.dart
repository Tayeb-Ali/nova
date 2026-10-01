import 'lsp_client.dart';
import 'process_transport.dart';
import 'server_registry.dart';

/// Lifecycle for per-project `gopls` servers.
///
/// One [LspClient] per project root, started on demand and stopped when the
/// project closes. The client is returned uninitialized-safe: [ensureFor]
/// performs the LSP handshake before returning.
class GoLspManager {
  GoLspManager({LspTransport Function(String cwd)? transportFactory})
      : _transportFactory = transportFactory ??
            ((cwd) {
              final argv = serverArgvFor('go')!;
              return ProcessTransport(
                command: argv.first,
                args: argv.sublist(1),
                cwd: cwd,
              );
            });

  final LspTransport Function(String cwd) _transportFactory;
  final Map<String, LspClient> _clients = {};
  final Map<String, LspTransport> _transports = {};

  /// Client for [projectPath], starting `gopls serve` on first use.
  Future<LspClient> ensureFor(String projectPath) async {
    return ensureForLanguage(projectPath, 'go');
  }

  /// Client for [projectPath] running the server registered for [language].
  /// Throws when [serverArgvFor] has no entry (callers treat that as
  /// "no live completions", never as an editing failure).
  Future<LspClient> ensureForLanguage(
    String projectPath,
    String language,
  ) async {
    final String key = '$language@$projectPath';
    final existing = _clients[key] ?? _clients[projectPath];
    if (existing != null) return existing;
    final List<String>? argv = serverArgvFor(language);
    if (argv == null) {
      throw StateError('no LSP server registered for $language');
    }
    // The injected factory only knows the Go layout; other servers are
    // spawned directly from the registry argv.
    final LspTransport transport = language == 'go'
        ? _transportFactory(projectPath)
        : ProcessTransport(
            command: argv.first,
            args: argv.sublist(1),
            cwd: projectPath,
          );
    final client = LspClient(transport);
    await client.initialize(LspClient.uriFor(projectPath));
    _transports[key] = transport;
    _clients[key] = client;
    return client;
  }

  /// Best-effort completion fetch for any registered language: returns the
  /// raw server items, or an empty list when the server is down, unknown,
  /// or too slow (the 3s `LspClient` timeout applies).
  Future<List<LspCompletionItem>> completionFor(
    String projectPath,
    String language,
    String filePath,
    int line,
    int character,
  ) async {
    try {
      final client = await ensureForLanguage(projectPath, language);
      return await client.completion(filePath, line, character);
    } catch (_) {
      return const [];
    }
  }

  /// Best-effort didOpen for any registered language (no-op otherwise).
  Future<void> didOpenFile(
    String projectPath,
    String filePath,
    String language,
  ) async {
    try {
      final client = await ensureForLanguage(projectPath, language);
      client.didOpen(filePath, language);
    } catch (_) {
      // Server missing or failing: editing stays fully functional.
    }
  }

  /// Best-effort didOpen for a Go file (no-op when the server is down).
  Future<void> didOpenGoFile(String projectPath, String filePath) async {
    try {
      final client = await ensureFor(projectPath);
      client.didOpen(filePath, 'go');
    } catch (_) {
      // gopls missing or failing: editing stays fully functional.
    }
  }

  /// Best-effort didChange (called on save).
  Future<void> didChangeGoFile(
      String projectPath, String filePath, String text) async {
    try {
      final client = await ensureFor(projectPath);
      client.didOpen(filePath, 'go');
      client.didChange(filePath, text);
    } catch (_) {
      // Server unavailable: ignore.
    }
  }

  /// Stop the server for [projectPath] (idempotent).
  Future<void> stopFor(String projectPath) async {
    _clients.remove(projectPath);
    final transport = _transports.remove(projectPath);
    if (transport != null) {
      try {
        await transport.stop();
      } catch (_) {
        // Already gone.
      }
    }
  }

  /// Stop every managed server.
  Future<void> stopAll() async {
    for (final path in _transports.keys.toList()) {
      await stopFor(path);
    }
  }
}
