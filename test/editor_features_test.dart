import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:nova/src/features/editor/autocomplete/language_snippets.dart";
import "package:nova/src/features/editor/theme/editor_theme_pack.dart";

void main() {
  group("theme pack JSON", () {
    Map<String, dynamic> minimal({String type = "dark"}) => {
      "name": "Test",
      "type": type,
      "colors": {
        "editor.background": "#1e1e1e",
        "editor.foreground": "#d4d4d4",
      },
      "tokenColors": [
        {
          "scope": ["keyword", "storage.type"],
          "settings": {"foreground": "#569cd6", "fontStyle": "bold"},
        },
        {
          "scope": "comment",
          "settings": {"foreground": "#6a9955", "fontStyle": "italic"},
        },
      ],
    };

    test("parses valid pack with aliases and defaults", () {
      final pack = EditorThemePack.fromJson("t", minimal());
      expect(pack.name, "Test");
      expect(pack.brightness, Brightness.dark);
      expect(pack.chrome.background, const Color(0xFF1E1E1E));
      expect(pack.chrome.foreground, const Color(0xFFD4D4D4));
      // Missing chrome keys fall back to dark defaults.
      expect(pack.chrome.cursor, const Color(0xFFAEAFAD));
      // storage.type aliases to keyword.
      expect(pack.tokens["keyword"]?.color, const Color(0xFF569CD6));
      expect(pack.tokens["keyword"]?.bold, isTrue);
      expect(pack.tokens["comment"]?.italic, isTrue);
      expect(pack.toHighlightTokens()["keyword"], isA<TextStyle>());
    });

    test("round-trips through toJson", () {
      final pack = EditorThemePack.fromJson("t", minimal());
      final again = EditorThemePack.fromJson("t", pack.toJson());
      expect(again.name, pack.name);
      expect(again.brightness, pack.brightness);
      expect(again.tokens.keys.toSet(), pack.tokens.keys.toSet());
      expect(again.chrome.background, pack.chrome.background);
    });

    test("semantic colors map to highlight keys and win", () {
      final json = minimal()
        ..["semanticTokenColors"] = {
          "function": {"foreground": "#dcdcaa"},
          "variable": {"foreground": "#9cdcfe"},
        };
      final pack = EditorThemePack.fromJson("t", json);
      final tokens = pack.toHighlightTokens();
      expect(tokens["title.function"]?.color, const Color(0xFFDCDCAA));
      expect(tokens["variable"]?.color, const Color(0xFF9CDCFE));
      // Round-trip keeps semantic names.
      final again = EditorThemePack.fromJson("t", pack.toJson());
      expect(again.semantic.keys, containsAll(["function", "variable"]));
    });

    test("accent defaults per brightness, overridable", () {
      expect(
        EditorThemePack.fromJson("t", minimal()).accent,
        const Color(0xFF9FA8DA),
      );
      expect(
        EditorThemePack.fromJson("t", minimal(type: "light")).accent,
        const Color(0xFF3F51B5),
      );
      final custom = minimal()..["colors"] = {"ui.accent": "#ff0000"};
      expect(
        EditorThemePack.fromJson("t", custom).accent,
        const Color(0xFFFF0000),
      );
    });

    test("rejects bad type, bad hex, missing foreground", () {
      expect(
        () => EditorThemePack.fromJson("t", minimal(type: "neon")),
        throwsFormatException,
      );
      final badHex = minimal()
        ..["tokenColors"] = [
          {
            "scope": "keyword",
            "settings": {"foreground": "not-a-color"},
          },
        ];
      expect(
        () => EditorThemePack.fromJson("t", badHex),
        throwsFormatException,
      );
      final noFg = minimal()
        ..["tokenColors"] = [
          {
            "scope": "keyword",
            "settings": {"fontStyle": "bold"},
          },
        ];
      expect(() => EditorThemePack.fromJson("t", noFg), throwsFormatException);
    });

    test("hex parsing accepts #rgb and #rrggbb", () {
      expect(parseHexColor("#fff"), const Color(0xFFFFFFFF));
      expect(parseHexColor("000000"), const Color(0xFF000000));
      expect(parseHexColor("#1e1e1e"), const Color(0xFF1E1E1E));
      expect(() => parseHexColor("#12"), throwsFormatException);
    });
  });

  group("language snippets", () {
    test("every supported language has snippets", () {
      for (final lang in ["python", "javascript", "php", "dart", "json"]) {
        expect(snippetsForLanguage(lang), isNotEmpty, reason: lang);
      }
    });

    test("aliases resolve, unknown resolves to empty", () {
      expect(normalizeLanguageId("py"), "python");
      expect(normalizeLanguageId("JS"), "javascript");
      expect(snippetsForLanguage("cobol"), isEmpty);
      expect(snippetsForLanguage(null), isEmpty);
    });
  });
}
