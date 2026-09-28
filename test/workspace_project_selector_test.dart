import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';
import 'package:nova/src/features/workspace/workspace_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serves a BRAND NEW list of BRAND NEW ProjectInfo instances on every call,
/// exactly like the real bridge (listProjects() mints fresh objects). This is
/// the condition that made the project selector crash: `activeProjectProvider`
/// held an instance from an earlier load that was equal-by-path but not
/// identical to the row rendered in the current list.
class _FreshInstanceProjectService extends ProjectService {
  _FreshInstanceProjectService(this.names);

  final List<String> names;

  @override
  Future<List<ProjectInfo>> listProjects() async => [
        for (final n in names)
          ProjectInfo(name: n, path: '/data/user/0/sd.adaa.codeide/files/$n'),
      ];

  @override
  Future<void> openProject(String path) async {}
}

Widget _harness(ProjectService service, {ProjectInfo? active}) {
  return ProviderScope(
    overrides: [
      projectServiceProvider.overrideWithValue(service),
      activeProjectProvider.overrideWith((ref) => active),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: WorkspaceScreen()),
    ),
  );
}

void main() {
  const demo = '/data/user/0/sd.adaa.codeide/files/demo';

  testWidgets('active project from a stale list still selects exactly once', (
    WidgetTester tester,
  ) async {
    // An instance captured from a previous load — same path, different object.
    final stale = ProjectInfo(name: 'demo', path: demo);

    await tester.pumpWidget(
      _harness(
        _FreshInstanceProjectService(['demo', 'other']),
        active: stale,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('demo'), findsOneWidget);
  });

  testWidgets('duplicate paths do not trigger the 2-matches assertion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        _FreshInstanceProjectService(['demo', 'demo', 'other']),
        active: ProjectInfo(name: 'demo', path: demo),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('active project absent from the list falls back to the hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        _FreshInstanceProjectService(['other']),
        active: const ProjectInfo(name: 'gone', path: '/nowhere'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Select project'), findsOneWidget);
  });

  test('ProjectInfo compares by path, not identity', () {
    const a = ProjectInfo(name: 'a', path: demo);
    const b = ProjectInfo(name: 'renamed', path: demo);
    const c = ProjectInfo(name: 'c', path: '/other');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
