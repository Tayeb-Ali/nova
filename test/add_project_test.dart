import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/core/ui/nova_nav_bar.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

class _FakeProjectService extends ProjectService {
  static const demo = ProjectInfo(
    name: "demo",
    path: "/data/demo",
    language: "php",
  );

  /// Mirrors the real ProjectManager: a created project persists and shows up
  /// in the next listProjects() call.
  final List<ProjectInfo> _projects = [demo];

  @override
  Future<List<ProjectInfo>> listProjects() async => List.of(_projects);

  @override
  Future<ProjectInfo> createProject(String name, String language) async {
    final created = ProjectInfo(
      name: name,
      path: "/data/$name",
      language: language,
    );
    _projects.add(created);
    return created;
  }

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

  testWidgets('adding a project does not throw', (
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

    // Projects hub is the default tab; open the new-project dialog.
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump(const Duration(milliseconds: 500));

    // Type a name and create. Scope the field to the dialog: the hub behind it
    // has its own search TextField, and it comes first in the widget tree.
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      "repro",
    );
    await tester.pump(const Duration(milliseconds: 300));
    final createButton = find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, "Create"),
    );
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // Creating a project must land the user in the editor with that project
    // active, not leave them on the projects hub.
    final navBar = tester.widget<NovaNavBar>(find.byType(NovaNavBar));
    expect(navBar.selectedIndex, 1, reason: 'editor tab should be selected');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NovaNavBar)),
    );
    expect(
      container.read(activeProjectProvider)?.name,
      'repro',
      reason: 'the new project should be the active one',
    );
  });
}
