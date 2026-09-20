import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/legacy.dart";

import "lsp_client.dart";

/// The app-wide LSP client. Uses [NullTransport] until a real server
/// transport is wired via native stdio.
final lspClientProvider = Provider<LspClient>((ref) {
  return LspClient(NullTransport());
});

/// Latest diagnostics snapshot per open document, kept in sync with
/// [LspClient.diagnosticsStream].
final lspDiagnosticsByPathProvider =
    StateProvider<Map<String, LspDiagnostics>>((ref) => <String, LspDiagnostics>{});

/// Diagnostics for all open documents, updated as the server publishes them.
final lspDiagnosticsProvider = StreamProvider<List<LspDiagnostics>>((ref) {
  final Stream<LspDiagnostics> stream =
      ref.watch(lspClientProvider).diagnosticsStream;
  final StateController<Map<String, LspDiagnostics>> store =
      ref.watch(lspDiagnosticsByPathProvider.notifier);
  return stream.map((LspDiagnostics diagnostics) {
    store.state = <String, LspDiagnostics>{
      ...store.state,
      diagnostics.path: diagnostics,
    };
    return store.state.values.toList(growable: false);
  });
});