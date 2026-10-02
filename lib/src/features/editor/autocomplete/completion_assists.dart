import "package:flutter/widgets.dart";
import "package:re_editor/re_editor.dart";

import "language_snippets.dart";

/// Side-tables for the two JetBrains-parity completion assists.
///
/// Neither feature subclasses prompts: postfix templates are plain
/// snippet-style [CodeFieldPrompt]s built by [NovaPromptsBuilder] (same
/// `word`-alias + `customAutocomplete` mechanism as the existing
/// `arrow`/`puf` aliases), and auto-import is a word -> import-line map
/// applied after acceptance in the editor wiring.
///
/// All tables are `const` and bounded; doc comments stay in English.

/// Postfix keywords offered after `receiver.` (for example `expr.if`).
///
/// The set is intentionally small and predictable: real member completion
/// always wins (the builder only offers these when the receiver has no
/// member table), and anything after the last dot that is not exactly one
/// of these falls through to the normal flow.
const Set<String> postfixKeywords = <String>{
  "if",
  "else",
  "for",
  "while",
  "log",
  "not",
  "null",
};

/// Builds the single-line postfix expansion for [receiver] + [keyword] in
/// the language [languageId], or null when the combination has no
/// meaningful syntax (for example `null` in Python/Java, which have no
/// `??` operator).
///
/// The returned caret offset is an index into [expansion] ([TextSelection]
/// collapsed there), computed arithmetically from the expansion length so
/// it cannot drift: block templates park the caret inside the braces
/// (`length - 1`), trailing templates park it at the end (`length`).
({String expansion, int caretOffset})? postfixExpansion(
  String? languageId,
  String receiver,
  String keyword,
) {
  final String? lang = normalizeLanguageId(languageId);
  switch (keyword) {
    case "if":
      switch (lang) {
        case "python":
          final String expansion = "if $receiver:";
          return (expansion: expansion, caretOffset: expansion.length);
        case "dart":
        case "javascript":
        case "typescript":
        case "php":
        case "java":
          final String expansion = "if ($receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        default:
          return null;
      }
    case "else":
      switch (lang) {
        case "python":
          final String expansion = "if not $receiver:";
          return (expansion: expansion, caretOffset: expansion.length);
        case "dart":
        case "javascript":
        case "typescript":
        case "php":
        case "java":
          final String expansion = "if (!$receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        default:
          return null;
      }
    case "for":
      switch (lang) {
        case "python":
          final String expansion = "for x in $receiver:";
          return (expansion: expansion, caretOffset: expansion.length);
        case "dart":
          final String expansion = "for (final x in $receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        case "javascript":
        case "typescript":
          final String expansion = "for (const x of $receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        case "php":
          final String expansion = "foreach ($receiver as \$x) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        case "java":
          final String expansion = "for (var x : $receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        default:
          return null;
      }
    case "while":
      switch (lang) {
        case "python":
          final String expansion = "while $receiver:";
          return (expansion: expansion, caretOffset: expansion.length);
        case "dart":
        case "javascript":
        case "typescript":
        case "php":
        case "java":
          final String expansion = "while ($receiver) {}";
          return (expansion: expansion, caretOffset: expansion.length - 1);
        default:
          return null;
      }
    case "log":
      switch (lang) {
        case "dart":
        case "python":
          final String expansion = "print($receiver)";
          return (expansion: expansion, caretOffset: expansion.length);
        case "javascript":
        case "typescript":
          final String expansion = "console.log($receiver)";
          return (expansion: expansion, caretOffset: expansion.length);
        case "php":
          final String expansion = "var_dump($receiver);";
          return (expansion: expansion, caretOffset: expansion.length);
        case "java":
          final String expansion = "System.out.println($receiver);";
          return (expansion: expansion, caretOffset: expansion.length);
        default:
          return null;
      }
    case "not":
      switch (lang) {
        case "python":
          final String expansion = "not $receiver";
          return (expansion: expansion, caretOffset: expansion.length);
        case "dart":
        case "javascript":
        case "typescript":
        case "php":
        case "java":
          final String expansion = "!$receiver";
          return (expansion: expansion, caretOffset: expansion.length);
        default:
          return null;
      }
    case "null":
      switch (lang) {
        case "dart":
        case "javascript":
        case "typescript":
        case "php":
          final String expansion = "$receiver ?? ";
          return (expansion: expansion, caretOffset: expansion.length);
        default:
          // Python and Java have no `??` operator: no template offered.
          return null;
      }
    default:
      return null;
  }
}

/// High-value external symbols mapped to their import line, per language.
///
/// Bounded on purpose (~10-15 entries for Dart/JS/TS/Python only): this is
/// a JetBrains-parity convenience for the most-typed names, not a symbol
/// index. Keys are completed words (prompt `word`s); values are full import
/// lines without the trailing newline.
const Map<String, Map<String, String>> _autoImportLines = {
  "dart": {
    "Widget": "import 'package:flutter/widgets.dart';",
    "StatelessWidget": "import 'package:flutter/widgets.dart';",
    "StatefulWidget": "import 'package:flutter/widgets.dart';",
    "State": "import 'package:flutter/widgets.dart';",
    "BuildContext": "import 'package:flutter/widgets.dart';",
    "Text": "import 'package:flutter/widgets.dart';",
    "Column": "import 'package:flutter/widgets.dart';",
    "Row": "import 'package:flutter/widgets.dart';",
    "Container": "import 'package:flutter/widgets.dart';",
    "MaterialApp": "import 'package:flutter/material.dart';",
    "Scaffold": "import 'package:flutter/material.dart';",
    "jsonDecode": "import 'dart:convert';",
    "jsonEncode": "import 'dart:convert';",
    "Future": "import 'dart:async';",
    "File": "import 'dart:io';",
  },
  "javascript": {
    "useState": "import { useState } from 'react';",
    "useEffect": "import { useEffect } from 'react';",
    "useRef": "import { useRef } from 'react';",
    "useMemo": "import { useMemo } from 'react';",
    "useCallback": "import { useCallback } from 'react';",
    "useContext": "import { useContext } from 'react';",
    "Component": "import { Component } from 'react';",
    "Fragment": "import { Fragment } from 'react';",
    "React": "import React from 'react';",
    "axios": "import axios from 'axios';",
    "fs": "import fs from 'fs';",
    "path": "import path from 'path';",
  },
  "typescript": {
    "useState": "import { useState } from 'react';",
    "useEffect": "import { useEffect } from 'react';",
    "useRef": "import { useRef } from 'react';",
    "useMemo": "import { useMemo } from 'react';",
    "useCallback": "import { useCallback } from 'react';",
    "useContext": "import { useContext } from 'react';",
    "Component": "import { Component } from 'react';",
    "Fragment": "import { Fragment } from 'react';",
    "React": "import React from 'react';",
    "axios": "import axios from 'axios';",
    "fs": "import fs from 'fs';",
    "path": "import path from 'path';",
  },
  "python": {
    "Path": "from pathlib import Path",
    "dataclass": "from dataclasses import dataclass",
    "field": "from dataclasses import field",
    "json": "import json",
    "os": "import os",
    "sys": "import sys",
    "re": "import re",
    "datetime": "from datetime import datetime",
    "timedelta": "from datetime import timedelta",
    "Optional": "from typing import Optional",
    "List": "from typing import List",
    "Dict": "from typing import Dict",
    "asyncio": "import asyncio",
    "defaultdict": "from collections import defaultdict",
    "Counter": "from collections import Counter",
  },
};

/// Returns the word -> import-line map for [languageId] (canonicalized;
/// `"py"`/`"js"`/`"ts"` aliases resolve). Empty when the language has no
/// auto-import table. The returned map is read-only.
Map<String, String> importEditsFor(String? languageId) {
  final String? normalized = normalizeLanguageId(languageId);
  if (normalized == null) {
    return const {};
  }
  return _autoImportLines[normalized] ?? const {};
}

/// Returns the import line for a single completed [word], or null when the
/// word needs no import in [languageId].
String? importLineFor(String? languageId, String word) {
  return importEditsFor(languageId)[word];
}

/// Line index where an auto-import is inserted: 1 when the file starts
/// with a shebang (`#!...`) so the interpreter line stays first, else 0.
int autoImportInsertLine(String text) {
  return text.startsWith("#!") ? 1 : 0;
}

/// Applies the auto-import for [acceptedWord] to [text] and returns the
/// updated text, or [text] unchanged when the word needs no import or the
/// import line is already present.
///
/// Pure (no editor dependency) so the accept path and tests share it.
String applyAutoImport({
  required String text,
  required String? languageId,
  required String acceptedWord,
}) {
  final String? line = importLineFor(languageId, acceptedWord);
  if (line == null || line.isEmpty) {
    return text;
  }
  if (text.contains(line)) {
    return text;
  }
  if (text.startsWith("#!")) {
    final int newline = text.indexOf("\n");
    if (newline < 0) {
      return "$text\n$line";
    }
    return "${text.substring(0, newline + 1)}$line\n${text.substring(newline + 1)}";
  }
  return "$line\n$text";
}
