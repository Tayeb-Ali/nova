import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/features/markdown/markdown_toolbar.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

class _FakeProjectService extends ProjectService {
  static const project = ProjectInfo(
    name: "demo",
    path: "/data/demo",
    language: "php",
  );
  static const mdPath =
      "/data/user/0/sd.adaa.nova/files/projects/main_py/docs/NOTES.md";

  @override
  Future<List<ProjectInfo>> listProjects() async => [project];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => const [];

  @override
  Future<String> readFile(String path) async => "# Hi\n\nSome **text**.\n";

  @override
  Future<void> writeFile(String path, String content) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('markdown tab with long path does not overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectServiceProvider.overrideWithValue(_FakeProjectService()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // The shell boots on the Projects hub; switch to the Editor tab first.
    await tester.tap(find.text("Editor"));
    await tester.pump(const Duration(seconds: 1));

    final container =
        ProviderScope.containerOf(tester.element(find.byType(IdeShell)));
    const path = _FakeProjectService.mdPath;
    final id = container.read(workspaceTabsProvider.notifier).open(path);
    container.read(activeEditorTabProvider.notifier).state = id;
    // The tab body loads async (mount, load future, rebuild with content).
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Rich editor + toolbar + header toggle all laid out.
    expect(find.byType(FleatherEditor), findsOneWidget);
    expect(find.byType(MarkdownToolbar), findsOneWidget);
    expect(find.text("NOTES.md", findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
