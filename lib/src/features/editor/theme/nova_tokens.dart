import "package:flutter/material.dart";

// Nova design tokens from themes/developer_console/DESIGN.md.
// Dark values come from the front-matter palette; light values reuse the
// same hues via the "fixed"/"inverse" roles where DESIGN.md defines them
// (inverse-primary, primary/secondary/tertiary-fixed, on-error-container).
// Light outline/error values with no DESIGN.md counterpart follow the
// Material 3 baseline and are marked below.

// App-level colors (surfaces, roles, containers, outlines).
abstract final class NovaColors {
  // Dark scheme.
  static const Color darkSurface = Color(0xFF131313);
  static const Color darkSurfaceDim = Color(0xFF131313);
  static const Color darkSurfaceBright = Color(0xFF393939);
  static const Color darkContainerLowest = Color(0xFF0E0E0E);
  static const Color darkContainerLow = Color(0xFF1B1B1C);
  static const Color darkContainer = Color(0xFF202020);
  static const Color darkContainerHigh = Color(0xFF2A2A2A);
  static const Color darkContainerHighest = Color(0xFF353535);
  static const Color darkOnSurface = Color(0xFFE5E2E1);
  static const Color darkOnSurfaceVariant = Color(0xFFC0C7D3);
  static const Color darkInverseSurface = Color(0xFFE5E2E1);
  static const Color darkOnInverseSurface = Color(0xFF303030);
  static const Color darkSurfaceTint = Color(0xFF9FCAFF);
  static const Color darkPrimary = Color(0xFF007ACC);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkPrimaryContainer = Color(0xFF007ACC);
  static const Color darkOnPrimaryContainer = Color(0xFFFFFFFF);
  static const Color darkPrimaryFixed = Color(0xFFD1E4FF);
  static const Color darkPrimaryFixedDim = Color(0xFF9FCAFF);
  static const Color darkOnPrimaryFixed = Color(0xFF001D36);
  static const Color darkOnPrimaryFixedVariant = Color(0xFF00497D);
  static const Color darkSecondary = Color(0xFFCEBDFF);
  static const Color darkOnSecondary = Color(0xFF381385);
  static const Color darkSecondaryContainer = Color(0xFF4F319C);
  static const Color darkOnSecondaryContainer = Color(0xFFBEA8FF);
  static const Color darkTertiary = Color(0xFF61DAC1);
  static const Color darkOnTertiary = Color(0xFF00382E);
  static const Color darkTertiaryContainer = Color(0xFF008672);
  static const Color darkOnTertiaryContainer = Color(0xFFFFFFFF);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  static const Color darkOutline = Color(0xFF8A919D);
  static const Color darkOutlineVariant = Color(0xFF404751);
  static const Color darkBorder = Color(0xFF333333);
  // Recessed input interior/border from the DESIGN.md input section.
  static const Color darkInputBackground = Color(0xFF1E1E1E);
  static const Color darkInputBorder = Color(0xFF3C3C3C);

  // Light scheme (same hues, stepped down toward white).
  static const Color lightSurface = Color(0xFFFAFAF8);
  static const Color lightSurfaceDim = Color(0xFFE0DDD7);
  static const Color lightSurfaceBright = Color(0xFFFFFFFF);
  static const Color lightContainerLowest = Color(0xFFFFFFFF);
  static const Color lightContainerLow = Color(0xFFF3F0EB);
  static const Color lightContainer = Color(0xFFEAE7E1);
  static const Color lightContainerHigh = Color(0xFFE0DDD7);
  static const Color lightContainerHighest = Color(0xFFD5D2CC);
  static const Color lightOnSurface = Color(0xFF303030);
  static const Color lightOnSurfaceVariant = Color(0xFF4C5158);
  static const Color lightInverseSurface = Color(0xFF131313);
  static const Color lightOnInverseSurface = Color(0xFFE5E2E1);
  static const Color lightSurfaceTint = Color(0xFF0061A4);
  static const Color lightPrimary = Color(0xFF0061A4);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFD1E4FF);
  static const Color lightOnPrimaryContainer = Color(0xFF001D36);
  static const Color lightSecondary = Color(0xFF4F319C);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFE8DDFF);
  static const Color lightOnSecondaryContainer = Color(0xFF21005E);
  static const Color lightTertiary = Color(0xFF005144);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFF80F7DC);
  static const Color lightOnTertiaryContainer = Color(0xFF00201A);
  // No light error in DESIGN.md; follows the Material 3 baseline red.
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF690005);
  static const Color lightOutline = Color(0xFF8A919D);
  static const Color lightOutlineVariant = Color(0xFFD5D2CC);
  static const Color lightBorder = Color(0xFFD5D2CC);
  static const Color lightInputBackground = Color(0xFFEAE7E1);
}

// Editor chrome colors (background, cursor, selection, gutters).
// Dark values match EditorThemePack.defaultChrome(Brightness.dark);
// light values pair the light app surface with the existing light accents.
abstract final class NovaEditorChrome {
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkForeground = Color(0xFFD4D4D4);
  static const Color darkCursor = Color(0xFFAEAFAD);
  static const Color darkSelection = Color(0xFF264F78);
  static const Color darkLineNumber = Color(0xFF858585);
  static const Color darkLineHighlight = Color(0xFF2A2D2E);

  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightForeground = Color(0xFF1E1E1E);
  static const Color lightCursor = Color(0xFF000000);
  static const Color lightSelection = Color(0xFFADD6FF);
  static const Color lightLineNumber = Color(0xFF999999);
  static const Color lightLineHighlight = Color(0xFFEAE7E1);
}

// Syntax token colors shared by the nova packs (DESIGN.md Colors section).
// Keyword is bold and comment is italic in the pack definitions below.
abstract final class NovaSyntax {
  static const Color keyword = Color(0xFFA78BFA);
  static const Color type = Color(0xFF4EC9B0);
  static const Color string = Color(0xFFCE9178);
  static const Color number = Color(0xFF61DAC1);
  static const Color comment = Color(0xFF858585);
  static const Color function = Color(0xFF9FCAFF);
}

// Corner radii (DESIGN.md Shapes: 4px baseline, 6px popover, 12px hub card).
abstract final class NovaRadius {
  static const double baseline = 4.0;
  static const double popover = 6.0;
  static const double hubCard = 12.0;

  static const BorderRadius baselineRadius =
      BorderRadius.all(Radius.circular(baseline));
  static const BorderRadius popoverRadius =
      BorderRadius.all(Radius.circular(popover));
  static const BorderRadius hubCardRadius =
      BorderRadius.all(Radius.circular(hubCard));
}

// Spacing scale on the DESIGN.md 4px grid (space-xs through space-xl).
abstract final class NovaSpacing {
  static const double grid = 4.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double gutter = 8.0;
}
