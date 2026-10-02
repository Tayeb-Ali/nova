import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

class _FakeProjectService extends ProjectService {
  static const project = ProjectInfo(
    name: "demo",
    path: "/data/demo",
    language: "php",
  );

  @override
  Future<List<ProjectInfo>> listProjects() async => [project];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => const [];

  @override
  Future<String> readFile(String path) async => "";

  @override
  Future<void> writeFile(String path, String content) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('run panel collapsed does not overflow', (
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

    // The console starts collapsed (editor-first layout): expand it, then
    // collapse it again — neither direction may overflow.
    final expand = find.byIcon(Icons.keyboard_arrow_up);
    expect(expand, findsOneWidget);
    await tester.tap(expand);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final collapse = find.byIcon(Icons.keyboard_arrow_down);
    expect(collapse, findsOneWidget);
    await tester.tap(collapse);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });
}
