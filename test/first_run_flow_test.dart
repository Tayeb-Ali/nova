import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/settings_store.dart';
import 'package:nova/src/features/onboarding/first_run_flow.dart';
import 'package:nova/src/features/onboarding/language_screen.dart';
import 'package:nova/src/features/onboarding/onboarding_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('FirstRunFlow bypasses to child under flutter test', (
    WidgetTester tester,
  ) async {
    // FLUTTER_TEST=true is set on the test VM, so the gate must yield the
    // shell immediately (this is what keeps the whole existing suite green).
    await tester.pumpWidget(_wrap(const FirstRunFlow(child: Text('shell'))));
    expect(find.text('shell'), findsOneWidget);
    expect(find.byType(LanguageScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  test('chooseLanguage persists locale + flag, invalid falls back to en', () async {
    final store = SettingsStore();
    await store.chooseLanguage('ar');
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsStore.kAppLocale), 'ar');
    expect(prefs.getBool(SettingsStore.kLanguageChosen), isTrue);
    expect(store.state.languageChosen, isTrue);

    await store.chooseLanguage('xx');
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsStore.kAppLocale), 'en');
  });

  test('completeOnboarding persists the flag', () async {
    final store = SettingsStore();
    expect(store.state.onboardingDone, isFalse);
    await store.completeOnboarding();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsStore.kOnboardingDone), isTrue);
    expect(store.state.onboardingDone, isTrue);
  });

  testWidgets('LanguageScreen defaults to English and confirms choice', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const LanguageScreen()));
    // Bounded pumps instead of pumpAndSettle: the staggered entrance
    // animations never upset the fake clock this way.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Choose your language'), findsOneWidget);
    // Default selection is English: tapping Continue keeps en.
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsStore.kAppLocale), 'en');
    expect(prefs.getBool(SettingsStore.kLanguageChosen), isTrue);
  });

  testWidgets('OnboardingScreen skip finishes the flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsStore.kOnboardingDone), isTrue);
  });
}
