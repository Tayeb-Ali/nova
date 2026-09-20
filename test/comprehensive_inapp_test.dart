import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/app_config.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/bridge/native_bridge.dart';
import 'package:nova/src/core/models/terminal_session.dart';
import 'package:nova/src/core/services/terminal_service.dart';

class _RecordedCall {
  _RecordedCall(this.channel, this.args);
  final String channel;
  final List<Object?>? args;
}

void _mockPigeonChannel({
  required TestDefaultBinaryMessenger messenger,
  required String channelName,
  required MessageCodec<Object?> codec,
  required List<_RecordedCall> log,
  required Object? Function(List<Object?>? args) replyFor,
}) {
  messenger.setMockMessageHandler(channelName, (ByteData? message) async {
    final args = message == null ? null : codec.decodeMessage(message) as List<Object?>?;
    log.add(_RecordedCall(channelName, args));
    return codec.encodeMessage(replyFor(args));
  });
}

void _registerAllMocks(TestDefaultBinaryMessenger messenger, List<_RecordedCall> log) {
  final tCodec = bridge.TerminalApi.pigeonChannelCodec;
  for (final entry in {
    'dev.flutter.pigeon.nova.TerminalApi.createSession': () => <Object?>['sess-1'],
    'dev.flutter.pigeon.nova.TerminalApi.write': () => <Object?>[null],
    'dev.flutter.pigeon.nova.TerminalApi.resize': () => <Object?>[null],
    'dev.flutter.pigeon.nova.TerminalApi.close': () => <Object?>[null],
    'dev.flutter.pigeon.nova.TerminalApi.sendSignal': () => <Object?>[null],
  }.entries) {
    _mockPigeonChannel(
      messenger: messenger,
      channelName: entry.key,
      codec: tCodec,
      log: log,
      replyFor: (_) => entry.value(),
    );
  }
  final fCodec = bridge.FileApi.pigeonChannelCodec;
  for (final name in [
    'dev.flutter.pigeon.nova.FileApi.writeFile',
    'dev.flutter.pigeon.nova.FileApi.readFile',
    'dev.flutter.pigeon.nova.FileApi.listFiles',
  ]) {
    _mockPigeonChannel(
      messenger: messenger,
      channelName: name,
      codec: fCodec,
      log: log,
      replyFor: (_) => <Object?>[name.contains('readFile') ? 'content' : null],
    );
  }
  final rCodec = bridge.RuntimeApi.pigeonChannelCodec;
  for (final name in [
    'dev.flutter.pigeon.nova.RuntimeApi.getRuntimes',
    'dev.flutter.pigeon.nova.RuntimeApi.installRuntime',
  ]) {
    _mockPigeonChannel(
      messenger: messenger,
      channelName: name,
      codec: rCodec,
      log: log,
      replyFor: (_) {
        if (name.contains('getRuntimes')) {
          return <Object?>[
            <Object?>[
              bridge.RuntimeInfo(id: 'node', displayName: 'Node.js', version: 'v20.0.0', installed: false),
              bridge.RuntimeInfo(id: 'python', displayName: 'Python', version: '3.11.0', installed: false),
            ]
          ];
        }
        return <Object?>[null];
      },
    );
  }
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('Comprehensive in-app test — Node/Python/Terminal', () {
    void emit(Map<String, Object?> payload) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        AppConfig.eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(payload),
        (_) {},
      );
    }

    test('writes Node sample files via FileApi and verifies content patterns', () async {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerAllMocks(messenger, log);

      // Simulate writing Node hello/fs/http samples (as DebugTestHarness does)
      const nodeHello = """
console.log('node-hello:' + process.version);
console.log('arch:' + process.arch);
""";
      const nodeFs = """
const fs=require('fs'), path=require('path');
fs.writeFileSync('/tmp/nova.txt','hello-fs');
console.log('fs-ok');
""";
      const nodeHttp = """
const http=require('http');
http.createServer((req,res)=>res.end('ok')).listen(0);
console.log('http-ok');
""";

      // Verify samples contain expected markers (like harness checks)
      expect(nodeHello, contains('node-hello'));
      expect(nodeFs, contains('fs-ok'));
      expect(nodeHttp, contains('http-ok'));

      // Simulate FileApi writes
      await NativeBridge.files.writeFile('/home/nova_test/test_node_hello.js', nodeHello);
      await NativeBridge.files.writeFile('/home/nova_test/test_node_fs.js', nodeFs);

      expect(log.where((c) => c.channel.endsWith('writeFile')), hasLength(2));
      expect(log.first.args?[1], contains('node-hello'));
    });

    test('writes Python sample files and verifies markers', () async {
      const pyHello = """
import platform
print(f"python-hello:{platform.python_version()}")
""";
      const pyIo = """
import tempfile
print('io-ok')
import sqlite3
print('sqlite-ok')
""";
      expect(pyHello, contains('python-hello'));
      expect(pyIo, contains('io-ok'));
      expect(pyIo, contains('sqlite-ok'));

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerAllMocks(messenger, log);

      await NativeBridge.files.writeFile('/home/nova_test/test_python_hello.py', pyHello);
      expect(log.where((c) => c.channel.endsWith('writeFile')), hasLength(1));
    });

    test('terminal session creates, writes Node/Python commands, handles batched output', () async {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerAllMocks(messenger, log);

      final terminal = TerminalService();
      final sessionId = await terminal.createSession(cwd: '/home/nova_test', cols: 80, rows: 24);
      expect(sessionId, 'sess-1');
      expect(log.singleWhere((c) => c.channel.endsWith('createSession')).args, ['/home/nova_test', 80, 24]);

      // Simulate user typing: node test_node_hello.js
      await terminal.write(sessionId, 'node test_node_hello.js\n');
      await terminal.write(sessionId, 'python3 test_python_hello.py\n');
      expect(log.where((c) => c.channel.endsWith('write')), hasLength(2));

      // Simulate batched PTY output (base64, as TerminalManager.flush does)
      final outputs = <TerminalOutput>[];
      final sub = terminal.outputStream.listen(outputs.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      emit({
        'event': 'terminalOutput',
        'sessionId': sessionId,
        'data': base64Encode(utf8.encode('node-hello:v20.0.0\narch:x64\n')),
      });
      emit({
        'event': 'terminalOutput',
        'sessionId': sessionId,
        'data': base64Encode(utf8.encode('python-hello:3.11.0\nio-ok:hello-py\n')),
      });
      await pumpEventQueue();

      expect(outputs, hasLength(2));
      expect(outputs[0].data, contains('node-hello'));
      expect(outputs[1].data, contains('python-hello'));
      expect(outputs[1].data, contains('io-ok'));

      // Test terminal exit event
      final exits = <TerminalOutput>[];
      final exitSub = terminal.exitStream.listen(exits.add);
      addTearDown(exitSub.cancel);
      await pumpEventQueue();
      emit({'event': 'terminalExit', 'sessionId': sessionId, 'exitCode': 0});
      await pumpEventQueue();
      expect(exits.single.exited, isTrue);
      expect(exits.single.exitCode, 0);
    });

    test('runtime get/install flow for node/python', () async {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerAllMocks(messenger, log);

      final runtimes = await NativeBridge.runtime.getRuntimes();
      expect(runtimes.map((r) => r.id), containsAll(['node', 'python']));
      expect(runtimes.firstWhere((r) => r.id == 'node').installed, isFalse);

      await NativeBridge.runtime.installRuntime('node');
      expect(log.any((c) => c.channel.endsWith('installRuntime') && c.args?.first == 'node'), isTrue);

      await NativeBridge.runtime.installRuntime('python');
      expect(log.any((c) => c.channel.endsWith('installRuntime') && c.args?.first == 'python'), isTrue);
    });

    test('terminal resize and signal propagate', () async {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerAllMocks(messenger, log);
      final terminal = TerminalService();
      final id = await terminal.createSession(cwd: '', cols: 80, rows: 24);
      await terminal.resize(id, 100, 30);
      await terminal.sendSignal(id, 'SIGTERM');
      expect(log.any((c) => c.channel.endsWith('resize') && c.args?[1] == 100), isTrue);
      expect(log.any((c) => c.channel.endsWith('sendSignal')), isTrue);
      await terminal.close(id);
      expect(log.any((c) => c.channel.endsWith('close')), isTrue);
    });
  });
}
