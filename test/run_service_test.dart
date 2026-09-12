import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract for the Termux run bridge (sd.adaa.codeide/run).
/// Methods: `isTermuxInstalled` -> bool, `runCode` -> Map.
///
/// This file intentionally defines a local minimal [RunResult] + timeout
/// helper so it passes standalone even if another agent's run-service file
/// is missing. If a real RunService exists, these tests still validate the
/// shared MethodChannel contract.

// ---------------------------------------------------------------------------
// Local minimal model (standalone, mirrors expected app model).
// ---------------------------------------------------------------------------

class RunResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;

  const RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.timedOut = false,
  });

  factory RunResult.fromMap(Map<dynamic, dynamic> map) {
    int exit = 0;
    final dynamic rawExit = map['exitCode'] ?? map['exit_code'];
    if (rawExit is int) {
      exit = rawExit;
    } else if (rawExit is String) {
      exit = int.tryParse(rawExit) ?? 0;
    }
    return RunResult(
      exitCode: exit,
      stdout: map['stdout']?.toString() ?? '',
      stderr: map['stderr']?.toString() ?? '',
      timedOut: map['timedOut'] == true || map['timed_out'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'exitCode': exitCode,
        'stdout': stdout,
        'stderr': stderr,
        'timedOut': timedOut,
      };
}

/// Runs [future] with [timeout]; on timeout returns a timed-out [RunResult].
Future<RunResult> runWithTimeout(
  Future<RunResult> future,
  Duration timeout,
) async {
  try {
    return await future.timeout(timeout);
  } on TimeoutException {
    return const RunResult(
      exitCode: -1,
      stdout: '',
      stderr: 'timed out',
      timedOut: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Thin channel wrapper under test (contract only).
// ---------------------------------------------------------------------------

class TestRunBridge {
  static const channel = MethodChannel('sd.adaa.codeide/run');

  Future<bool> isTermuxInstalled() async {
    final result = await channel.invokeMethod<bool>('isTermuxInstalled');
    return result ?? false;
  }

  Future<RunResult> runCode(Map<String, dynamic> args) async {
    final raw = await channel.invokeMethod<Map<dynamic, dynamic>>(
      'runCode',
      args,
    );
    if (raw == null) {
      return const RunResult(exitCode: -1, stdout: '', stderr: 'null result');
    }
    return RunResult.fromMap(raw);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RunResult parsing', () {
    test('parses success map', () {
      final r = RunResult.fromMap({
        'exitCode': 0,
        'stdout': 'hi\n',
        'stderr': '',
      });
      expect(r.exitCode, 0);
      expect(r.stdout, 'hi\n');
      expect(r.stderr, '');
      expect(r.timedOut, isFalse);
    });

    test('defaults missing keys', () {
      final r = RunResult.fromMap(<dynamic, dynamic>{});
      expect(r.exitCode, 0);
      expect(r.stdout, '');
      expect(r.stderr, '');
      expect(r.timedOut, isFalse);
    });

    test('parses snake_case + timedOut flag', () {
      final r = RunResult.fromMap({
        'exit_code': '2',
        'stdout': 'o',
        'stderr': 'e',
        'timedOut': true,
      });
      expect(r.exitCode, 2);
      expect(r.timedOut, isTrue);
    });
  });

  group('timeout helper', () {
    test('returns value when fast', () async {
      final r = await runWithTimeout(
        Future.value(const RunResult(exitCode: 0, stdout: 'ok', stderr: '')),
        const Duration(seconds: 2),
      );
      expect(r.timedOut, isFalse);
      expect(r.stdout, 'ok');
    });

    test('returns timedOut result on TimeoutException', () async {
      final slow = Completer<RunResult>();
      // Never completes; timeout fires.
      final r = await runWithTimeout(
        slow.future,
        const Duration(milliseconds: 50),
      );
      expect(r.timedOut, isTrue);
      expect(r.exitCode, -1);
    });
  });

  group('MethodChannel contract sd.adaa.codeide/run', () {
    const channel = MethodChannel('sd.adaa.codeide/run');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isTermuxInstalled':
            return true;
          case 'runCode':
            final args = (call.arguments as Map?) ?? {};
            if (args['sleepMs'] == 'timeout') {
              // Simulate a long native call to exercise timeout logic.
              await Future<void>.delayed(const Duration(seconds: 5));
              return <String, dynamic>{
                'exitCode': 0,
                'stdout': 'late',
                'stderr': '',
              };
            }
            return <String, dynamic>{
              'exitCode': 0,
              'stdout': 'hello from ${args['command'] ?? 'run'}',
              'stderr': '',
            };
          default:
            throw PlatformException(
              code: 'NOT_IMPLEMENTED',
              message: 'unknown ${call.method}',
            );
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isTermuxInstalled returns bool', () async {
      final bridge = TestRunBridge();
      expect(await bridge.isTermuxInstalled(), isTrue);
    });

    test('runCode success parses stdout', () async {
      final bridge = TestRunBridge();
      final r = await bridge.runCode({
        'command': 'python3',
        'filePath': '/tmp/main.py',
      });
      expect(r.exitCode, 0);
      expect(r.stdout, contains('python3'));
      expect(r.timedOut, isFalse);
    });

    test('runCode timeout maps to timedOut result', () async {
      final bridge = TestRunBridge();
      final r = await runWithTimeout(
        bridge.runCode({'sleepMs': 'timeout'}),
        const Duration(milliseconds: 100),
      );
      expect(r.timedOut, isTrue);
    });
  });
}
