import '../bridge/generated/ide_api.g.dart' as bridge;

/// A managed background process (task.md §21).
class ProcessInfo {
  final String pid;
  final String command;
  final String? cwd;
  final int? exitCode;
  final String? status;

  const ProcessInfo({
    required this.pid,
    required this.command,
    this.cwd,
    this.exitCode,
    this.status,
  });

  factory ProcessInfo.fromBridge(bridge.ProcessInfo p) => ProcessInfo(
        pid: p.pid,
        command: p.command,
        cwd: p.cwd,
        exitCode: p.exitCode,
        status: p.status,
      );
}