import "package:flutter/material.dart";

/// A single syntax token style (color + emphasis).
class TokenStyle {
  const TokenStyle({
    required this.color,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  final Color color;
  final bool bold;
  final bool italic;
  final bool underline;

  TextStyle toTextStyle() => TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.bold : null,
        fontStyle: italic ? FontStyle.italic : null,
        decoration: underline ? TextDecoration.underline : null,
      );

  Map<String, dynamic> toJson() => {
        "foreground": toHexString(color),
        "fontStyle": [
          if (bold) "bold",
          if (italic) "italic",
          if (underline) "underline",
        ].join(" "),
      };
}

/// Non-token editor chrome colors (background, caret, selection...).
class EditorChrome {
  const EditorChrome({
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.lineNumber,
    required this.lineHighlight,
  });

  final Color background;
  final Color foreground;
  final Color cursor;
  final Color selection;
  final Color lineNumber;
  final Color lineHighlight;
}

/// A full editor theme pack: token colors + semantic colors + chrome.
class EditorThemePack {
  const EditorThemePack({
    required this.id,
    required this.name,
    required this.brightness,
    required this.tokens,
    this.semantic = const {},
    required this.chrome,
    required this.accent,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Map<String, TokenStyle> tokens;

  /// VSCode-style semantic colors (function, variable, class...), mapped to
  /// highlight keys by [semanticTargets].
  final Map<String, TokenStyle> semantic;
  final EditorChrome chrome;

  /// UI accent driving the whole app color scheme when follow-mode is on.
  final Color accent;

  /// Parses the approved VSCode-compatible subset schema:
  /// `{name, type: light|dark, colors: {editor.*}, tokenColors: [{scope, settings}]}`.
  factory EditorThemePack.fromJson(String id, Map<String, dynamic> json) {
    final rawType = (json["type"] as String? ?? "dark").toLowerCase();
    if (rawType != "light" && rawType != "dark") {
      throw FormatException('Unknown theme type "$rawType" (want light|dark)');
    }
    final brightness =
        rawType == "light" ? Brightness.light : Brightness.dark;
    final colors = json["colors"];
    final colorMap = colors is Map<String, dynamic>
        ? colors
        : <String, dynamic>{};
    final fallback = defaultChrome(brightness);
    Color pick(String key, Color orElse) {
      final raw = colorMap[key];
      if (raw == null) return orElse;
      if (raw is! String) {
        throw FormatException('Color "$key" must be a hex string');
      }
      return parseHexColor(raw);
    }

    final chrome = EditorChrome(
      background: pick("editor.background", fallback.background),
      foreground: pick("editor.foreground", fallback.foreground),
      cursor: pick("editorCursor.foreground", fallback.cursor),
      lineNumber: pick("editorLineNumber.foreground", fallback.lineNumber),
      selection: pick("editor.selectionBackground", fallback.selection),
      lineHighlight:
          pick("editor.lineHighlightBackground", fallback.lineHighlight),
    );
    final accent = pick(
      "ui.accent",
      brightness == Brightness.light
          ? const Color(0xFF3F51B5)
          : const Color(0xFF9FA8DA),
    );

    final tokens = _parseTokenList(json["tokenColors"]);
    final semantic = _parseSemantic(json["semanticTokenColors"]);
    return EditorThemePack(
      id: id,
      name: json["name"] as String? ?? "Custom Theme",
      brightness: brightness,
      tokens: tokens,
      semantic: semantic,
      chrome: chrome,
      accent: accent,
    );
  }

  static Map<String, TokenStyle> _parseTokenList(dynamic rawRules) {
    final rules = rawRules is List ? rawRules : const [];
    final tokens = <String, TokenStyle>{};
    for (final rule in rules) {
      if (rule is! Map<String, dynamic>) {
        throw const FormatException("Each tokenColors entry must be an object");
      }
      tokens.addAll(_parseRule(rule, resolveScope));
    }
    return tokens;
  }

  static Map<String, TokenStyle> _parseSemantic(dynamic rawRules) {
    if (rawRules == null) return {};
    if (rawRules is! Map<String, dynamic>) {
      throw const FormatException("semanticTokenColors must be an object");
    }
    final semantic = <String, TokenStyle>{};
    for (final entry in rawRules.entries) {
      if (entry.value is! Map<String, dynamic>) {
        throw FormatException(
            'semanticTokenColors["${entry.key}"] must be an object');
      }
      // Kept keyed by semantic name ("function"); resolved to highlight
      // keys at merge time by [semanticTargets].
      semantic[entry.key.trim().toLowerCase()] =
          _parseSettings(entry.value as Map<String, dynamic>);
    }
    return semantic;
  }

  static Map<String, TokenStyle> _parseRule(
    Map<String, dynamic> rule,
    String Function(String) keyOf,
  ) {
    final settings = rule["settings"];
    if (settings is! Map<String, dynamic>) {
      throw const FormatException("tokenColors entry needs a settings object");
    }
    final style = _parseSettings(settings);
    final out = <String, TokenStyle>{};
    for (final scope in _expandScope(rule["scope"])) {
      out[keyOf(scope)] = style;
    }
    return out;
  }

  static TokenStyle _parseSettings(Map<String, dynamic> settings) {
    final fg = settings["foreground"];
    if (fg is! String) {
      throw const FormatException(
          "color settings needs a foreground hex string");
    }
    final (bold, italic, underline) =
        parseFontStyle(settings["fontStyle"] as String? ?? "");
    return TokenStyle(
      color: parseHexColor(fg),
      bold: bold,
      italic: italic,
      underline: underline,
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "type": brightness == Brightness.light ? "light" : "dark",
        "colors": {
          "editor.background": toHexString(chrome.background),
          "editor.foreground": toHexString(chrome.foreground),
          "editorCursor.foreground": toHexString(chrome.cursor),
          "editorLineNumber.foreground": toHexString(chrome.lineNumber),
          "editor.selectionBackground": toHexString(chrome.selection),
          "editor.lineHighlightBackground":
              toHexString(chrome.lineHighlight),
          "ui.accent": toHexString(accent),
        },
        "tokenColors": [
          for (final entry in tokens.entries)
            {
              "scope": entry.key,
              "settings": entry.value.toJson(),
            },
        ],
        "semanticTokenColors": {
          for (final entry in semantic.entries)
            entry.key: entry.value.toJson(),
        },
      };

  /// Token map ready for re_editor's CodeHighlightTheme.
  /// Semantic colors win over plain token colors (VSCode behavior).
  Map<String, TextStyle> toHighlightTokens() {
    final merged = <String, TokenStyle>{...tokens};
    for (final entry in semantic.entries) {
      for (final target in semanticTargets(entry.key)) {
        merged[target] = entry.value;
      }
    }
    return {
      for (final entry in merged.entries)
        entry.key: entry.value.toTextStyle(),
    };
  }

  /// Maps a VSCode TextMate scope to a re_highlight token key.
  /// Known aliases are remapped; anything else passes through verbatim.
  static String resolveScope(String scope) {
    final key = scope.trim().toLowerCase();
    return scopeAliases[key] ?? key;
  }

  static const Map<String, String> scopeAliases = {
    "comment": "comment",
    "string": "string",
    "keyword": "keyword",
    "keyword.control": "keyword",
    "keyword.operator": "operator",
    "storage.type": "keyword",
    "storage.modifier": "keyword",
    "constant.numeric": "number",
    "constant.language": "literal",
    "entity.name.function": "title",
    "entity.name.class": "title.class_",
    "entity.name.type": "type",
    "support.function": "built_in",
    "variable": "variable",
    "meta": "meta",
    "markup.bold": "strong",
    "markup.italic": "emphasis",
  };

  /// Maps a VSCode semantic token (function, variable, class...) to the
  /// highlight keys it colors. Unknown names pass through verbatim.
  static List<String> semanticTargets(String name) {
    return _semanticMap[name.trim().toLowerCase()] ?? [name.trim()];
  }

  static const Map<String, List<String>> _semanticMap = {
    "function": ["title.function"],
    "method": ["title.function"],
    "class": ["title.class_"],
    "interface": ["title.class_"],
    "enum": ["type"],
    "type": ["type"],
    "typeparameter": ["type"],
    "variable": ["variable"],
    "parameter": ["variable"],
    "property": ["attr"],
    "field": ["attr"],
    "namespace": ["title"],
    "macro": ["meta"],
  };

  static List<String> _expandScope(dynamic scope) {
    if (scope is String) {
      return scope
          .split(",")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (scope is List) {
      return [
        for (final s in scope)
          if (s is String && s.trim().isNotEmpty) s.trim(),
      ];
    }
    throw const FormatException("tokenColors scope must be a string or list");
  }

  /// Sensible chrome defaults per brightness.
  static EditorChrome defaultChrome(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const EditorChrome(
        background: Color(0xFFFFFFFF),
        foreground: Color(0xFF000000),
        cursor: Color(0xFF000000),
        selection: Color(0xFFADD6FF),
        lineNumber: Color(0xFF858585),
        lineHighlight: Color(0x0A000000),
      );
    }
    return const EditorChrome(
      background: Color(0xFF1E1E1E),
      foreground: Color(0xFFD4D4D4),
      cursor: Color(0xFFAEAFAD),
      selection: Color(0xFF264F78),
      lineNumber: Color(0xFF858585),
      lineHighlight: Color(0x0AFFFFFF),
    );
  }
}

/// Parses "#rgb", "#rrggbb", "#rrggbbaa" (leading '#' optional).
Color parseHexColor(String raw) {
  var hex = raw.trim();
  if (hex.startsWith("#")) hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split("").map((c) => "$c$c").join();
  }
  if (hex.length == 6) hex = "FF$hex";
  if (hex.length != 8 || int.tryParse(hex, radix: 16) == null) {
    throw FormatException('Invalid hex color "$raw"');
  }
  return Color(int.parse(hex, radix: 16));
}

String toHexString(Color color) {
  String channel(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, "0");
  final hex = "${channel(color.a)}${channel(color.r)}"
          "${channel(color.g)}${channel(color.b)}"
      .toUpperCase();
  if (hex.startsWith("FF")) return "#${hex.substring(2)}";
  return "#$hex";
}

/// Parses VSCode-style space-separated fontStyle ("bold italic").
(bool bold, bool italic, bool underline) parseFontStyle(String raw) {
  final parts = raw.toLowerCase().split(RegExp(r"\s+"));
  return (
    parts.contains("bold"),
    parts.contains("italic"),
    parts.contains("underline"),
  );
}
