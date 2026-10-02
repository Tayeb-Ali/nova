// First-run gate: language picker -> intro slides -> auth choice -> shell.
//
// Shown only on a fresh install (flags in [SettingsStore]); returning users
// land straight on [child]. Widget tests bypass everything so the existing
// suite keeps seeing the shell immediately.
import "dart:io" show Platform;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/settings_store.dart";
import "../auth/auth_providers.dart";
import "../auth/login_screen.dart";
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

/// First-run step decided by [FirstRunFlow.stepOf] (pure, unit-tested).
enum FirstRunStep { language, onboarding, auth, shell }

class FirstRunFlow extends ConsumerWidget {
  const FirstRunFlow({super.key, required this.child});

  final Widget child;

  /// Pure decision table (no env, no widgets): language first, then slides,
  /// then the auth choice (skipped when already decided or signed in).
  static FirstRunStep stepOf({
    required bool languageChosen,
    required bool onboardingDone,
    required bool authPromptDone,
    required bool signedIn,
  }) {
    if (!languageChosen) return FirstRunStep.language;
    if (!onboardingDone) return FirstRunStep.onboarding;
    if (!authPromptDone && !signedIn) return FirstRunStep.auth;
    return FirstRunStep.shell;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isFlutterTest) return child;
    final settings = ref.watch(settingsStoreProvider);
    final user = ref.watch(currentUserProvider);
    switch (stepOf(
      languageChosen: settings.languageChosen,
      onboardingDone: settings.onboardingDone,
      authPromptDone: settings.authPromptDone,
      signedIn: user != null,
    )) {
      case FirstRunStep.language:
        return const LanguageScreen();
      case FirstRunStep.onboarding:
        return const OnboardingScreen();
      case FirstRunStep.auth:
        return LoginScreen(
          onExit: () =>
              ref.read(settingsStoreProvider.notifier).markAuthPromptDone(),
        );
      case FirstRunStep.shell:
        return child;
    }
  }
}
