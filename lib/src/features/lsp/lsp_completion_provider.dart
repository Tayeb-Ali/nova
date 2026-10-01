import "package:flutter/widgets.dart";
import "package:re_editor/re_editor.dart";

import "lsp_client.dart";

/// Maps live `textDocument/completion` results onto `re_editor` prompts so
/// the synchronous [NovaPromptsBuilder] can merge server intelligence with
/// its instant local candidates (keywords, snippets, document words).
///
/// The fetch is best-effort: timeouts, missing servers, and malformed items
/// all yield an empty list, and the editor keeps working on local results
/// alone — the same contract as `GoLspManager.didOpenGoFile`.

/// Converts one LSP item into the closest `re_editor` prompt kind.
///
/// `insertText` (or `textEdit.newText`) becomes the applied expansion for
/// snippets; functions keep their label as the matchable word with the
/// server `detail` shown in the popup.
CodePrompt lspItemToPrompt(LspCompletionItem item) {
  final String word = item.label;
  final String detail = (item.detail ?? "").trim();
  switch (item.kind) {
    case 2: // Method
    case 3: // Function
    case 4: // Constructor
      return CodeFunctionPrompt(
        word: word,
        type: detail.isEmpty ? "lsp" : detail,
      );
    case 6: // Variable
    case 5: // Field
    case 7: // Class
    case 8: // Interface
    case 9: // Module
    case 10: // Property
    case 11: // Unit
    case 13: // Enum
    case 14: // Keyword
    case 17: // File
    case 22: // Struct
      return CodeFieldPrompt(
        word: word,
        type: detail.isEmpty ? "lsp" : detail,
      );
    case 15: // Snippet
      final String expansion = (item.insertText ?? "").isNotEmpty
          ? item.insertText!
          : word;
      return CodeFieldPrompt(
        word: word,
        type: detail.isEmpty ? "snippet" : detail,
        customAutocomplete: CodeAutocompleteResult(
          input: "",
          word: expansion,
          selection: TextSelection.collapsed(offset: expansion.length),
        ),
      );
    default:
      return CodeKeywordPrompt(word: word);
  }
}

/// Converts a whole completion response, dropping empty labels.
List<CodePrompt> lspItemsToPrompts(List<LspCompletionItem> items) {
  final List<CodePrompt> out = [];
  final Set<String> seen = {};
  for (final item in items) {
    if (item.label.isEmpty || !seen.add(item.label)) continue;
    out.add(lspItemToPrompt(item));
  }
  return out;
}

/// Best-effort completion fetch: returns server prompts or an empty list.
/// Never throws — callers park the result in
/// `NovaPromptsBuilder.externalPrompts` on success.
Future<List<CodePrompt>> fetchLspPrompts(
  LspClient client,
  String path,
  int line,
  int character,
) async {
  try {
    final List<LspCompletionItem> items = await client.completion(
      path,
      line,
      character,
    );
    return lspItemsToPrompts(items);
  } catch (_) {
    return const [];
  }
}
