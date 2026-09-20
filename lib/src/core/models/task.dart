/// A runnable task detected in a project (task.md §20).
class IdeTask {
  final String name;
  final String command;
  final String? args;

  const IdeTask({required this.name, required this.command, this.args});

  @override
  String toString() => '$name: $command ${args ?? ''}'.trim();
}