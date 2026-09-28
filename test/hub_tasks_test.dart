import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

class _FakeProjectService extends ProjectService {
  static const demo = ProjectInfo(
    name: "demo",
    path: "/data/demo",
    language: "node",
  );

  @override
  Future<List<ProjectInfo>> listProjects() async => [demo];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => const [
        FileEntry(name: "package.json", path: "/data/demo/package.json", isDirectory: false),
        FileEntry(name: "index.js", path: "/data/demo/index.js", isDirectory: false),
      ];

  @override
  Future<String> readFile(String path) async =>
      '{"scripts": {"start": "node index.js"}}';

  @override
  Future<void> writeFile(String path, String content) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('selecting a project in hub populates run tasks', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectServiceProvider.overrideWithValue(_FakeProjectService()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const NovaApp();
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Hub is the default tab; tap the project card to select it.
    await tester.tap(find.text("demo").first);
    await tester.pump(const Duration(seconds: 1));

    final tasks = container.read(runTasksProvider);
    expect(tasks, isNotEmpty);
    expect(container.read(runTaskProvider), isNotNull);
    expect(tester.takeException(), isNull);
  });
}
