import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/app_config.dart';
import 'package:nova/src/core/services/app_info_service.dart';
import 'package:nova/src/features/settings/about_screen.dart';
import 'package:nova/src/features/settings/settings_screen.dart';

import 'pubspec_version.dart';

Widget _app(Widget home) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<void> _dragTo(WidgetTester tester, String text) async {
  for (var i = 0; i < 10 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('AboutScreen shows download, project and contact sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Header version mirrors pubspec.yaml, never a hardcoded literal.
    expect(
      find.text('v$pubspecVersion (build $pubspecBuildNumber)'),
      findsOneWidget,
    );
    await _dragTo(tester, AppConfig.contactEmail);
    expect(find.text(AppConfig.contactEmail), findsOneWidget);
    expect(find.text(AppConfig.playStoreUrl), findsOneWidget);
    expect(find.text(AppConfig.githubReleasesUrl), findsWidgets);
    expect(find.text(AppConfig.githubRepoUrl), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings About card navigates to the About screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _dragTo(tester, 'About');
    await tester.tap(find.text('About'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
