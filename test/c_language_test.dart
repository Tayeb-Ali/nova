import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/models/runtime.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/task_detector.dart';

/// NEXT_PLAN item 1.1: C/C++ as a first-class language.
/// Covers the `RuntimeType.c` registry entry plus the `task_detector`
/// build/run tasks (`main.c`, `main.cpp`, `Makefile`).
void main() {
  group('RuntimeType.c registry', () {
    test('fromId maps c', () {
      expect(RuntimeType.fromId('c'), RuntimeType.c);
    });

    test('c is a language with a description', () {
      expect(RuntimeType.c.isLanguage, isTrue);
      expect(RuntimeType.c.description, isNotEmpty);
      expect(RuntimeType.c.icon, isNotNull);
    });

    test('RuntimeInfo c is a language, not a pack', () {
      final info = RuntimeInfo(id: 'c', displayName: 'C', installed: true);
      expect(info.type, RuntimeType.c);
      expect(info.isPack, isFalse);
    });
  });

  group('C/C++ task detection', () {
    Future<List<String>> commandsFor(List<String> files) async {
      final detector = TaskDetector(_FilesService(files));
      const project = ProjectInfo(
        name: 't',
        path: '/data/t',
        language: 'general',
      );
      final tasks = await detector.detect(project);
      return [for (final t in tasks) '${t.command} ${t.args ?? ''}'.trim()];
    }

    test('main.c builds and runs with cc', () async {
      expect(
        await commandsFor(['main.c']),
        ['sh -c "cc main.c -o app && ./app"'],
      );
    });

    test('main.cpp builds and runs with clang++', () async {
      expect(
        await commandsFor(['main.cpp']),
        ['sh -c "clang++ main.cpp -o app && ./app"'],
      );
    });

    test('Makefile adds a make task', () async {
      expect(await commandsFor(['Makefile']), ['make']);
    });

    test('c project with a Makefile yields both tasks', () async {
      expect(
        await commandsFor(['main.c', 'Makefile']),
        ['sh -c "cc main.c -o app && ./app"', 'make'],
      );
    });
  });
}

class _FilesService extends ProjectService {
  _FilesService(this.files);

  final List<String> files;

  @override
  Future<List<ProjectInfo>> listProjects() async => const [];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => [
        for (final f in files)
          FileEntry(name: f, path: '/data/t/$f', isDirectory: false),
      ];

  @override
  Future<String> readFile(String path) async => '';

  @override
  Future<void> writeFile(String path, String content) async {}
}
