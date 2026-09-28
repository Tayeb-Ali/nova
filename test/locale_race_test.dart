import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/core/settings_store.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

class _FakeProjectService extends ProjectService {
  static const demo = ProjectInfo(
    name: "demo",
    path: "/data/demo",
    language: "php",
  );

  @override
  Future<List<ProjectInfo>> listProjects() async => [demo];

  @override
  Future<ProjectInfo> createProject(String name, String language) async =>
      ProjectInfo(name: name, path: "/data/$name", language: language);

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
    // Real Arabic devices load a saved locale asynchronously; simulate the
    // load racing the first frames plus a dialog open and locale flips.
    SharedPreferences.setMockInitialValues({"nova.appLocale": "ar"});
  });

  testWidgets('locale load + add project does not throw', (
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
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump(const Duration(milliseconds: 200));
    await container.read(settingsStoreProvider.notifier).setAppLocale("en");
    await tester.pump(const Duration(milliseconds: 200));
    await container.read(settingsStoreProvider.notifier).setAppLocale("ar");
    await tester.pump(const Duration(milliseconds: 200));

    // Scope the field to the dialog: the hub behind it has its own search
    // TextField and comes first in the widget tree.
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      "repro",
    );
    await tester.pump(const Duration(milliseconds: 300));
    final createButton = find.descendant(
      of: dialog,
      matching: find.byType(FilledButton),
    );
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
