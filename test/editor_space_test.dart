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
  Future<String> readFile(String path) async => "<?php echo 1;";

  @override
  Future<void> writeFile(String path, String content) async {}
}

/// Editor breathing room: app chrome must yield to the keyboard so the
/// code area keeps maximum height while typing.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bottom nav hides while the keyboard is visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);

    // Keyboard opens: the bar (pure chrome while typing) must go away.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pump();
    expect(find.byType(NavigationBar), findsNothing);

    // Keyboard closes: navigation returns.
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace app bar slims while the keyboard is visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    await tester.pump();

    // Enter the workspace (Editor destination).
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Hide toolbar'), findsOneWidget);

    // Keyboard opens: full bar collapses to the slim strip (no AppBar),
    // with an expand affordance to bring it back.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('Show toolbar'), findsOneWidget);

    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus mode hides chrome and restores it on exit', (
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
    await tester.pump();
    await tester.pump();

    // Enter the workspace and open a file so the tab strip actions render.
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(IdeShell)),
    );
    const path = '/data/demo/index.php';
    final id = container.read(workspaceTabsProvider.notifier).open(path);
    container.read(activeEditorTabProvider.notifier).state = id;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // Enter focus: shell nav, app bar, tab strip and tool drawer go away.
    // (On narrow viewport the actions collapse into a popup menu.)
    await tester.tap(find.byTooltip('Tab actions'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Focus mode'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(AppBar), findsNothing);

    // Exit restores everything (focus bar keeps save + exit-focus).
    await tester.tap(find.byTooltip('Exit focus mode'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
