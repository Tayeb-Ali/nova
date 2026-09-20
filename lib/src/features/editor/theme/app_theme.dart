import "package:flutter/material.dart";

import "editor_theme_pack.dart";

/// Builds the whole-app Material theme from an editor theme pack, so the
/// entire app follows the editor colors (VSCode-dark app with VSCode-dark
/// editor, and so on).
///
/// The final ColorScheme is assembled BEFORE constructing ThemeData so all
/// derived colors (canvas, scaffold background, dialogs...) compute from it;
/// mutating a scheme via copyWith after construction would leave them stale.
class AppTheme {
  static ColorScheme schemeFor(EditorThemePack pack) {
    return ColorScheme.fromSeed(
      seedColor: pack.accent,
      brightness: pack.brightness,
    ).copyWith(
      surface: pack.chrome.background,
      onSurface: pack.chrome.foreground,
    );
  }

  static ThemeData fromPack(EditorThemePack pack) {
    return ThemeData(colorScheme: schemeFor(pack), useMaterial3: true);
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
