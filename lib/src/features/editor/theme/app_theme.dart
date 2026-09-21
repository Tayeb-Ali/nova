import "package:flutter/material.dart";

import "builtin_packs.dart";
import "editor_theme_pack.dart";
import "nova_tokens.dart";

/// Builds the whole-app Material theme from an editor theme pack, so the
/// entire app follows the editor colors (Nova-dark app with Nova-dark
/// editor, and so on).
///
/// The final ColorScheme is assembled BEFORE constructing ThemeData so all
/// derived colors (canvas, scaffold background, dialogs...) compute from it;
/// mutating a scheme via copyWith after construction would leave them stale.
///
/// The primary role is resolved from [NovaColors] per brightness (matching
/// each pack's accent) so the app chrome stays on the Nova palette even for
/// user-imported packs.
class AppTheme {
  static ColorScheme schemeFor(EditorThemePack pack) {
    final bool dark = pack.brightness == Brightness.dark;
    return ColorScheme(
      brightness: pack.brightness,
      primary: dark ? NovaColors.darkPrimary : NovaColors.lightPrimary,
      onPrimary: dark ? NovaColors.darkOnPrimary : NovaColors.lightOnPrimary,
      primaryContainer: dark
          ? NovaColors.darkPrimaryContainer
          : NovaColors.lightPrimaryContainer,
      onPrimaryContainer: dark
          ? NovaColors.darkOnPrimaryContainer
          : NovaColors.lightOnPrimaryContainer,
      secondary: dark ? NovaColors.darkSecondary : NovaColors.lightSecondary,
      onSecondary:
          dark ? NovaColors.darkOnSecondary : NovaColors.lightOnSecondary,
      secondaryContainer: dark
          ? NovaColors.darkSecondaryContainer
          : NovaColors.lightSecondaryContainer,
      onSecondaryContainer: dark
          ? NovaColors.darkOnSecondaryContainer
          : NovaColors.lightOnSecondaryContainer,
      tertiary: dark ? NovaColors.darkTertiary : NovaColors.lightTertiary,
      onTertiary:
          dark ? NovaColors.darkOnTertiary : NovaColors.lightOnTertiary,
      tertiaryContainer: dark
          ? NovaColors.darkTertiaryContainer
          : NovaColors.lightTertiaryContainer,
      onTertiaryContainer: dark
          ? NovaColors.darkOnTertiaryContainer
          : NovaColors.lightOnTertiaryContainer,
      error: dark ? NovaColors.darkError : NovaColors.lightError,
      onError: dark ? NovaColors.darkOnError : NovaColors.lightOnError,
      errorContainer: dark
          ? NovaColors.darkErrorContainer
          : NovaColors.lightErrorContainer,
      onErrorContainer: dark
          ? NovaColors.darkOnErrorContainer
          : NovaColors.lightOnErrorContainer,
      surface: pack.chrome.background,
      onSurface: pack.chrome.foreground,
      surfaceDim:
          dark ? NovaColors.darkSurfaceDim : NovaColors.lightSurfaceDim,
      surfaceBright:
          dark ? NovaColors.darkSurfaceBright : NovaColors.lightSurfaceBright,
      surfaceContainerLowest: dark
          ? NovaColors.darkContainerLowest
          : NovaColors.lightContainerLowest,
      surfaceContainerLow: dark
          ? NovaColors.darkContainerLow
          : NovaColors.lightContainerLow,
      surfaceContainer:
          dark ? NovaColors.darkContainer : NovaColors.lightContainer,
      surfaceContainerHigh: dark
          ? NovaColors.darkContainerHigh
          : NovaColors.lightContainerHigh,
      surfaceContainerHighest: dark
          ? NovaColors.darkContainerHighest
          : NovaColors.lightContainerHighest,
      onSurfaceVariant: dark
          ? NovaColors.darkOnSurfaceVariant
          : NovaColors.lightOnSurfaceVariant,
      outline: dark ? NovaColors.darkOutline : NovaColors.lightOutline,
      outlineVariant: dark
          ? NovaColors.darkOutlineVariant
          : NovaColors.lightOutlineVariant,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface:
          dark ? NovaColors.darkInverseSurface : NovaColors.lightInverseSurface,
      onInverseSurface: dark
          ? NovaColors.darkOnInverseSurface
          : NovaColors.lightOnInverseSurface,
      inversePrimary:
          dark ? NovaColors.darkPrimaryFixedDim : NovaColors.lightPrimary,
      surfaceTint:
          dark ? NovaColors.darkSurfaceTint : NovaColors.lightSurfaceTint,
    );
  }

  static ThemeData fromPack(EditorThemePack pack) {
    final ColorScheme scheme = schemeFor(pack);
    final bool dark = pack.brightness == Brightness.dark;
    final Color inputFill =
        dark ? NovaColors.darkInputBackground : NovaColors.lightInputBackground;
    final Color inputBorderColor =
        dark ? NovaColors.darkInputBorder : NovaColors.lightOutline;
    final BorderRadius buttonRadius = NovaRadius.baselineRadius;
    final ButtonStyle buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 36)),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
    );
    OutlineInputBorder inputBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: NovaRadius.baselineRadius,
        borderSide: BorderSide(color: color),
      );
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: inputBorder(inputBorderColor),
        enabledBorder: inputBorder(inputBorderColor),
        focusedBorder: inputBorder(scheme.primary),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: NovaRadius.hubCardRadius),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: NovaRadius.popoverRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(color: scheme.onSurface),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }

  static ThemeData fallback(Brightness brightness) {
    return fromPack(
      brightness == Brightness.light
          ? BuiltinThemePacks.novaLight
          : BuiltinThemePacks.novaDark,
    );
  }
}
