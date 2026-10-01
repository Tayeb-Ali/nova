import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/features/splash/splash_screen.dart';

/// Splash strings come from the translation files, so the harness must
/// provide the real localization delegates (default test locale is English).
Widget _harness(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('SplashScreen shows brand loader from translations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(const SplashScreen()));
    await tester.pump();
    expect(find.text('Nova'), findsOneWidget);
    expect(
      find.text('Your dev environment in your pocket'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashGate falls through to the child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(const SplashGate(child: Text('home'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
