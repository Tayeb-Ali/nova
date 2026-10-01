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
    CodeKeywordPrompt(word: "Future<void>  async {}"),
    CodeKeywordPrompt(word: "await "),
    CodeKeywordPrompt(word: "Navigator.push();"),
    CodeKeywordPrompt(word: "Text(\"\")"),
    CodeKeywordPrompt(word: "@override"),
  ],
  "typescript": [
    CodeFunctionPrompt(
      word: "console.log",
      type: "void",
      parameters: {"value": "any"},
    ),
    CodeKeywordPrompt(word: "interface  {}"),
    CodeKeywordPrompt(word: "type  = ;"),
    CodeKeywordPrompt(word: "const  = ;"),
    CodeKeywordPrompt(word: "async function () {}"),
    CodeKeywordPrompt(word: "await "),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "for (const x of ) {}"),
    CodeKeywordPrompt(word: "import  from \"\";"),
    CodeKeywordPrompt(word: "export default "),
  ],
  "java": [
    CodeKeywordPrompt(word: "public class  {}"),
    CodeKeywordPrompt(word: "public static void main(String[] args) {}"),
    CodeKeywordPrompt(word: "System.out.println();"),
    CodeKeywordPrompt(word: "for (int i = 0; i < n; i++) {}"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "private  ;"),
    CodeKeywordPrompt(word: "import java.util.*;"),
    CodeKeywordPrompt(word: "new ArrayList<>();"),
    CodeKeywordPrompt(word: "@Override"),
  ],
  "kotlin": [
    CodeKeywordPrompt(word: "fun main() {}"),
    CodeFunctionPrompt(word: "println", type: "Unit", parameters: {"message": "Any?"}),
    CodeKeywordPrompt(word: "val  = "),
    CodeKeywordPrompt(word: "var  = "),
    CodeKeywordPrompt(word: "data class  ()"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "for (x in ) {}"),
    CodeKeywordPrompt(word: "when () {}"),
    CodeKeywordPrompt(word: "import "),
    CodeKeywordPrompt(word: "companion object {}"),
  ],
  "go": [
    CodeKeywordPrompt(word: "package main"),
    CodeKeywordPrompt(word: "func main() {}"),
    CodeKeywordPrompt(word: "fmt.Println();"),
    CodeKeywordPrompt(word: "if err != nil {}"),
    CodeKeywordPrompt(word: "for i := 0; i < n; i++ {}"),
    CodeKeywordPrompt(word: "for _, v := range  {}"),
    CodeKeywordPrompt(word: "import ()"),
    CodeKeywordPrompt(word: "go func() {}()"),
    CodeKeywordPrompt(word: "type  struct {}"),
  ],
  "rust": [
    CodeKeywordPrompt(word: "fn main() {}"),
    CodeKeywordPrompt(word: "println!(\"{}\", );"),
    CodeKeywordPrompt(word: "let mut  = ;"),
    CodeKeywordPrompt(word: "if let Some(x) =  {}"),
    CodeKeywordPrompt(word: "match  {}"),
    CodeKeywordPrompt(word: "for x in  {}"),
    CodeKeywordPrompt(word: "struct  {}"),
    CodeKeywordPrompt(word: "impl  {}"),
    CodeKeywordPrompt(word: "use ;"),
  ],
  "c": [
    CodeKeywordPrompt(word: "#include <stdio.h>"),
    CodeKeywordPrompt(word: "int main(void) {}"),
    CodeKeywordPrompt(word: "printf(\"%d\\n\", );"),
    CodeKeywordPrompt(word: "for (int i = 0; i < n; i++) {}"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "malloc(sizeof());"),
    CodeKeywordPrompt(word: "typedef struct {} ;"),
    CodeKeywordPrompt(word: "return 0;"),
  ],
  "cpp": [
    CodeKeywordPrompt(word: "#include <iostream>"),
    CodeKeywordPrompt(word: "int main() {}"),
    CodeKeywordPrompt(word: "std::cout <<  << std::endl;"),
    CodeKeywordPrompt(word: "for (int i = 0; i < n; i++) {}"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "class  {};"),
    CodeKeywordPrompt(word: "std::vector<>();"),
    CodeKeywordPrompt(word: "auto  = ;"),
  ],
  "csharp": [
    CodeKeywordPrompt(word: "using System;"),
    CodeKeywordPrompt(word: "public class  {}"),
    CodeKeywordPrompt(word: "Console.WriteLine();"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "foreach (var x in ) {}"),
    CodeKeywordPrompt(word: "public void  () {}"),
    CodeKeywordPrompt(word: "var  = ;"),
    CodeKeywordPrompt(word: "await "),
  ],
  "swift": [
    CodeKeywordPrompt(word: "import SwiftUI"),
    CodeKeywordPrompt(word: "func  () {}"),
    CodeKeywordPrompt(word: "let  = "),
    CodeKeywordPrompt(word: "var  = "),
    CodeKeywordPrompt(word: "if let x =  {}"),
    CodeKeywordPrompt(word: "guard let x =  else { return }"),
    CodeKeywordPrompt(word: "for x in  {}"),
    CodeKeywordPrompt(word: "struct  {}"),
    CodeFunctionPrompt(word: "print", type: "Void", parameters: {"items": "Any"}),
  ],
  "ruby": [
    CodeKeywordPrompt(word: "def  end"),
    CodeKeywordPrompt(word: "puts \"\""),
    CodeKeywordPrompt(word: "if  end"),
    CodeKeywordPrompt(word: ".each do |x| end"),
    CodeKeywordPrompt(word: "class  end"),
    CodeKeywordPrompt(word: "require \"\""),
    CodeKeywordPrompt(word: "attr_reader :"),
  ],
  "sql": [
    CodeKeywordPrompt(word: "SELECT  FROM  WHERE ;"),
    CodeKeywordPrompt(word: "INSERT INTO  () VALUES ();"),
    CodeKeywordPrompt(word: "UPDATE  SET  WHERE ;"),
    CodeKeywordPrompt(word: "DELETE FROM  WHERE ;"),
    CodeKeywordPrompt(word: "CREATE TABLE  ();"),
    CodeKeywordPrompt(word: "JOIN  ON "),
    CodeKeywordPrompt(word: "ORDER BY "),
    CodeKeywordPrompt(word: "GROUP BY "),
  ],
  "css": [
    CodeKeywordPrompt(word: "display: flex;"),
    CodeKeywordPrompt(word: "margin: 0 auto;"),
    CodeKeywordPrompt(word: "@media () {}"),
    CodeKeywordPrompt(word: "color: #;"),
    CodeKeywordPrompt(word: "font-size: 16px;"),
  ],
  "scss": [
    CodeKeywordPrompt(word: "@mixin  {}"),
    CodeKeywordPrompt(word: "@include ;"),
    CodeKeywordPrompt(word: "@media () {}"),
    CodeKeywordPrompt(word: "display: flex;"),
    CodeKeywordPrompt(word: "\$: ;"),
  ],
  "xml": [
    CodeKeywordPrompt(word: "<?xml version=\"1.0\"?>"),
    CodeKeywordPrompt(word: "<!--  -->"),
  ],
  "yaml": [
    CodeKeywordPrompt(word: "key: value"),
    CodeKeywordPrompt(word: "- item"),
  ],
  "shell": [
    CodeKeywordPrompt(word: "if [  ]; then"),
    CodeKeywordPrompt(word: "for f in *; do"),
    CodeKeywordPrompt(word: "echo \"\""),
    CodeKeywordPrompt(word: "#!/bin/bash"),
    CodeKeywordPrompt(word: "function () {}"),
  ],
  "php": [
    CodeKeywordPrompt(word: "<?php"),
    CodeKeywordPrompt(word: "echo \"\";"),
    CodeKeywordPrompt(word: "require_once \"\";"),
    CodeKeywordPrompt(word: "function () {}"),
    CodeKeywordPrompt(word: "if () {}"),
    CodeKeywordPrompt(word: "foreach (\$x as \$y) {}"),
    CodeKeywordPrompt(word: "class  {}"),
    CodeKeywordPrompt(word: "public function  () {}"),
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
    CodeKeywordPrompt(word: "async def ():"),
    CodeKeywordPrompt(word: "await "),
    CodeKeywordPrompt(word: "class  :"),
    CodeKeywordPrompt(word: "try: except :"),
    CodeKeywordPrompt(word: "list comprehension []"),
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
  "jsx": "javascript",
  "ts": "typescript",
  "tsx": "typescript",
  "mts": "typescript",
  "kt": "kotlin",
  "kts": "kotlin",
  "rs": "rust",
  "cs": "csharp",
  "rb": "ruby",
  "sh": "shell",
  "bash": "shell",
  "yml": "yaml",
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
