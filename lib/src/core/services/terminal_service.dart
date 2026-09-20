import 'dart:convert';

import '../bridge/events_bus.dart';
import '../bridge/native_bridge.dart';
import '../models/terminal_session.dart';

/// Interactive PTY sessions (task.md §8–§12).
class TerminalService {
  /// Batched Kotlin -> Flutter terminal output/exit events (task.md §11).
  Stream<TerminalOutput> get outputStream {
    return IdeEventBus.instance.stream
        .where((e) => e is Map && e['event'] == 'terminalOutput')
        .map((e) {
      final map = e as Map;
      final raw = map['data'] as String? ?? '';
      String data = raw;
      try {
        data = utf8.decode(base64.decode(raw), allowMalformed: true);
      } catch (_) {
        // native sent plain text
      }
      return TerminalOutput(
        sessionId: (map['sessionId'] as String?) ?? '',
        data: data,
      );
    });
  }

  Stream<TerminalOutput> get exitStream {
    return IdeEventBus.instance.stream
        .where((e) => e is Map && e['event'] == 'terminalExit')
        .map((e) {
      final map = e as Map;
      return TerminalOutput(
        sessionId: (map['sessionId'] as String?) ?? '',
        data: '',
        exited: true,
        exitCode: (map['exitCode'] as int?) ?? -1,
      );
    });
  }

  Future<String> createSession({
    required String cwd,
    int cols = 80,
    int rows = 24,
  }) =>
      NativeBridge.terminal.createSession(cwd, cols, rows);

  Future<void> write(String sessionId, String data) =>
      NativeBridge.terminal.write(sessionId, data);

  Future<void> resize(String sessionId, int cols, int rows) =>
      NativeBridge.terminal.resize(sessionId, cols, rows);

  Future<void> close(String sessionId) => NativeBridge.terminal.close(sessionId);

  Future<void> sendSignal(String sessionId, String signal) =>
      NativeBridge.terminal.sendSignal(sessionId, signal);
}