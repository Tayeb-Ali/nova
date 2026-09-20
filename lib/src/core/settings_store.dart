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
  final bool autocompleteEnabled;
  final bool followEditorTheme;
  final String editorFont;
  final double editorFontSize;
  // Locale override: null follows the system, otherwise 'ar' or 'en'.
  final String? appLocale;
  const Settings({
    this.themeMode = ThemeMode.system,
    this.timeoutMs = AppConfig.defaultTimeoutMs,
    this.aiBaseUrl = SettingsStore.defaultBaseUrl,
    this.aiModel = SettingsStore.defaultModel,
    this.autocompleteEnabled = true,
    this.followEditorTheme = true,
    this.editorFont = "system",
    this.editorFontSize = 13.0,
    this.appLocale,
  });
  Settings copyWith({
    ThemeMode? themeMode,
    int? timeoutMs,
    String? aiBaseUrl,
    String? aiModel,
    bool? autocompleteEnabled,
    bool? followEditorTheme,
    String? editorFont,
    double? editorFontSize,
    String? appLocale,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      autocompleteEnabled: autocompleteEnabled ?? this.autocompleteEnabled,
      followEditorTheme: followEditorTheme ?? this.followEditorTheme,
      editorFont: editorFont ?? this.editorFont,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      appLocale: appLocale ?? this.appLocale,
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
  static const kAutocomplete = "nova.autocomplete";
  static const kFollowTheme = "nova.followEditorTheme";
  static const kEditorFont = "nova.editorFont";
  static const kEditorFontSize = "nova.editorFontSize";
  static const kAppLocale = "nova.appLocale";
  SettingsStore() : super(const Settings()) {
    load();
  }
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(kTheme);
    final timeout = prefs.getInt(kTimeout);
    final baseUrl = prefs.getString(kBaseUrl);
    final model = prefs.getString(kModel);
    final autocomplete = prefs.getBool(kAutocomplete);
    final followTheme = prefs.getBool(kFollowTheme);
    final editorFont = prefs.getString(kEditorFont);
    final editorFontSize = prefs.getDouble(kEditorFontSize);
    final storedLocale = prefs.getString(kAppLocale);
    // Only accepted locale codes survive; anything else falls back to system.
    final appLocale = (storedLocale == "ar" || storedLocale == "en")
        ? storedLocale
        : null;
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
      autocompleteEnabled: autocomplete ?? true,
      followEditorTheme: followTheme ?? true,
      editorFont: editorFont ?? "system",
      editorFontSize: (editorFontSize ?? 13.0).clamp(10.0, 24.0),
      appLocale: appLocale,
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

  Future<void> setAutocompleteEnabled(bool enabled) async {
    state = state.copyWith(autocompleteEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAutocomplete, enabled);
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

  // Sets the locale override (null follows the system); copyWith keeps the
  // old value on null, so rebuild explicitly to allow clearing to system.
  Future<void> setAppLocale(String? locale) async {
    final v = (locale == "ar" || locale == "en") ? locale : null;
    state = Settings(
      themeMode: state.themeMode,
      timeoutMs: state.timeoutMs,
      aiBaseUrl: state.aiBaseUrl,
      aiModel: state.aiModel,
      autocompleteEnabled: state.autocompleteEnabled,
      followEditorTheme: state.followEditorTheme,
      editorFont: state.editorFont,
      editorFontSize: state.editorFontSize,
      appLocale: v,
    );
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove(kAppLocale);
    } else {
      await prefs.setString(kAppLocale, v);
    }
  }
}

final settingsStoreProvider = StateNotifierProvider<SettingsStore, Settings>(
  (ref) => SettingsStore(),
);
