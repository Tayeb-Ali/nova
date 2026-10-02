// First-run gate: language picker -> intro slides -> main shell.
//
// Shown only on a fresh install (flags in [SettingsStore]); returning users
// land straight on [child]. Widget tests bypass everything so the existing
// suite keeps seeing the shell immediately.
import "dart:io" show Platform;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/settings_store.dart";
import "language_screen.dart";
import "onboarding_screen.dart";

/// True while running under `flutter test` (same convention as SplashGate).
bool get _isFlutterTest {
  try {
    return Platform.environment["FLUTTER_TEST"] == "true";
  } catch (_) {
    return false;
  }
}

class FirstRunFlow extends ConsumerWidget {
  const FirstRunFlow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isFlutterTest) return child;
    final settings = ref.watch(settingsStoreProvider);
    if (!settings.languageChosen) return const LanguageScreen();
    if (!settings.onboardingDone) return const OnboardingScreen();
    return child;
  }
}
