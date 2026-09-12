import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_service.dart';
import 'termux_bridge.dart';

/// Lifecycle of the latest run request.
enum RunStatus { idle, running, success, error }

/// UI-facing snapshot of the latest run.
class RunState {
  final RunStatus status;
  final String stdout;
  final String stderr;
  final int? exitCode;
  final String message;

  const RunState({
    this.status = RunStatus.idle,
    this.stdout = '',
    this.stderr = '',
    this.exitCode,
    this.message = '',
  });

  factory RunState.initial() => const RunState();

  RunState copyWith({
    RunStatus? status,
    String? stdout,
    String? stderr,
    int? exitCode,
    String? message,
  }) {
    return RunState(
      status: status ?? this.status,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      exitCode: exitCode ?? this.exitCode,
      message: message ?? this.message,
    );
  }
}

/// Owns run execution and publishes [RunState] for the output panel.
class RunController extends StateNotifier<RunState> {
  final RunService _service;
  final TermuxBridge _bridge;

  RunController({RunService? service, TermuxBridge? bridge})
      : _service = service ?? RunService(bridge: bridge ?? TermuxBridge.instance),
        _bridge = bridge ?? TermuxBridge.instance,
        super(RunState.initial());

  /// Resets the panel to its idle state.
  void clear() => state = RunState.initial();

  /// Reports an error without running anything (e.g. unreadable file).
  void reportError(String message) {
    state = state.copyWith(status: RunStatus.error, message: message);
  }

  /// Runs inline [code] for [language] (`py`/`js`/`php` + aliases).
  Future<void> runSingleFile({
    required String code,
    required String language,
  }) async {
    state = const RunState(status: RunStatus.running, message: 'Running...');
    if (!await _bridge.isTermuxInstalled()) {
      state = state.copyWith(
        status: RunStatus.error,
        message: 'Termux is not installed. Open the Termux setup guide to '
            'install and configure it.',
      );
      return;
    }
    try {
      final RunResult result =
          await _service.runSingleFile(code: code, language: language);
      _applyResult(result);
    } on RunNeedsWorkdirException catch (e) {
      state = state.copyWith(status: RunStatus.error, message: e.message);
    } on ArgumentError catch (e) {
      state = state.copyWith(
        status: RunStatus.error,
        message: e.message as String? ?? '$e',
      );
    } catch (e) {
      state = state.copyWith(
        status: RunStatus.error,
        message: 'Run failed: $e',
      );
    }
  }

  /// Runs a Termux-visible file inside [workdir].
  Future<void> runProjectFile({
    required String filePath,
    required String workdir,
    List<String> args = const [],
    String? stdin,
  }) async {
    state = RunState(
      status: RunStatus.running,
      message: 'Running $filePath...',
    );
    if (!await _bridge.isTermuxInstalled()) {
      state = state.copyWith(
        status: RunStatus.error,
        message: 'Termux is not installed. Open the Termux setup guide to '
            'install and configure it.',
      );
      return;
    }
    try {
      final RunResult result = await _service.runProjectFile(
        filePath: filePath,
        workdir: workdir,
        args: args,
        stdin: stdin,
      );
      _applyResult(result);
    } on ArgumentError catch (e) {
      state = state.copyWith(
        status: RunStatus.error,
        message: e.message as String? ?? '$e',
      );
    } catch (e) {
      state = state.copyWith(
        status: RunStatus.error,
        message: 'Run failed: $e',
      );
    }
  }

  void _applyResult(RunResult result) {
    final bool ok = !result.timedOut && result.exitCode == 0;
    state = state.copyWith(
      status: ok ? RunStatus.success : RunStatus.error,
      stdout: result.stdout,
      stderr: result.stderr,
      exitCode: result.exitCode,
      message: result.timedOut
          ? 'Timed out waiting for the Termux result.'
          : (ok ? 'Exited with code 0.' : 'Exited with code ${result.exitCode}.'),
    );
  }
}

final termuxBridgeProvider = Provider<TermuxBridge>((ref) {
  return TermuxBridge.instance;
});

final runServiceProvider = Provider<RunService>((ref) {
  return RunService(bridge: ref.watch(termuxBridgeProvider));
});

final runStateProvider =
    StateNotifierProvider<RunController, RunState>((ref) {
  return RunController(
    service: ref.watch(runServiceProvider),
    bridge: ref.watch(termuxBridgeProvider),
  );
});

/// Editor integration point: runs the currently open file.
///
/// Pass the open tab content as [code] when available (avoids a disk read);
/// otherwise the file is read from [filePath]. Large snippets are routed to
/// [RunController.runProjectFile] when [workdir] is provided, otherwise the
/// needs-workdir error is surfaced in the run state.
Future<void> runCurrentFile(
  WidgetRef ref, {
  required String filePath,
  required String language,
  String? code,
  String? workdir,
  List<String> args = const [],
}) async {
  final RunController controller = ref.read(runStateProvider.notifier);
  String? source = code;
  if (source == null) {
    try {
      source = await File(filePath).readAsString();
    } on FileSystemException catch (e) {
      controller.reportError('Cannot read file: ${e.message}');
      return;
    }
  }
  if (source.length > RunService.maxInlineCodeLength && workdir != null) {
    await controller.runProjectFile(
      filePath: filePath,
      workdir: workdir,
      args: args,
    );
  } else {
    await controller.runSingleFile(code: source, language: language);
  }
}
