import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/ui/text_prompt_dialog.dart';
import 'package:nova/src/features/workspace/new_project_dialog.dart';

/// Pumps [child] behind a button that opens the dialog, then drives the whole
/// open → type → submit → exit-animation sequence frame by frame.
Future<void> _driveDialog(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump(); // start the open transition
  await tester.pump(const Duration(milliseconds: 300));

  await tester.enterText(find.byType(TextField).first, 'repro');
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.widgetWithText(FilledButton, 'Create'));
  // The pop completes the showDialog future immediately, but the route keeps
  // rebuilding through its exit transition. Step frame by frame so a
  // caller-owned (already disposed) controller would be hit.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('new project dialog: submit then exit animation is clean', (
    WidgetTester tester,
  ) async {
    await _driveDialog(tester, showNewProjectDialog);
  });

  testWidgets('text prompt dialog: submit then exit animation is clean', (
    WidgetTester tester,
  ) async {
    await _driveDialog(
      tester,
      (context) => showTextPromptDialog(
        context: context,
        title: 'New file',
        hintText: 'e.g. main.py',
        confirmLabel: 'Create',
        cancelLabel: 'Cancel',
      ),
    );
  });

  testWidgets('text prompt dialog: cancel does not dispose early', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showTextPromptDialog(
                  context: context,
                  title: 'New file',
                  hintText: 'e.g. main.py',
                  confirmLabel: 'Create',
                  cancelLabel: 'Cancel',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'main.py');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });
}
