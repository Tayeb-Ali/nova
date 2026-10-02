import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/lsp/go_lsp_manager.dart';
import 'package:nova/src/features/lsp/lsp_client.dart';
import 'package:nova/src/features/lsp/server_registry.dart';

/// In-memory [LspTransport] answering the initialize handshake, for
/// manager lifecycle tests (no processes spawned).
class _HandshakeTransport implements LspTransport {
  final StreamController<String> controller =
      StreamController<String>.broadcast();
  int starts = 0;
  int stops = 0;

  @override
  Stream<String> get incoming => controller.stream;

  @override
  void send(String message) {
    final match = RegExp(r'"method":"initialize"').firstMatch(message);
    if (match == null) return;
    final id = RegExp(r'"id":(\d+)').firstMatch(message)!.group(1)!;
    scheduleMicrotask(() {
      controller.add('{"jsonrpc":"2.0","id":$id,"result":{"capabilities":{}}}');
    });
  }

  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
    await controller.close();
  }
}

void main() {
  test('stopFor removes every language key of the project', () async {
    final fakes = <String, _HandshakeTransport>{};
    final manager = GoLspManager(
      transportFactory: (cwd) =>
          fakes.putIfAbsent(cwd, _HandshakeTransport.new),
    );
    await manager.ensureForLanguage('/p1', 'go');
    await manager.ensureForLanguage('/p2', 'go');
    expect(manager.liveServerCount, 2);

    await manager.stopFor('/p1');
    expect(manager.liveServerCount, 1);
    expect(fakes['/p1']!.stops, 1);
    expect(fakes['/p2']!.stops, 0);

    // Idempotent: stopping again stops nothing new.
    await manager.stopFor('/p1');
    expect(fakes['/p1']!.stops, 1);
    await manager.stopAll();
    expect(manager.liveServerCount, 0);
  });

  test('server cap evicts the least-recently-added', () async {
    final fakes = <String, _HandshakeTransport>{};
    final manager = GoLspManager(
      transportFactory: (cwd) =>
          fakes.putIfAbsent(cwd, _HandshakeTransport.new),
    );
    for (var i = 0; i < GoLspManager.maxServers + 2; i++) {
      await manager.ensureForLanguage('/p$i', 'go');
    }
    expect(manager.liveServerCount, GoLspManager.maxServers);
    // The two oldest were evicted and stopped.
    expect(fakes['/p0']!.stops, 1);
    expect(fakes['/p1']!.stops, 1);
    expect(fakes['/p5']!.stops, 0);
    await manager.stopAll();
  });

  test('didChange/didClose for unknown languages never throw', () async {
    final manager = GoLspManager(
      transportFactory: (_) => _HandshakeTransport(),
    );
    await manager.didChangeFile('/p', '/p/Main.cs', 'csharp', 'x');
    await manager.didCloseFile('/p', '/p/Main.cs', 'csharp');
    expect(manager.liveServerCount, 0);
    await manager.stopAll();
  });

  test('dart has a registered stdio server', () async {
    expect(serverArgvFor('dart'), ['dart', 'language-server']);
    expect(serverArgvFor('csharp'), isNull);
    expect(lspInstallHints['dart'], isNotEmpty);
  });
}
