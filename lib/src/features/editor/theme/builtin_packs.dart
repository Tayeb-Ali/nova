import "package:flutter/material.dart";
import "package:re_highlight/styles/atom-one-dark.dart";
import "package:re_highlight/styles/atom-one-light.dart";
import "package:re_highlight/styles/github-dark.dart";
import "package:re_highlight/styles/github.dart";
import "package:re_highlight/styles/monokai.dart";
import "package:re_highlight/styles/night-owl.dart";
import "package:re_highlight/styles/nord.dart";
import "package:re_highlight/styles/tokyo-night-dark.dart";
import "package:re_highlight/styles/vs.dart";
import "package:re_highlight/styles/vs2015.dart";

import "editor_theme_pack.dart";

/// Built-in packs wrapping re_highlight's bundled styles.
class BuiltinThemePacks {
  static const String defaultLightPackId = "vs";
  static const String defaultDarkPackId = "vs2015";

  static final List<EditorThemePack> all = [
    _fromMap(
      id: "vs",
      name: "VSCode Light",
      brightness: Brightness.light,
      tokens: vsTheme,
      semantic: _vsLightSemantic,
    ),
    _fromMap(
      id: "vs2015",
      name: "VSCode Dark",
      brightness: Brightness.dark,
      tokens: vs2015Theme,
      semantic: _vsDarkSemantic,
    ),
    _fromMap(
      id: "atom-one-light",
      name: "Atom One Light",
      brightness: Brightness.light,
      tokens: atomOneLightTheme,
    ),
    _fromMap(
      id: "atom-one-dark",
      name: "Atom One Dark",
      brightness: Brightness.dark,
      tokens: atomOneDarkTheme,
    ),
    _fromMap(
      id: "github",
      name: "GitHub Light",
      brightness: Brightness.light,
      tokens: githubTheme,
    ),
    _fromMap(
      id: "github-dark",
      name: "GitHub Dark",
      brightness: Brightness.dark,
      tokens: githubDarkTheme,
    ),
    _fromMap(
      id: "monokai",
      name: "Monokai",
      brightness: Brightness.dark,
      tokens: monokaiTheme,
    ),
    _fromMap(
      id: "nord",
      name: "Nord",
      brightness: Brightness.dark,
      tokens: nordTheme,
    ),
    _fromMap(
      id: "tokyo-night-dark",
      name: "Tokyo Night",
      brightness: Brightness.dark,
      tokens: tokyoNightDarkTheme,
    ),
    _fromMap(
      id: "night-owl",
      name: "Night Owl",
      brightness: Brightness.dark,
      tokens: nightOwlTheme,
    ),
  ];

  static EditorThemePack? byId(String id) {
    for (final pack in all) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// w700 and heavier count as bold.
  static bool _isBold(FontWeight? weight) =>
      (weight?.value ?? FontWeight.normal.value) >= FontWeight.w700.value;

  static EditorThemePack _fromMap({
    required String id,
    required String name,
    required Brightness brightness,
    required Map<String, TextStyle> tokens,
    Map<String, TokenStyle> semantic = const {},
  }) {
    final fallback = EditorThemePack.defaultChrome(brightness);
    final root = tokens["root"];
    final parsed = <String, TokenStyle>{};
    for (final entry in tokens.entries) {
      if (entry.key == "root") continue;
      final style = entry.value;
      parsed[entry.key] = TokenStyle(
        color: style.color ?? fallback.foreground,
        bold: _isBold(style.fontWeight),
        italic: style.fontStyle == FontStyle.italic,
        underline: style.decoration == TextDecoration.underline,
      );
    }
    return EditorThemePack(
      id: id,
      name: name,
      brightness: brightness,
      tokens: parsed,
      semantic: semantic,
      chrome: EditorChrome(
        background: root?.backgroundColor ?? fallback.background,
        foreground: root?.color ?? fallback.foreground,
        cursor: fallback.cursor,
        selection: fallback.selection,
        lineNumber: fallback.lineNumber,
        lineHighlight: fallback.lineHighlight,
      ),
      accent: brightness == Brightness.light
          ? const Color(0xFF3F51B5)
          : const Color(0xFF9FA8DA),
    );
  }

  /// VSCode Dark+ semantic colors (the stock vs2015 map lacks function /
  /// variable / class distinction, so we layer the real palette on top).
  static const _vsDarkSemantic = {
    "function": TokenStyle(color: Color(0xFFDCDCAA)),
    "method": TokenStyle(color: Color(0xFFDCDCAA)),
    "variable": TokenStyle(color: Color(0xFF9CDCFE)),
    "parameter": TokenStyle(color: Color(0xFF9CDCFE)),
    "property": TokenStyle(color: Color(0xFF9CDCFE)),
    "class": TokenStyle(color: Color(0xFF4EC9B0)),
    "interface": TokenStyle(color: Color(0xFF4EC9B0)),
    "enum": TokenStyle(color: Color(0xFF4EC9B0)),
    "type": TokenStyle(color: Color(0xFF4EC9B0)),
  };

  /// VSCode Light+ semantic colors.
  static const _vsLightSemantic = {
    "function": TokenStyle(color: Color(0xFF795E26)),
    "method": TokenStyle(color: Color(0xFF795E26)),
    "variable": TokenStyle(color: Color(0xFF001080)),
    "parameter": TokenStyle(color: Color(0xFF001080)),
    "property": TokenStyle(color: Color(0xFF001080)),
    "class": TokenStyle(color: Color(0xFF267F99)),
    "interface": TokenStyle(color: Color(0xFF267F99)),
    "enum": TokenStyle(color: Color(0xFF267F99)),
    "type": TokenStyle(color: Color(0xFF267F99)),
  };
}
