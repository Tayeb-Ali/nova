import "package:flutter/material.dart";
import "package:flutter_riverpod/legacy.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app_config.dart";

// Immutable app settings snapshot.
@immutable
class Settings {
  final ThemeMode themeMode;
  final int timeoutMs;
  final String aiBaseUrl;
  final String aiModel;
  final String aiProvider;
  final bool autocompleteEnabled;
  // Independent AI-completion toggle: the master autocomplete switch gates
  // the whole popup system, this flag gates only the AI source within it.
  final bool aiCompletionEnabled;
  final bool followEditorTheme;
  final String editorFont;
  final double editorFontSize;
  final bool wordWrap;
  final bool autoSave;
  // Locale override: null follows the system, otherwise a code from
  // [SettingsStore.supportedLocales].
  final String? appLocale;
  // First-run flow: language picker shown until true, onboarding until true.
  final bool languageChosen;
  final bool onboardingDone;
  // Post-slides auth choice (sign in/up or guest). Shown once when set.
  final bool authPromptDone;
  const Settings({
    this.themeMode = ThemeMode.system,
    this.timeoutMs = AppConfig.defaultTimeoutMs,
    this.aiBaseUrl = SettingsStore.defaultBaseUrl,
    this.aiModel = SettingsStore.defaultModel,
    this.aiProvider = "openai",
    this.autocompleteEnabled = true,
    this.aiCompletionEnabled = true,
    this.followEditorTheme = true,
    this.editorFont = "system",
    this.editorFontSize = 13.0,
    this.wordWrap = false,
    this.autoSave = false,
    this.appLocale,
    this.languageChosen = false,
    this.onboardingDone = false,
    this.authPromptDone = false,
  });
  Settings copyWith({
    ThemeMode? themeMode,
    int? timeoutMs,
    String? aiBaseUrl,
    String? aiModel,
    String? aiProvider,
    bool? autocompleteEnabled,
    bool? aiCompletionEnabled,
    bool? followEditorTheme,
    String? editorFont,
    double? editorFontSize,
    bool? wordWrap,
    bool? autoSave,
    String? appLocale,
    bool? languageChosen,
    bool? onboardingDone,
    bool? authPromptDone,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      aiProvider: aiProvider ?? this.aiProvider,
      autocompleteEnabled: autocompleteEnabled ?? this.autocompleteEnabled,
      aiCompletionEnabled: aiCompletionEnabled ?? this.aiCompletionEnabled,
      followEditorTheme: followEditorTheme ?? this.followEditorTheme,
      editorFont: editorFont ?? this.editorFont,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      wordWrap: wordWrap ?? this.wordWrap,
      autoSave: autoSave ?? this.autoSave,
      appLocale: appLocale ?? this.appLocale,
      languageChosen: languageChosen ?? this.languageChosen,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      authPromptDone: authPromptDone ?? this.authPromptDone,
    );
  }
}

// Persists Settings via shared_preferences and exposes mutations.
class SettingsStore extends StateNotifier<Settings> {
  static const defaultBaseUrl = "https://api.openai.com/v1";
  static const defaultModel = "gpt-4o-mini";
  static const kTheme = "nova.themeMode";
  static const kTimeout = "nova.timeoutMs";
  static const kBaseUrl = "nova.aiBaseUrl";
  static const kModel = "nova.aiModel";
  static const kAiProvider = "nova.aiProvider";
  static const kAutocomplete = "nova.autocomplete";
  static const kAiCompletion = "nova.aiCompletion";
  static const kFollowTheme = "nova.followEditorTheme";
  static const kEditorFont = "nova.editorFont";
  static const kEditorFontSize = "nova.editorFontSize";
  static const kWordWrap = "nova.wordWrap";
  static const kAutoSave = "nova.autoSave";
  static const kAppLocale = "nova.appLocale";
  static const kLanguageChosen = "nova.languageChosen";
  static const kOnboardingDone = "nova.onboardingDone";
  static const kAuthPromptDone = "nova.authPromptDone";
  // Languages offered in the first-launch picker and Settings.
  // Codes must match lib/l10n/app_<code>.arb files. Default is English.
  static const supportedLocales = ["en", "ar", "fr", "es", "ru", "zh"];
  static const defaultLocale = "en";
  SettingsStore() : super(const Settings()) {
    load();
  }
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(kTheme);
    final timeout = prefs.getInt(kTimeout);
    final baseUrl = prefs.getString(kBaseUrl);
    final model = prefs.getString(kModel);
    final aiProvider = prefs.getString(kAiProvider);
    final autocomplete = prefs.getBool(kAutocomplete);
    final aiCompletion = prefs.getBool(kAiCompletion);
    final followTheme = prefs.getBool(kFollowTheme);
    final editorFont = prefs.getString(kEditorFont);
    final editorFontSize = prefs.getDouble(kEditorFontSize);
    final wordWrap = prefs.getBool(kWordWrap);
    final autoSave = prefs.getBool(kAutoSave);
    final storedLocale = prefs.getString(kAppLocale);
    // Only accepted locale codes survive; anything else falls back to system.
    final appLocale = (storedLocale != null &&
            supportedLocales.contains(storedLocale))
        ? storedLocale
        : null;
    final languageChosen = prefs.getBool(kLanguageChosen) ?? false;
    final onboardingDone = prefs.getBool(kOnboardingDone) ?? false;
    final authPromptDone = prefs.getBool(kAuthPromptDone) ?? false;
    ThemeMode mode = ThemeMode.system;
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      mode = ThemeMode.values[themeIndex];
    }
    state = Settings(
      themeMode: mode,
      timeoutMs: timeout ?? AppConfig.defaultTimeoutMs,
      aiBaseUrl: baseUrl ?? defaultBaseUrl,
      aiModel: model ?? defaultModel,
      aiProvider: aiProvider ?? "openai",
      autocompleteEnabled: autocomplete ?? true,
      aiCompletionEnabled: aiCompletion ?? true,
      followEditorTheme: followTheme ?? true,
      editorFont: editorFont ?? "system",
      editorFontSize: (editorFontSize ?? 13.0).clamp(10.0, 24.0),
      wordWrap: wordWrap ?? false,
      autoSave: autoSave ?? false,
      appLocale: appLocale,
      languageChosen: languageChosen,
      onboardingDone: onboardingDone,
      authPromptDone: authPromptDone,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kTheme, mode.index);
  }

  Future<void> setTimeoutMs(int ms) async {
    final clamped = ms.clamp(1000, 120000);
    state = state.copyWith(timeoutMs: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kTimeout, clamped);
  }

  Future<void> setAiBaseUrl(String url) async {
    final v = url.trim().isEmpty ? defaultBaseUrl : url.trim();
    state = state.copyWith(aiBaseUrl: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBaseUrl, v);
  }

  Future<void> setAiModel(String model) async {
    final v = model.trim().isEmpty ? defaultModel : model.trim();
    state = state.copyWith(aiModel: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kModel, v);
  }

  Future<void> setAiProvider(String id) async {
    state = state.copyWith(aiProvider: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAiProvider, id);
  }

  Future<void> setAutocompleteEnabled(bool enabled) async {
    state = state.copyWith(autocompleteEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAutocomplete, enabled);
  }

  Future<void> setAiCompletionEnabled(bool enabled) async {
    state = state.copyWith(aiCompletionEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAiCompletion, enabled);
  }

  Future<void> setFollowEditorTheme(bool follow) async {
    state = state.copyWith(followEditorTheme: follow);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kFollowTheme, follow);
  }

  Future<void> setEditorFont(String id) async {
    state = state.copyWith(editorFont: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kEditorFont, id);
  }

  Future<void> setEditorFontSize(double size) async {
    final clamped = size.clamp(10.0, 24.0);
    state = state.copyWith(editorFontSize: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kEditorFontSize, clamped);
  }

  Future<void> setWordWrap(bool enabled) async {
    state = state.copyWith(wordWrap: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kWordWrap, enabled);
  }

  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSave: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAutoSave, enabled);
  }

  // Sets the locale override (null follows the system); copyWith keeps the
  // old value on null, so rebuild explicitly to allow clearing to system.
  Future<void> setAppLocale(String? locale) async {
    final v = (locale != null && supportedLocales.contains(locale))
        ? locale
        : null;
    state = Settings(
      themeMode: state.themeMode,
      timeoutMs: state.timeoutMs,
      aiBaseUrl: state.aiBaseUrl,
      aiModel: state.aiModel,
      aiProvider: state.aiProvider,
      autocompleteEnabled: state.autocompleteEnabled,
      aiCompletionEnabled: state.aiCompletionEnabled,
      followEditorTheme: state.followEditorTheme,
      editorFont: state.editorFont,
      editorFontSize: state.editorFontSize,
      wordWrap: state.wordWrap,
      autoSave: state.autoSave,
      appLocale: v,
      languageChosen: state.languageChosen,
      onboardingDone: state.onboardingDone,
      authPromptDone: state.authPromptDone,
    );
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove(kAppLocale);
    } else {
      await prefs.setString(kAppLocale, v);
    }
  }

  /// Marks the first-launch language choice done (with the given locale).
  Future<void> chooseLanguage(String code) async {
    final v = supportedLocales.contains(code) ? code : defaultLocale;
    await setAppLocale(v);
    state = state.copyWith(languageChosen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLanguageChosen, true);
  }

  /// Marks the intro slides seen so they never show again.
  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDone, true);
  }

  /// Marks the post-slides auth choice done (signed in or guest).
  Future<void> markAuthPromptDone() async {
    state = state.copyWith(authPromptDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAuthPromptDone, true);
  }
}

final settingsStoreProvider = StateNotifierProvider<SettingsStore, Settings>(
  (ref) => SettingsStore(),
);
