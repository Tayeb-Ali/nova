import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/services/app_info_service.dart';
import 'package:nova/src/core/settings_store.dart';
import 'package:nova/src/features/settings/settings_screen.dart';

import 'pubspec_version.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The About card reads the version from package_info_plus: pin the mock
    // to the pubspec values so the card renders deterministically.
    AppInfo.debugReset();
    PackageInfo.setMockInitialValues(
      appName: 'nova',
      packageName: 'sd.adaa.codeide',
      version: pubspecVersion,
      buildNumber: pubspecBuildNumber,
      buildSignature: '',
    );
    await AppInfo.load();
  });
  tearDown(AppInfo.debugReset);

  testWidgets('Settings shows app version and build number', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The About card sits at the end of a lazily-built ListView: drag it
    // into view before asserting.
    for (
      var i = 0;
      i < 10 && find.text('About').evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
    }
    expect(find.text('About'), findsOneWidget);
    expect(
      find.text('v$pubspecVersion (build $pubspecBuildNumber)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings AI completion toggle flips the flag', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The editor card may sit below the fold: drag until the row appears.
    for (
      var i = 0;
      i < 10 && find.text('AI completion').evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
    }
    expect(find.text('AI completion'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(
      container.read(settingsStoreProvider).aiCompletionEnabled,
      isTrue,
    );
    await tester.tap(find.text('AI completion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      container.read(settingsStoreProvider).aiCompletionEnabled,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
