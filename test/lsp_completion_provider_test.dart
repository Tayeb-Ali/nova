import "package:flutter_test/flutter_test.dart";
import "package:re_editor/re_editor.dart";

import "package:nova/src/features/editor/autocomplete/language_members.dart";
import "package:nova/src/features/lsp/go_lsp_manager.dart";
import "package:nova/src/features/lsp/lsp_client.dart";
import "package:nova/src/features/lsp/lsp_completion_provider.dart";

void main() {
  group("lspItemToPrompt", () {
    test("function kinds become function prompts", () {
      final prompt = lspItemToPrompt(
        const LspCompletionItem(label: "Println", kind: 3, detail: "void"),
      );
      expect(prompt, isA<CodeFunctionPrompt>());
      expect(prompt.word, "Println");
    });

    test("field/class kinds become field prompts with detail", () {
      final prompt = lspItemToPrompt(
        const LspCompletionItem(label: "PI", kind: 5, detail: "number"),
      ) as CodeFieldPrompt;
      expect(prompt.type, "number");
    });

    test("snippet kind uses insertText as expansion", () {
      final prompt = lspItemToPrompt(
        const LspCompletionItem(
          label: "for",
          kind: 15,
          insertText: "for (\$1) {}",
        ),
      ) as CodeFieldPrompt;
      expect(prompt.autocomplete.word, "for (\$1) {}");
    });

    test("unknown kind falls back to keyword", () {
      final prompt = lspItemToPrompt(
        const LspCompletionItem(label: "whatever"),
      );
      expect(prompt, isA<CodeKeywordPrompt>());
    });
  });

  group("lspItemsToPrompts", () {
    test("drops empty labels and duplicates", () {
      final prompts = lspItemsToPrompts(const [
        LspCompletionItem(label: "a"),
        LspCompletionItem(label: ""),
        LspCompletionItem(label: "a"),
        LspCompletionItem(label: "b", kind: 3),
      ]);
      expect(prompts.map((p) => p.word).toList(), ["a", "b"]);
    });
  });

  group("completionFor", () {
    test("unregistered language yields empty without spawning", () async {
      final manager = GoLspManager(
        transportFactory: (_) => throw StateError("must not spawn"),
      );
      expect(
        await manager.completionFor("/tmp", "cobol", "/tmp/x.cob", 0, 0),
        isEmpty,
      );
      await manager.stopAll();
    });
  });

  group("definitionFor", () {
    test("unregistered language yields null without spawning", () async {
      final manager = GoLspManager(
        transportFactory: (_) => throw StateError("must not spawn"),
      );
      expect(
        await manager.definitionFor("/tmp", "cobol", "/tmp/x.cob", 0, 0),
        isNull,
      );
      await manager.stopAll();
    });
  });

  group("signatureHelpFor", () {
    test("unregistered language yields null without spawning", () async {
      final manager = GoLspManager(
        transportFactory: (_) => throw StateError("must not spawn"),
      );
      expect(
        await manager.signatureHelpFor("/tmp", "cobol", "/tmp/x.cob", 0, 0),
        isNull,
      );
      await manager.stopAll();
    });
  });

  group("membersFor (fuzzy source)", () {
    test("returns full table for fuzzy filtering", () {
      MemberRegistry.debugFill("javascript", const {
        "receivers": {
          "console": {
            "methods": {"log": "void", "error": "void"},
            "fields": {},
          },
        },
      });
      final all = MemberRegistry.membersFor("javascript", "console")!;
      expect(all.map((p) => p.word).toSet(), {"log", "error"});
      expect(MemberRegistry.membersFor("javascript", "nope"), isNull);
    });
  });
}
