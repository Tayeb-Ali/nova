import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/services/app_info_service.dart';
import 'package:nova/src/features/settings/settings_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The About card reads the version from package_info_plus: pin the mock
    // to the pubspec values so the card renders deterministically.
    AppInfo.debugReset();
    PackageInfo.setMockInitialValues(
      appName: 'nova',
      packageName: 'sd.adaa.codeide',
      version: '0.1.6',
      buildNumber: '6',
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
    expect(find.text('v0.1.6 (build 6)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
