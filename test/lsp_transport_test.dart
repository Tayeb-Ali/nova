import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/models/process_info.dart';
import 'package:nova/src/core/services/process_service.dart';
import 'package:nova/src/features/lsp/go_lsp_manager.dart';
import 'package:nova/src/features/lsp/lsp_client.dart';
import 'package:nova/src/features/lsp/process_transport.dart';
import 'package:nova/src/features/lsp/server_registry.dart';

/// In-memory ProcessService double: records spawns/writes, replays canned
/// stdout through a controllable event stream.
class FakeProcesses extends ProcessService {
  final StreamController<ProcessEvent> events = StreamController.broadcast();
  final List<String> written = [];
  int spawnCount = 0;

  @override
  Future<ProcessInfo> start({
    required String command,
    List<String> args = const [],
    String? cwd,
    Map<String, String>? environment,
    bool? mergeStderr,
  }) async {
    spawnCount++;
    expect(mergeStderr, isFalse,
        reason: 'LSP stdio needs unmerged stdout');
    return const ProcessInfo(pid: 'lsp-1', command: 'gopls');
  }

  @override
  Future<void> writeStdin(String pid, String base64Chunk) async {
    written.add(base64Chunk);
  }

  @override
  Future<void> kill(String pid) async {}

  String get stdinText {
    final raw = written.join();
    // Writes are chunked; tests keep payloads small so one chunk suffices.
    return utf8.decode(base64Decode(raw));
  }
}

String frame(String body) =>
    'Content-Length: ${body.length}\r\n\r\n$body';

/// In-memory [LspTransport] that answers the initialize handshake like a
/// real server, for manager-level tests.
class _HandshakeTransport implements LspTransport {
  final StreamController<String> controller =
      StreamController<String>.broadcast();
  int starts = 0;
  int stops = 0;

  @override
  Stream<String> get incoming => controller.stream;

  @override
  void send(String message) {
    if (!message.contains('"method":"initialize"')) return;
    final id = RegExp(r'"id":(\d+)').firstMatch(message)?.group(1);
    if (id != null) {
      controller.add(
          '{"jsonrpc":"2.0","id":$id,"result":{"capabilities":{}}}');
    }
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
  test('registry wires go to gopls serve + apt hint', () {
    expect(serverCommandFor('go'), 'gopls serve');
    expect(serverArgvFor('go'), ['gopls', 'serve']);
    expect(lspInstallHints['go'], 'apt install gopls');
    expect(serverCommandFor('rust'), 'rust-analyzer');
    expect(serverArgvFor('rust'), ['rust-analyzer']);
    expect(serverArgvFor('cobol'), isNull);
  });

  test('transport decodes split Content-Length frames', () async {
    final fake = FakeProcesses();
    final transport = ProcessTransport(
      command: 'gopls',
      args: const ['serve'],
      cwd: '/proj',
      processes: fake,
      events: fake.events.stream,
    );
    final received = <String>[];
    transport.incoming.listen(received.add);
    await transport.start();

    // One message split across two stdout chunks.
    const body = '{"jsonrpc":"2.0","id":1,"result":{}}';
    final framed = frame(body);
    fake.events.add(const ProcessEvent(pid: 'lsp-1', output: ''));
    fake.events.add(ProcessEvent(
        pid: 'lsp-1', output: framed.substring(0, framed.length - 10)));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    fake.events
        .add(ProcessEvent(pid: 'lsp-1', output: framed.substring(framed.length - 10)));
    await Future<void>.delayed(Duration.zero);
    expect(received, [body]);
    await transport.stop();
  });

  test('transport frames stdin writes with headers', () async {
    final fake = FakeProcesses();
    final transport = ProcessTransport(
      command: 'gopls',
      args: const ['serve'],
      cwd: '/proj',
      processes: fake,
      events: fake.events.stream,
    );
    await transport.start();
    transport.send('{"jsonrpc":"2.0","method":"initialized","params":{}}');
    await Future<void>.delayed(Duration.zero);
    expect(fake.written, isNotEmpty);
    expect(fake.stdinText, startsWith('Content-Length: '));
    expect(fake.stdinText, contains('"method":"initialized"'));
    await transport.stop();
  });

  test('transport ignores other pids and exit events', () async {
    final fake = FakeProcesses();
    final transport = ProcessTransport(
      command: 'gopls',
      args: const ['serve'],
      cwd: '/proj',
      processes: fake,
      events: fake.events.stream,
    );
    final received = <String>[];
    transport.incoming.listen(received.add);
    await transport.start();
    const body = '{"jsonrpc":"2.0","id":9,"result":null}';
    fake.events.add(ProcessEvent(pid: 'other', output: frame(body)));
    fake.events.add(const ProcessEvent(pid: 'lsp-1', exited: true));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await transport.stop();
  });

  test('GoLspManager caches one client per project', () async {
    final fakes = <String, _HandshakeTransport>{};
    final manager = GoLspManager(
      transportFactory: (cwd) =>
          fakes.putIfAbsent(cwd, _HandshakeTransport.new),
    );
    final a = await manager.ensureFor('/proj');
    final b = await manager.ensureFor('/proj');
    expect(identical(a, b), isTrue);
    expect(fakes, hasLength(1));
    await manager.didOpenGoFile('/proj', '/proj/main.go');
    await manager.didChangeGoFile('/proj', '/proj/main.go', 'package main');
    await manager.stopAll();
    expect(fakes['/proj']!.stops, 1);
  });

  test('LspClient initialize handshake works over framed transport', () async {
    final fake = FakeProcesses();
    final transport = ProcessTransport(
      command: 'gopls',
      args: const ['serve'],
      cwd: '/proj',
      processes: fake,
      events: fake.events.stream,
    );
    final client = LspClient(transport);
    // Answer the initialize request as gopls would (framed).
    transport.incoming.listen((_) {});
    final initFuture = client.initialize('file:///proj');
    await Future<void>.delayed(Duration.zero);
    final sent = fake.stdinText;
    final id = RegExp(r'"id":(\d+)').firstMatch(sent)!.group(1)!;
    fake.events.add(ProcessEvent(
        pid: 'lsp-1',
        output: frame(
            '{"jsonrpc":"2.0","id":$id,"result":{"capabilities":{}}}')));
    await initFuture;
    await transport.stop();
  });
}
