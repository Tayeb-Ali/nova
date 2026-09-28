import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/features/process/process_screen.dart';

/// Regression: `ProcessScreen.initState` used to call `_refresh()`, whose
/// first statement read `AppLocalizations.of(context)`. Reading an inherited
/// widget before `initState` completes throws, which on device surfaced as the
/// process tab blowing up the widget tree (and a huge main-thread stall while
/// the error was reported).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.codeide.ProcessApi.listProcesses',
      (ByteData? message) async {
        // Pigeon reply envelope: a one-element list whose single value is the
        // result. An empty process list.
        return const StandardMessageCodec().encodeMessage(<Object?>[<Object?>[]]);
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.codeide.ProcessApi.listProcesses',
          null,
        );
  });

  testWidgets('process screen mounts without an inherited-widget error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ProcessScreen()),
      ),
    );

    // The offending call was in the synchronous prefix of _refresh(), so the
    // very first frame is enough to catch a regression.
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('process screen survives the async failure path', (
    WidgetTester tester,
  ) async {
    // listProcesses fails: pigeon error envelope is [code, message, details].
    // The catch branch reads l10n, which must happen after the first await,
    // never during initState.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.codeide.ProcessApi.listProcesses',
      (ByteData? message) async => const StandardMessageCodec()
          .encodeMessage(<Object?>['boom', 'list failed', null]),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ProcessScreen()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The error banner rendered instead of crashing.
    expect(find.textContaining('list failed'), findsOneWidget);
  });
}
