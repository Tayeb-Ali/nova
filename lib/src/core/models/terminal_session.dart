/// A batched terminal output chunk pushed from Kotlin (task.md §11).
class TerminalOutput {
  final String sessionId;
  final String data;
  final bool exited;
  final int? exitCode;

  const TerminalOutput({
    required this.sessionId,
    required this.data,
    this.exited = false,
    this.exitCode,
  });
}