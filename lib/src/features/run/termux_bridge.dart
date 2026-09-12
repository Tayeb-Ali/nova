import 'dart:async';

import 'package:flutter/services.dart';

/// Result of a single Termux execution.
class RunResult {
  /// Captured standard output.
  final String stdout;

  /// Captured standard error.
  final String stderr;

  /// Process exit code, or -1 when unknown (dispatch failure / timeout).
  final int exitCode;

  /// True when the result was synthesized by the client-side timeout.
  final bool timedOut;

  const RunResult({
    this.stdout = '',
    this.stderr = '',
    this.exitCode = -1,
    this.timedOut = false,
  });
}

/// Thin wrapper around the native `sd.adaa.codeide/run` MethodChannel.
///
/// The native side acknowledges `runCode` immediately (dispatch ack) and
/// delivers the real result asynchronously via `onRunResult` with the
/// originating `requestId`. This class correlates the two with Completers.
///
/// Testability: the channel name is a public constant, so tests can install
/// a mock handler via the default binary messenger.
class TermuxBridge {
  /// MethodChannel name shared with TermuxBridge.kt.
  static const MethodChannel channel =
      MethodChannel('sd.adaa.codeide/run');

  /// Shared singleton used by the default providers.
  static final TermuxBridge instance = TermuxBridge._();

  TermuxBridge._() {
    channel.setMethodCallHandler(_handleCall);
  }

  static int _counter = 0;
  final Map<int, Completer<RunResult>> _pending = {};

  /// Generates a request id that fits in a 32-bit int (PendingIntent code).
  static int nextRequestId() {
    _counter = (_counter + 1) % 0x7fffffff;
    final int timeBits = DateTime.now().millisecondsSinceEpoch % 0x100000;
    return ((timeBits << 11) + _counter) % 0x7fffffff;
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method != 'onRunResult') return;
    final Map<String, dynamic> args =
        Map<String, dynamic>.from(call.arguments as Map);
    final int? requestId = (args['requestId'] as num?)?.toInt();
    if (requestId == null) return;
    final Completer<RunResult>? completer = _pending.remove(requestId);
    if (completer == null || completer.isCompleted) return;
    completer.complete(RunResult(
      stdout: args['stdout'] as String? ?? '',
      stderr: args['stderr'] as String? ?? '',
      exitCode: (args['exitCode'] as num?)?.toInt() ?? -1,
    ));
  }

  /// True when the Termux app package is installed on the device.
  Future<bool> isTermuxInstalled() async {
    try {
      return await channel.invokeMethod<bool>('isTermuxInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Best-effort interpreter probe. Optimistic by design on the native side
  /// (RUN_COMMAND is async); a false positive is possible, so callers that
  /// need certainty should run a real snippet and check its exit code.
  Future<bool> checkInterpreter(String bin) async {
    try {
      return await channel
              .invokeMethod<bool>('checkInterpreter', {'bin': bin}) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Dispatches a command to Termux and completes with its result.
  ///
  /// [path] becomes EXTRA_COMMAND_PATH, [args] EXTRA_ARGUMENTS, [workdir]
  /// EXTRA_WORKDIR and [stdin] EXTRA_STDIN. When [timeout] elapses first,
  /// completes with a synthetic [RunResult.timedOut] result.
  Future<RunResult> runCode({
    required String path,
    List<String> args = const [],
    String? workdir,
    String? stdin,
    int? requestId,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final int rid = requestId ?? nextRequestId();
    final Completer<RunResult> completer = Completer<RunResult>();
    _pending[rid] = completer;
    try {
      await channel.invokeMethod<void>('runCode', {
        'path': path,
        'args': args,
        'workdir': workdir,
        'stdin': stdin,
        'requestId': rid,
      });
    } on PlatformException catch (e) {
      _pending.remove(rid);
      return RunResult(
        stderr: 'Failed to dispatch to Termux: ${e.message}',
      );
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(rid);
        return const RunResult(
          stderr: 'Timed out waiting for the Termux result.',
          timedOut: true,
        );
      },
    );
  }
}
