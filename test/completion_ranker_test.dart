import "package:flutter_test/flutter_test.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/dart.dart";

import "package:nova/src/features/editor/autocomplete/completion_ranker.dart";

void main() {
  group("fuzzyScore", () {
    test("exact word is excluded (null)", () {
      expect(fuzzyScore("print", "print"), isNull);
    });

    test("prefix outranks substring outranks fuzzy", () {
      final int prefix = fuzzyScore("println", "pr")!;
      final int substring = fuzzyScore("sprinkle", "pr")!;
      final int fuzzy = fuzzyScore("super", "pr")!;
      expect(prefix, greaterThan(substring));
      expect(substring, greaterThan(fuzzy));
    });

    test("no match yields null", () {
      expect(fuzzyScore("print", "xyz"), isNull);
      expect(fuzzyScore("ab", "abc"), isNull);
    });

    test("case-insensitive", () {
      expect(fuzzyScore("Println", "prln"), isNotNull);
      expect(fuzzyScore("println", "PRLN"), isNotNull);
    });

    test("fuzzy subsequence matches across gaps", () {
      expect(fuzzyScore("println", "prln"), isNotNull);
      expect(fuzzyScore("console", "cnl"), isNotNull);
    });

    test("empty input matches everything (member popup after dot)", () {
      expect(fuzzyScore("log", ""), isNotNull);
    });

    test("shorter prefix wins ties", () {
      expect(
        fuzzyScore("print", "pr")!,
        greaterThan(fuzzyScore("printlnExtra", "pr")!),
      );
    });
  });

  group("fuzzyMatchIndices", () {
    test("prefix yields leading run", () {
      expect(fuzzyMatchIndices("print", "pr"), [0, 1]);
    });

    test("fuzzy yields ordered hits", () {
      expect(fuzzyMatchIndices("println", "prln"), [0, 1, 5, 6]);
    });

    test("no match yields empty", () {
      expect(fuzzyMatchIndices("print", "xyz"), isEmpty);
    });
  });

  group("rankPrompts", () {
    test("orders best first and caps the list", () {
      final prompts = rankPrompts(
        const [
          CodeKeywordPrompt(word: "sprinkle"),
          CodeKeywordPrompt(word: "println"),
          CodeKeywordPrompt(word: "print"),
        ],
        "pr",
      );
      expect(
        prompts.map((p) => p.word).toList(),
        ["print", "println", "sprinkle"],
      );
      final capped = rankPrompts(
        const [
          CodeKeywordPrompt(word: "sprinkle"),
          CodeKeywordPrompt(word: "println"),
          CodeKeywordPrompt(word: "print"),
        ],
        "pr",
        limit: 2,
      );
      expect(capped.map((p) => p.word).toList(), ["print", "println"]);
    });

    test("field prompts outrank bare keywords on ties", () {
      final prompts = rankPrompts(
        const [
          CodeKeywordPrompt(word: "alpha"),
          CodeFieldPrompt(word: "alpha2", type: "String"),
        ],
        "alph",
      );
      expect(prompts.first.word, "alpha2");
    });

    test("drops non-matches", () {
      final prompts = rankPrompts(
        const [
          CodeKeywordPrompt(word: "print"),
          CodeKeywordPrompt(word: "class"),
        ],
        "pr",
      );
      expect(prompts.map((p) => p.word), ["print"]);
    });

    test("member context prefers functions", () {
      final prompts = rankPrompts(
        const [
          CodeKeywordPrompt(word: "logx"),
          CodeFunctionPrompt(word: "logy", type: "void"),
        ],
        "log",
        memberContext: true,
      );
      expect(prompts.first.word, "logy");
    });
  });

  group("extractLanguageKeywords", () {
    test("dart yields keywords including class", () {
      final words = extractLanguageKeywords(langDart).map((p) => p.word);
      expect(words, contains("class"));
      expect(words, contains("return"));
    });

    test("null language yields empty", () {
      expect(extractLanguageKeywords(null), isEmpty);
    });
  });
}
