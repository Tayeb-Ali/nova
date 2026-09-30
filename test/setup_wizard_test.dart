import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/app_config.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/services/setup_service.dart';
import 'package:nova/src/features/setup/setup_wizard_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<dynamic> events;
  late int startSetupCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = StreamController<dynamic>.broadcast();
    startSetupCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.codeide.SetupApi.startSetup',
          (message) async {
            startSetupCalls++;
            return bridge.SetupApi.pigeonChannelCodec.encodeMessage(
              <Object?>[null],
            );
          },
        );
  });

  tearDown(() async {
    await events.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.codeide.SetupApi.startSetup',
          null,
        );
  });

  Future<void> pumpWizard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SetupWizardDialog(events: events.stream)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('slim default, full persists, progress, retry resumes, done', (
    WidgetTester tester,
  ) async {
    await pumpWizard(tester);
    expect(tester.takeException(), isNull);

    // Step 1: slim is the default variant.
    expect(find.text('Slim ~80MB (default)'), findsOneWidget);
    expect(find.text('Full ~283MB (offline)'), findsOneWidget);
    expect(await SetupService().getBootstrapVariant(), AppConfig.bootstrapVariantSlim);

    // Pick full: persisted for the Kotlin installer via prefs.
    await tester.tap(find.text('Full ~283MB (offline)'));
    await tester.pumpAndSettle();
    expect(await SetupService().getBootstrapVariant(), AppConfig.bootstrapVariantFull);

    // Start the download.
    await tester.tap(find.widgetWithText(FilledButton, 'Download'));
    await tester.pumpAndSettle();
    expect(startSetupCalls, 1);

    // Native download progress shows phase + percent.
    events.add({'event': 'setupProgress', 'phase': 'downloading', 'fraction': 0.1});
    // Broadcast events arrive on a microtask; one pump delivers, the
    // second renders.
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('downloading'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    // Failure surfaces the error with a retry that resumes.
    events.add({'event': 'setupFailed', 'error': 'boom'});
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(startSetupCalls, 2);

    // Completion shows the ready state.
    events.add(const {'event': 'setupCompleted'});
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
