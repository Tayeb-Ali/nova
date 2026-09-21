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

  Future<String?> detectLanguage(ProjectInfo project) async {
    try {
      final entries = await service.listFiles(project.path);
      return detectProjectLanguage([for (final e in entries) e.name]);
    } catch (_) {
      // Project root unreadable or not ready; unknown language.
      return null;
    }
  }

  /// Detects the project language from top-level file basenames.
  ///
  /// Pure function, no IO. Matching is case-insensitive and uses
  /// first-match priority order (see body). Returns null when no
  /// marker matches. `Makefile` alone is intentionally ignored as
  /// ambiguous.
  static String? detectProjectLanguage(List<String> fileNames) {
    final names = <String>{
      for (final f in fileNames) _basenameLower(f),
    };
    if (names.contains('pubspec.yaml')) return 'dart';
    if (names.contains('package.json')) return 'node';
    if (names.contains('cargo.toml')) return 'rust';
    if (names.contains('go.mod')) return 'go';
    if (names.contains('composer.json')) return 'php';
    if (names.contains('requirements.txt') ||
        names.contains('pyproject.toml') ||
        names.contains('setup.py')) {
      return 'python';
    }
    if (names.any((n) => n.endsWith('.sln') || n.endsWith('.csproj'))) {
      return 'csharp';
    }
    if (names.contains('gemfile')) return 'ruby';
    if (names.contains('pom.xml') ||
        names.any((n) => n.startsWith('build.gradle'))) {
      return 'java';
    }
    if (names.contains('package.swift')) return 'swift';
    if (names.contains('cmakelists.txt')) return 'cpp';
    return null;
  }

  /// Lowercases and strips any directory prefix, so callers may pass
  /// either basenames or paths without changing the result.
  static String _basenameLower(String fileName) {
    final slash = fileName.lastIndexOf(RegExp(r'[/\\]'));
    final base =
        slash >= 0 ? fileName.substring(slash + 1) : fileName;
    return base.toLowerCase();
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