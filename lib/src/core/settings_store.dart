import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app_config.dart";

// Immutable app settings snapshot.
@immutable
class Settings {
  final ThemeMode themeMode;
  final int timeoutMs;
  final String aiBaseUrl;
  final String aiModel;
  const Settings({
    this.themeMode = ThemeMode.system,
    this.timeoutMs = AppConfig.defaultTimeoutMs,
    this.aiBaseUrl = SettingsStore.defaultBaseUrl,
    this.aiModel = SettingsStore.defaultModel,
  });
  Settings copyWith({
    ThemeMode? themeMode,
    int? timeoutMs,
    String? aiBaseUrl,
    String? aiModel,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
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
  SettingsStore() : super(const Settings()) {
    load();
  }
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(kTheme);
    final timeout = prefs.getInt(kTimeout);
    final baseUrl = prefs.getString(kBaseUrl);
    final model = prefs.getString(kModel);
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
}

final settingsStoreProvider = StateNotifierProvider<SettingsStore, Settings>(
  (ref) => SettingsStore(),
);
