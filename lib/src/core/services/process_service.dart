import '../bridge/events_bus.dart';
import '../bridge/generated/ide_api.g.dart' as bridge;
import '../bridge/native_bridge.dart';
import '../models/process_info.dart';

/// Managed background processes that outlive the terminal (task.md §21).
class ProcessService {
  Stream<ProcessEvent> get eventStream {
    return IdeEventBus.instance.stream
        .where((e) => e is Map && (e['event'] == 'processOutput' || e['event'] == 'processExit'))
        .map((e) => ProcessEvent.fromMap(e as Map));
  }

  Future<ProcessInfo> start({
    required String command,
    List<String> args = const [],
    String? cwd,
    Map<String, String>? environment,
  }) async {
    final p = await NativeBridge.process.startProcess(bridge.ProcessRequest(
      command: command,
      args: args,
      cwd: cwd,
      environment: environment,
    ));
    return ProcessInfo.fromBridge(p);
  }

  Future<void> kill(String pid) => NativeBridge.process.killProcess(pid);

  Future<List<ProcessInfo>> list() async {
    final list = await NativeBridge.process.listProcesses();
    return list.map(ProcessInfo.fromBridge).toList();
  }
}

/// A process push event (stdout/stderr/exited) from Kotlin.
class ProcessEvent {
  final String pid;
  final String output;
  final bool exited;
  final int? exitCode;

  const ProcessEvent({
    required this.pid,
    this.output = '',
    this.exited = false,
    this.exitCode,
  });

  factory ProcessEvent.fromMap(Map map) => ProcessEvent(
        pid: (map['pid'] as String?) ?? '',
        output: (map['data'] as String?) ?? '',
        exited: map['event'] == 'processExit',
        exitCode: (map['exitCode'] as int?) ?? -1,
      );
}