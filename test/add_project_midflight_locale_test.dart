import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/core/ui/nova_nav_bar.dart';
import 'package:nova/src/core/settings_store.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

/// Slow fake: createProject stays in flight long enough to flip the locale
/// mid-await, racing the dialog exit transition + MaterialApp rebuild.
class _SlowProjectService extends ProjectService {
  static const demo = ProjectInfo(
    name: 'demo',
    path: '/data/demo',
    language: 'php',
  );

  final List<ProjectInfo> _projects = [demo];

  @override
  Future<List<ProjectInfo>> listProjects() async => List.of(_projects);

  @override
  Future<ProjectInfo> createProject(String name, String language) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final created = ProjectInfo(
      name: name,
      path: '/data/$name',
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
  Future<String> readFile(String path) async => '';

  @override
  Future<void> writeFile(String path, String content) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('locale flip mid-create does not throw', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectServiceProvider.overrideWithValue(_SlowProjectService()),
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

    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pump(const Duration(milliseconds: 500));

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'midflight',
    );
    await tester.pump(const Duration(milliseconds: 300));

    final createButton = find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, 'Create'),
    );
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    // Create is now in flight (400ms fake) and the dialog exit transition
    // is rebuilding the TextField: flip the locale mid-flight so MaterialApp
    // rebuilds Localizations underneath both. Old code used the disposed
    // controller here (TextEditingController after dispose) and a stale
    // inherited dependency (_dependents.isEmpty, see nova_last_crash).
    await tester.pump(const Duration(milliseconds: 100));
    await container.read(settingsStoreProvider.notifier).setAppLocale('ar');
    await tester.pump(const Duration(milliseconds: 200));
    await container.read(settingsStoreProvider.notifier).setAppLocale('en');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    final navBar = tester.widget<NovaNavBar>(find.byType(NovaNavBar));
    expect(navBar.selectedIndex, 1, reason: 'editor tab should be selected');
    final checkContainer = ProviderScope.containerOf(
      tester.element(find.byType(NovaNavBar)),
    );
    expect(
      checkContainer.read(activeProjectProvider)?.name,
      'midflight',
      reason: 'the new project should be the active one',
    );
  });
}
