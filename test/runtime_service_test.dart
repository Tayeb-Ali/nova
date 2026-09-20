import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/models/runtime.dart';
import 'package:nova/src/core/services/runtime_service.dart';

/// A single simulated pigeon request captured by the fake host.
class _RecordedCall {
  _RecordedCall(this.channel, this.args);

  final String channel;
  final List<Object?>? args;
}

/// Intercepts an outbound pigeon channel, records the call, and replies with
/// [replyFor]'s value encoded through the real pigeon codec. Pigeon relies on
/// per-method channel names (e.g. "...RuntimeApi.getRuntimes") and a raw
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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('getRuntimes maps bridge runtimes to models', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final log = <_RecordedCall>[];
    _mockPigeonChannel(
      messenger: messenger,
      channelName: 'dev.flutter.pigeon.nova.RuntimeApi.getRuntimes',
      codec: bridge.RuntimeApi.pigeonChannelCodec,
      log: log,
      replyFor: (args) {
        return <Object?>[
          <Object?>[
            bridge.RuntimeInfo(
              id: 'php',
              displayName: 'PHP',
              version: '8.2.10',
              installed: true,
              executable: '/usr/bin/php',
            ),
            bridge.RuntimeInfo(
              id: 'node',
              displayName: 'Node.js',
              version: 'v20.0.0',
              installed: false,
            ),
          ],
        ];
      },
    );

    final runtimes = await RuntimeService().getRuntimes();

    expect(log, hasLength(1));
    expect(
      log.single.channel.endsWith('RuntimeApi.getRuntimes'),
      isTrue,
    );
    expect(runtimes, hasLength(2));
    final php = runtimes[0];
    expect(php.id, 'php');
    expect(php.installed, isTrue);
    expect(php.version, '8.2.10');
    expect(php.executable, '/usr/bin/php');
    expect(php.type, RuntimeType.php);
    final node = runtimes[1];
    expect(node.id, 'node');
    expect(node.installed, isFalse);
    expect(node.version, 'v20.0.0');
  });

  test('install invokes RuntimeApi.installRuntime with runtime id', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final log = <_RecordedCall>[];
    _mockPigeonChannel(
      messenger: messenger,
      channelName: 'dev.flutter.pigeon.nova.RuntimeApi.installRuntime',
      codec: bridge.RuntimeApi.pigeonChannelCodec,
      log: log,
      replyFor: (args) => <Object?>[null],
    );

    await RuntimeService().install('php');

    expect(log, hasLength(1));
    final call = log.single;
    expect(call.channel.endsWith('RuntimeApi.installRuntime'), isTrue);
    expect(call.args, ['php']);
  });
}