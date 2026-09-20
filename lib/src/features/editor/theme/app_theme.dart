import "package:flutter/material.dart";

import "editor_theme_pack.dart";

/// Builds the whole-app Material theme from an editor theme pack, so the
/// entire app follows the editor colors (VSCode-dark app with VSCode-dark
/// editor, and so on).
class AppTheme {
  static ThemeData fromPack(EditorThemePack pack) {
    final scheme = ColorScheme.fromSeed(
      seedColor: pack.accent,
      brightness: pack.brightness,
    ).copyWith(
      surface: pack.chrome.background,
      onSurface: pack.chrome.foreground,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData fallback(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
