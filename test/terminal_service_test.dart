import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/app_config.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/bridge/native_bridge.dart';
import 'package:nova/src/core/models/terminal_session.dart';
import 'package:nova/src/core/services/terminal_service.dart';

/// A single simulated pigeon request captured by the fake host.
class _RecordedCall {
  _RecordedCall(this.channel, this.args);

  final String channel;
  final List<Object?>? args;
}

/// Intercepts an outbound pigeon channel, records the call, and replies with
/// [replyFor]'s value encoded through the real pigeon codec. Pigeon relies on
/// per-method channel names (e.g. "...TerminalApi.createSession") and a raw
/// payload, so `setMockMethodCallHandler` (MethodCodec-based) cannot decode
/// it; using the raw message handler with the shared pigeon codec is the
/// robust way to simulate the host.
void _mockPigeonChannel({
  required TestDefaultBinaryMessenger messenger,
  required String channelName,
  required MessageCodec<Object?> codec,
  required List<_RecordedCall> log,
  required Object? Function(List<Object?>? args) replyFor,
}) {
  messenger.setMockMessageHandler(channelName, (ByteData? message) async {
    final args = message == null
        ? null
        : codec.decodeMessage(message) as List<Object?>?;
    log.add(_RecordedCall(channelName, args));
    return codec.encodeMessage(replyFor(args));
  });
}

void _registerTerminalApis(
  TestDefaultBinaryMessenger messenger,
  List<_RecordedCall> log,
) {
  final codec = bridge.TerminalApi.pigeonChannelCodec;
  _mockPigeonChannel(
    messenger: messenger,
    channelName:
        'dev.flutter.pigeon.nova.TerminalApi.createSession',
    codec: codec,
    log: log,
    replyFor: (args) => <Object?>['abc'],
  );
  for (final name in <String>[
    'dev.flutter.pigeon.nova.TerminalApi.write',
    'dev.flutter.pigeon.nova.TerminalApi.resize',
    'dev.flutter.pigeon.nova.TerminalApi.close',
    'dev.flutter.pigeon.nova.TerminalApi.sendSignal',
  ]) {
    _mockPigeonChannel(
      messenger: messenger,
      channelName: name,
      codec: codec,
      log: log,
      replyFor: (args) => <Object?>[null],
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('TerminalService channels', () {
    test('createSession routes to TerminalApi.createSession and returns id',
        () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerTerminalApis(messenger, log);

      final sessionId = await NativeBridge.terminal.createSession('/a', 80, 24);

      expect(log, hasLength(1));
      final call = log.single;
      expect(call.channel.endsWith('TerminalApi.createSession'), isTrue);
      expect(call.args, ['/a', 80, 24]);
      expect(sessionId, 'abc');
    });

    test('write routes sessionId + data to TerminalApi.write', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final log = <_RecordedCall>[];
      _registerTerminalApis(messenger, log);

      await TerminalService().write('s1', 'ls -la\n');

      expect(log, hasLength(1));
      final call = log.single;
      expect(call.channel.endsWith('TerminalApi.write'), isTrue);
      expect(call.args, ['s1', 'ls -la\n']);
    });
  });

  group('TerminalService events', () {
    void emitEvent(Map<String, Object?> payload) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        AppConfig.eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(payload),
        (ByteData? reply) {},
      );
    }

    test('outputStream decodes base64 payloads', () async {
      final service = TerminalService();
      final received = <TerminalOutput>[];
      final sub = service.outputStream.listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      emitEvent({
        'event': 'terminalOutput',
        'sessionId': 's1',
        'data': base64Encode(utf8.encode('hello')),
      });
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single.sessionId, 's1');
      expect(received.single.data, 'hello');
      expect(received.single.exited, isFalse);
    });

    test('outputStream ignores non-terminalOutput events', () async {
      final service = TerminalService();
      final received = <TerminalOutput>[];
      final sub = service.outputStream.listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      emitEvent({'event': 'setupCompleted'});
      emitEvent({'event': 'processOutput', 'pid': '1', 'data': 'x'});
      await pumpEventQueue();

      expect(received, isEmpty);
    });

    test('outputStream falls back to raw text when data is not base64',
        () async {
      final service = TerminalService();
      final received = <TerminalOutput>[];
      final sub = service.outputStream.listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      emitEvent({
        'event': 'terminalOutput',
        'sessionId': 's1',
        'data': 'plain text, not base64',
      });
      await pumpEventQueue();

      expect(received.single.data, 'plain text, not base64');
    });

    test('exitStream decodes terminalExit with exit code', () async {
      final service = TerminalService();
      final received = <TerminalOutput>[];
      final sub = service.exitStream.listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      emitEvent({'event': 'terminalExit', 'sessionId': 's1', 'exitCode': 0});
      await pumpEventQueue();

      expect(received.single.sessionId, 's1');
      expect(received.single.exited, isTrue);
      expect(received.single.exitCode, 0);
    });
  });
}