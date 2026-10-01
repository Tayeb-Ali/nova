import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';
import 'package:nova/src/features/workspace/workspace_screen.dart';

const String _dir = '/data/user/0/sd.adaa.codeide/files/demo';

class _FakeProjectService extends ProjectService {
  static const project = ProjectInfo(
    name: 'demo',
    path: _dir,
    language: 'php',
  );

  @override
  Future<List<ProjectInfo>> listProjects() async => [project];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => const [];

  @override
  Future<String> readFile(String path) async => '<?php echo "hi";';

  @override
  Future<void> writeFile(String path, String content) async {}
}

/// Device scenario: file open in the editor with the explorer and the tool
/// drawer open on a short viewport (keyboard up). The editor pane shrinks
/// below its fixed chrome (48px tab strip + file header) and used to throw
/// "RenderFlex overflowed" from editor_area_view.dart:294, while the editor
/// remount loop flapped the keyboard non-stop.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('open file with drawer and explorer on short viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        projectServiceProvider.overrideWithValue(_FakeProjectService()),
        fileEntriesProvider.overrideWith(
          (ref, path) async => const <FileEntry>[],
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: WorkspaceScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open a code file like the user did.
    final id = container
        .read(workspaceTabsProvider.notifier)
        .open('$_dir/index.php');
    container.read(activeEditorTabProvider.notifier).state = id;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
