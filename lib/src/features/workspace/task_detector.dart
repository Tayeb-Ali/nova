import "dart:convert";

import "../../core/models/project.dart";
import "../../core/models/task.dart";
import "../../core/services/project_service.dart";

/// Detects runnable tasks for a project (task.md §20):
/// package.json `scripts`, composer.json `scripts`, artisan,
/// main.py / index.js / index.php entry points.
class TaskDetector {
  final ProjectService service;

  const TaskDetector(this.service);

  Future<List<IdeTask>> detect(ProjectInfo project) async {
    final tasks = <IdeTask>[];
    try {
      final entries = await service.listFiles(project.path);
      final names = {for (final e in entries) e.name};

      if (names.contains("package.json")) {
        await _collectJsonScripts("${project.path}/package.json", tasks,
            prefix: "npm", runCommand: "npm run");
      }
      if (names.contains("composer.json")) {
        await _collectJsonScripts("${project.path}/composer.json", tasks,
            prefix: "composer", runCommand: "composer run");
      }
      if (names.contains("artisan")) {
        tasks.add(const IdeTask(
            name: "artisan serve", command: "php", args: "artisan serve"));
      }
      if (names.contains("main.py")) {
        tasks.add(const IdeTask(name: "main.py", command: "python", args: "main.py"));
      }
      if (names.contains("index.js")) {
        tasks.add(const IdeTask(name: "index.js", command: "node", args: "index.js"));
      }
      if (names.contains("index.php")) {
        tasks.add(const IdeTask(name: "index.php", command: "php", args: "index.php"));
      }
    } catch (_) {
      // Project root unreadable or not ready; no tasks.
    }
    return tasks;
  }

  Future<void> _collectJsonScripts(
    String filePath,
    List<IdeTask> out, {
    required String prefix,
    required String runCommand,
  }) async {
    try {
      final raw = await service.readFile(filePath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final scripts = decoded["scripts"];
      if (scripts is! Map) return;
      scripts.forEach((name, value) {
        if (value is! String) return;
        out.add(IdeTask(
          name: "$prefix: $name",
          command: runCommand,
          args: name as String,
        ));
      });
    } catch (_) {
      // Invalid or unreadable manifest; skip it.
    }
  }
}