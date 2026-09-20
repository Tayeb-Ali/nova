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

  testWidgets('run panel collapsed does not overflow', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectServiceProvider.overrideWithValue(_FakeProjectService()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Collapse the console via the toggle IconButton.
    final toggle = find.byIcon(Icons.keyboard_arrow_down);
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });
}