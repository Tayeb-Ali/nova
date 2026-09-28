import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/features/git/git_screen.dart';

/// Regression: the commit-message dialog used to create its
/// `TextEditingController` in `_commit()` and dispose it right after
/// `await showDialog(...)` returned. `pop()` completes that future *before* the
/// dialog finishes its exit transition, so the still-rebuilding `TextField`
/// re-attached a listener to a disposed controller and threw
/// "A TextEditingController was used after being disposed", which in turn
/// produced the MaterialApp `'_dependents.isEmpty'` assertion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The commit button is only enabled when git status loads cleanly.
  const statusChannel = 'dev.flutter.pigeon.codeide.GitApi.status';
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(statusChannel, (ByteData? message) async {
          // Pigeon encodes the typed GitStatus through its own codec, which is
          // what decodes the reply back into a GitStatus instance.
          return bridge.GitApi.pigeonChannelCodec.encodeMessage(<Object?>[
            bridge.GitStatus(
              branch: 'main',
              modified: const [],
              added: const [],
              deleted: const [],
              untracked: const [],
            ),
          ]);
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(statusChannel, null);
  });

  Widget harness() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: GitScreen()),
  );

  testWidgets('commit dialog: submit then exit animation is clean', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    // The path gates the action buttons; no native project list is needed.
    await tester.enterText(find.byType(TextField).first, '/data/demo');
    // The path field's onSubmitted drives the setState that enables the
    // action buttons; enterText alone does not rebuild the parent.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Commit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'fix: things',
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(
      find.descendant(of: dialog, matching: find.widgetWithText(FilledButton, 'Commit')),
    );
    // Step the exit transition frame by frame: a caller-owned controller
    // disposed at pop() would throw on the very next rebuild.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('commit dialog: cancel does not dispose early', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '/data/demo');
    // The path field's onSubmitted drives the setState that enables the
    // action buttons; enterText alone does not rebuild the parent.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Commit'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'discarded',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: dialog, matching: find.widgetWithText(TextButton, 'Cancel')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
