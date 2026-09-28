import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';
import 'package:nova/src/features/workspace/workspace_screen.dart';

const String _demo = '/data/user/0/sd.adaa.codeide/files/demo';
const String _other = '/data/user/0/sd.adaa.codeide/files/other';

/// Mints BRAND NEW ProjectInfo instances on every call, like the real bridge.
class _FreshInstanceProjectService extends ProjectService {
  _FreshInstanceProjectService(this.seed);

  final List<ProjectInfo> seed;

  @override
  Future<List<ProjectInfo>> listProjects() async => [
    for (final p in seed) ProjectInfo(name: p.name, path: p.path),
  ];

  @override
  Future<void> openProject(String path) async {}
}

Future<ProviderContainer> _boot(
  WidgetTester tester, {
  List<ProjectInfo>? seed,
}) async {
  final container = ProviderContainer(
    overrides: [
      projectServiceProvider.overrideWithValue(
        _FreshInstanceProjectService(
          seed ??
              const [
                ProjectInfo(name: 'demo', path: _demo),
                ProjectInfo(name: 'other', path: _other),
              ],
        ),
      ),
      // The file listing never completes without a native channel.
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
  return container;
}

/// The real crash: the project list is refreshed by another writer (the
/// projects hub) while `activeProjectProvider` still holds the instance from
/// the previous list. The old guard matched on `.path` but DropdownButton
/// matches on `item.value == value`, and ProjectInfo had no operator==, so
/// the active project matched ZERO items and the assertion fired.
void main() {
  testWidgets('refreshed list with a stale active instance does not assert', (
    WidgetTester tester,
  ) async {
    final container = await _boot(tester);
    expect(container.read(activeProjectProvider)?.path, _demo);

    // A background reload replaces the list with brand new objects. Nothing
    // re-runs _loadProjects, so `active` keeps pointing at the old instance.
    container.read(projectsProvider.notifier).state = [
      const ProjectInfo(name: 'demo', path: _demo),
      const ProjectInfo(name: 'other', path: _other),
    ];
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The active project is still selected, matched by path.
    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).first,
    );
    expect(dropdown.value, _demo);
  });

  testWidgets('duplicate paths do not trigger the 2-matches assertion', (
    WidgetTester tester,
  ) async {
    final container = await _boot(tester);
    container.read(projectsProvider.notifier).state = [
      const ProjectInfo(name: 'demo', path: _demo),
      const ProjectInfo(name: 'demo', path: _demo),
      const ProjectInfo(name: 'other', path: _other),
    ];
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('active project removed from the list falls back to no value', (
    WidgetTester tester,
  ) async {
    final container = await _boot(tester);
    container.read(projectsProvider.notifier).state = [
      const ProjectInfo(name: 'other', path: _other),
    ];
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Select project'), findsOneWidget);
  });

  test('ProjectInfo compares by path, not identity', () {
    const a = ProjectInfo(name: 'a', path: _demo);
    const b = ProjectInfo(name: 'renamed', path: _demo);
    const c = ProjectInfo(name: 'c', path: _other);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
