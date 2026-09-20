import "package:flutter/widgets.dart";
import "package:re_editor/re_editor.dart";

/// Detail label used for snippet-style prompts.
///
/// [CodePrompt] has no dedicated snippet subclass, so multi-word statement
/// templates are expressed as [CodeFieldPrompt] (matchable prefix in [word],
/// full expansion in [customAutocomplete]) or [CodeKeywordPrompt] (when the
/// expansion is identical to the matchable word). The popup in
/// `autocomplete_popup.dart` shows a snippet icon for any [CodeFieldPrompt]
/// whose [CodeFieldPrompt.type] equals this value.
const String snippetPromptType = "snippet";

/// Single-line snippet prompts keyed by editor language id.
///
/// Every entry is chosen so it is reachable through re_editor's prefix
/// matching ([CodePrompt.match] requires `word.startsWith(input)`):
/// either the snippet text itself starts with a word character, or [word]
/// holds a short matchable alias while `customAutocomplete` carries the full
/// expansion. All completions flow through the standard `autocomplete` getter
/// mechanism ([CodeAutocompleteResult.fromWord] or an explicit
/// [CodeAutocompleteResult] with a cursor offset), so
/// [CodeAutocompleteEditingValue.autocomplete] can apply them by replacing
/// the typed `input` with the completion `word`.
const Map<String, List<CodePrompt>> languageSnippets = {
  "python": [
    CodeKeywordPrompt(word: "if __name__ == \"__main__\":"),
    CodeKeywordPrompt(word: "def main():"),
    CodeFieldPrompt(
      word: "for i in range():",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "for i in range():",
        selection: TextSelection.collapsed(offset: 14),
      ),
    ),
    CodeFieldPrompt(
      word: "with open() as f:",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "with open() as f:",
        selection: TextSelection.collapsed(offset: 9),
      ),
    ),
    CodeFunctionPrompt(
      word: "print",
      type: "None",
      parameters: {"value": "object"},
    ),
    CodeFunctionPrompt(
      word: "len",
      type: "int",
      parameters: {"obj": "object"},
    ),
    CodeKeywordPrompt(word: "import "),
    CodeKeywordPrompt(word: "return "),
  ],
  "javascript": [
    CodeFunctionPrompt(
      word: "console.log",
      type: "void",
      parameters: {"value": "any"},
    ),
    CodeFunctionPrompt(
      word: "JSON.stringify",
      type: "string",
      parameters: {"value": "any"},
    ),
    CodeFunctionPrompt(
      word: "document.querySelector",
      type: "Element",
      parameters: {"selector": "string"},
    ),
    // "(" is not a valid identifier part, so this snippet is matched
    // through the "arrow" alias and expands to the full expression.
    CodeFieldPrompt(
      word: "arrow",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "() => {}",
        selection: TextSelection.collapsed(offset: 7),
      ),
    ),
    CodeKeywordPrompt(word: "import  from \"\";"),
    CodeKeywordPrompt(word: "export default "),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "for (let i = 0; i < n; i++) {}"),
  ],
  "php": [
    CodeKeywordPrompt(word: "<?php"),
    CodeKeywordPrompt(word: "echo \"\";"),
    CodeKeywordPrompt(word: "require_once \"\";"),
    CodeKeywordPrompt(word: "function () {}"),
    CodeFunctionPrompt(
      word: "isset",
      type: "bool",
      parameters: {"var": "mixed"},
    ),
    CodeFunctionPrompt(
      word: "empty",
      type: "bool",
      parameters: {"var": "mixed"},
    ),
    CodeFunctionPrompt(
      word: "var_dump",
      type: "void",
      parameters: {"value": "mixed"},
    ),
    CodeFunctionPrompt(
      word: "count",
      type: "int",
      parameters: {"array": "array"},
    ),
  ],
  "dart": [
    CodeKeywordPrompt(word: "void main() {}"),
    CodeFunctionPrompt(
      word: "print",
      type: "void",
      parameters: {"object": "Object?"},
    ),
    CodeFunctionPrompt(
      word: "setState",
      type: "void",
      parameters: {"fn": "VoidCallback"},
    ),
    CodeKeywordPrompt(word: "import \"\";"),
    CodeKeywordPrompt(word: "class  {}"),
    CodeKeywordPrompt(word: "final  = ;"),
    CodeKeywordPrompt(word: "for (final x in ) {}"),
    CodeKeywordPrompt(word: "if (mounted) return;"),
  ],
  // JSON keys always start with a quote character, which can never be part
  // of the typed `input`, so each template below uses a short matchable
  // alias in [word] and expands to a full `"key": value` pair.
  "json": [
    CodeFieldPrompt(
      word: "name",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"name\": \"\"",
        selection: TextSelection.collapsed(offset: 9),
      ),
    ),
    CodeFieldPrompt(
      word: "id",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"id\": 0",
        selection: TextSelection.collapsed(offset: 8),
      ),
    ),
    CodeFieldPrompt(
      word: "enabled",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"enabled\": true",
        selection: TextSelection.collapsed(offset: 15),
      ),
    ),
    CodeFieldPrompt(
      word: "items",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"items\": []",
        selection: TextSelection.collapsed(offset: 10),
      ),
    ),
    CodeFieldPrompt(
      word: "config",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"config\": {}",
        selection: TextSelection.collapsed(offset: 11),
      ),
    ),
    CodeFieldPrompt(
      word: "value",
      type: snippetPromptType,
      customAutocomplete: CodeAutocompleteResult(
        input: "",
        word: "\"value\": \"\"",
        selection: TextSelection.collapsed(offset: 10),
      ),
    ),
  ],
};

/// Short file-extension style aliases mapped to canonical language ids.
const Map<String, String> _languageIdAliases = {
  "py": "python",
  "js": "javascript",
  "ts": "javascript",
};

/// Normalizes a user supplied language id ("Dart", " py ", ...) to the
/// canonical lowercase id used by [languageSnippets].
String? normalizeLanguageId(String? languageId) {
  if (languageId == null) {
    return null;
  }
  final String normalized = languageId.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  return _languageIdAliases[normalized] ?? normalized;
}

/// Returns the snippet prompts for [languageId], or an empty list when the
/// language is unknown. Never returns null so callers can always spread it.
List<CodePrompt> snippetsForLanguage(String? languageId) {
  final String? normalized = normalizeLanguageId(languageId);
  if (normalized == null) {
    return const [];
  }
  return languageSnippets[normalized] ?? const [];
}
