import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/features/workspace/file_explorer_view.dart';
import 'package:nova/src/features/workspace/workspace_providers.dart';

const String _dir = '/data/user/0/sd.adaa.codeide/files/demo';
const ProjectInfo _project = ProjectInfo(
  name: 'demo',
  path: _dir,
  language: 'php',
);

/// Pumps the explorer squeezed to 91px tall — the exact constraint from a
/// device log where an open keyboard + tall tool drawer left
/// `BoxConstraints(w=264.0, 0.0<=h<=91.0)` and the fixed header (135px)
/// threw "RenderFlex overflowed by 44 pixels on the bottom".
Future<void> _pumpSqueezed(
  WidgetTester tester,
  Future<List<FileEntry>> Function() listFiles,
) async {
  final container = ProviderContainer(
    overrides: [
      fileEntriesProvider.overrideWith((ref, path) => listFiles()),
    ],
  );
  addTearDown(container.dispose);
  container.read(activeProjectProvider.notifier).state = _project;
  container.read(currentDirProvider.notifier).state = _dir;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SizedBox(width: 264, height: 91, child: FileExplorerView()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('squeezed explorer with empty folder does not overflow', (
    WidgetTester tester,
  ) async {
    await _pumpSqueezed(tester, () async => const <FileEntry>[]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('squeezed explorer while loading does not overflow', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        // Never completes: the explorer stays on the spinner.
        fileEntriesProvider.overrideWith(
          (ref, path) => Completer<List<FileEntry>>().future,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeProjectProvider.notifier).state = _project;
    container.read(currentDirProvider.notifier).state = _dir;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(width: 264, height: 91, child: FileExplorerView()),
          ),
        ),
      ),
    );
    // No pumpAndSettle: the spinner animation never settles.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
