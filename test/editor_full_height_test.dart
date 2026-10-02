import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:re_editor/re_editor.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';
import 'package:nova/src/features/workspace/editor_area_view.dart';

class _FakeProjectService extends ProjectService {
  static const project = ProjectInfo(
    name: 'demo',
    path: '/data/demo',
    language: 'php',
  );

  @override
  Future<List<ProjectInfo>> listProjects() async => [project];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => const [];

  @override
  Future<String> readFile(String path) async =>
      List.generate(85, (i) => 'echo "Line $i";').join('\n');

  @override
  Future<void> writeFile(String path, String content) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('editor fills full height in focus mode and with keyboard without white gap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectServiceProvider.overrideWithValue(_FakeProjectService()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Tap Editor
    await tester.tap(find.text('Editor'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Open file
    final container = ProviderScope.containerOf(
      tester.element(find.byType(IdeShell)),
    );
    final id = container
        .read(workspaceTabsProvider.notifier)
        .open('/data/demo/index.php');
    container.read(activeEditorTabProvider.notifier).state = id;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Enter focus mode
    container.read(focusModeProvider.notifier).state = true;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // In focus mode without keyboard, editor should fill screen height minus focus bar (~41px)
    final editorBox = tester.renderObject<RenderBox>(find.byType(CodeEditor));
    final editorAreaBox = tester.renderObject<RenderBox>(find.byType(EditorAreaView));
    
    // EditorAreaView fills the entire 800px screen
    expect(editorAreaBox.size.height, 800.0);
    // CodeEditor should fill almost the entire 800px (> 750px), NOT be capped at 400px!
    expect(editorBox.size.height, greaterThan(750.0));

    // Open keyboard (300px)
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // With keyboard (500px available), CodeEditor should fill > 450px, NOT be capped at 250px!
    final editorBoxKeyboard = tester.renderObject<RenderBox>(find.byType(CodeEditor));
    final editorAreaBoxKeyboard = tester.renderObject<RenderBox>(find.byType(EditorAreaView));
    expect(editorAreaBoxKeyboard.size.height, 500.0);
    expect(editorBoxKeyboard.size.height, greaterThan(450.0));
  });
}
