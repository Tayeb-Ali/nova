import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

import 'package:nova/src/features/editor/autocomplete/completion_assists.dart';
import 'package:nova/src/features/editor/autocomplete/language_members.dart';
import 'package:nova/src/features/editor/autocomplete/nova_prompts_builder.dart';

/// Postfix templates (`expr.if` -> `if (expr) {}`) and the auto-import
/// side-table. Builder tests pump a context like `member_trigger_test.dart`;
/// pure table/expansion checks need no widgets.
void main() {
  setUpAll(() {
    MemberRegistry.debugFill('javascript', {
      'receivers': {
        'console': {
          'methods': {'log': 'void', 'error': 'void'},
          'fields': {},
        },
      },
    });
    MemberRegistry.debugFill('php', {
      'receivers': {
        'request': {
          'methods': {'input': 'mixed'},
          'fields': {},
        },
      },
    });
  });

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext c) {
            captured = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  CodeAutocompleteEditingValue? buildAt(
    BuildContext ctx,
    String languageId,
    String text, {
    int? offset,
  }) {
    final NovaPromptsBuilder builder =
        NovaPromptsBuilder(languageId: languageId);
    return builder.build(
      ctx,
      CodeLine(text),
      CodeLineSelection.collapsed(index: 0, offset: offset ?? text.length),
    );
  }

  Set<String> wordsOf(CodeAutocompleteEditingValue? result) =>
      result == null
          ? <String>{}
          : result.prompts.map((CodePrompt p) => p.word).toSet();

  CodePrompt promptFor(CodeAutocompleteEditingValue? result, String word) {
    expect(result, isNotNull);
    return result!.prompts.firstWhere(
      (CodePrompt p) => p.word == word,
      orElse: () => throw StateError('missing prompt $word'),
    );
  }

  group('postfix expansions (pure)', () {
    test('dart block templates park the caret inside braces', () {
      var template = postfixExpansion('dart', 'x', 'if')!;
      expect(template.expansion, 'if (x) {}');
      expect(template.caretOffset, 8);
      template = postfixExpansion('dart', 'items', 'for')!;
      expect(template.expansion, 'for (final x in items) {}');
      expect(template.caretOffset, 24);
      template = postfixExpansion('dart', 'x', 'while')!;
      expect(template.expansion, 'while (x) {}');
      expect(template.caretOffset, 11);
      template = postfixExpansion('dart', 'ok', 'else')!;
      expect(template.expansion, 'if (!ok) {}');
      expect(template.caretOffset, 10);
    });

    test('dart trailing templates park the caret at the end', () {
      var template = postfixExpansion('dart', 'x', 'log')!;
      expect(template.expansion, 'print(x)');
      expect(template.caretOffset, 8);
      template = postfixExpansion('dart', 'x', 'not')!;
      expect(template.expansion, '!x');
      expect(template.caretOffset, 2);
      template = postfixExpansion('dart', 'x', 'null')!;
      expect(template.expansion, 'x ?? ');
      expect(template.caretOffset, 5);
    });

    test('log is print/console.log/var_dump/println per language', () {
      expect(postfixExpansion('python', 'x', 'log')!.expansion, 'print(x)');
      expect(
        postfixExpansion('javascript', 'user', 'log')!.expansion,
        'console.log(user)',
      );
      expect(
        postfixExpansion('javascript', 'user', 'log')!.caretOffset,
        17,
      );
      expect(
        postfixExpansion('typescript', 'user', 'log')!.expansion,
        'console.log(user)',
      );
      expect(postfixExpansion('php', 'x', 'log')!.expansion, 'var_dump(x);');
      expect(postfixExpansion('php', 'x', 'log')!.caretOffset, 12);
      expect(
        postfixExpansion('java', 'x', 'log')!.expansion,
        'System.out.println(x);',
      );
      expect(postfixExpansion('java', 'x', 'log')!.caretOffset, 22);
    });

    test('not is !expr except python', () {
      expect(postfixExpansion('dart', 'x', 'not')!.expansion, '!x');
      expect(postfixExpansion('java', 'x', 'not')!.expansion, '!x');
      final template = postfixExpansion('python', 'x', 'not')!;
      expect(template.expansion, 'not x');
      expect(template.caretOffset, 5);
    });

    test('python control templates use colons', () {
      var template = postfixExpansion('python', 'x', 'if')!;
      expect(template.expansion, 'if x:');
      expect(template.caretOffset, 5);
      template = postfixExpansion('python', 'items', 'for')!;
      expect(template.expansion, 'for x in items:');
      expect(template.caretOffset, 15);
      template = postfixExpansion('python', 'x', 'while')!;
      expect(template.expansion, 'while x:');
      expect(template.caretOffset, 8);
      template = postfixExpansion('python', 'x', 'else')!;
      expect(template.expansion, 'if not x:');
      expect(template.caretOffset, 9);
    });

    test('php foreach and java enhanced-for wrap the receiver', () {
      final php = postfixExpansion('php', 'items', 'for')!;
      expect(php.expansion, 'foreach (items as \$x) {}');
      expect(php.caretOffset, 23);
      final java = postfixExpansion('java', 'rows', 'for')!;
      expect(java.expansion, 'for (var x : rows) {}');
      expect(java.caretOffset, 20);
    });

    test('null is ?? only where the syntax exists', () {
      expect(postfixExpansion('dart', 'v', 'null')!.expansion, 'v ?? ');
      expect(postfixExpansion('typescript', 'v', 'null')!.expansion, 'v ?? ');
      expect(postfixExpansion('php', 'v', 'null')!.expansion, 'v ?? ');
      expect(postfixExpansion('python', 'x', 'null'), isNull);
      expect(postfixExpansion('java', 'x', 'null'), isNull);
    });

    test('unknown keyword or language yields nothing', () {
      expect(postfixExpansion('dart', 'x', 'bogus'), isNull);
      expect(postfixExpansion('json', 'x', 'if'), isNull);
      expect(postfixExpansion('cobol', 'x', 'if'), isNull);
      expect(postfixExpansion(null, 'x', 'if'), isNull);
    });
  });

  group('postfix through the builder', () {
    testWidgets('x.if offers the full typed word with its expansion',
        (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      final CodeAutocompleteEditingValue? result =
          buildAt(ctx, 'dart', 'x.if');
      expect(result, isNotNull);
      expect(result!.input, 'x.if');
      final CodePrompt prompt = promptFor(result, 'x.if');
      expect(prompt.autocomplete.word, 'if (x) {}');
      expect(prompt.autocomplete.selection.extentOffset, 8);
      // Accepting replaces the whole `receiver.keyword` span.
      final CodeAutocompleteResult applied = result.autocomplete;
      expect(applied.input, 'x.if');
      expect(applied.word, 'if (x) {}');
      expect(applied.selection.extentOffset, 8 - 'x.if'.length);
    });

    testWidgets('dotted chains keep the whole chain', (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      final CodeAutocompleteEditingValue? result =
          buildAt(ctx, 'dart', 'a.b.if');
      expect(result, isNotNull);
      expect(result!.input, 'a.b.if');
      final CodePrompt prompt = promptFor(result, 'a.b.if');
      expect(prompt.autocomplete.word, 'if (a.b) {}');
      expect(prompt.autocomplete.selection.extentOffset, 10);
    });

    testWidgets('real member receivers suppress postfix', (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      // `log` is both a member of console and a postfix keyword: the
      // member path is tried first (input `log`, not the postfix input
      // `console.log`), and the table check suppresses the template even
      // though no member fuzzy-matches the fully-typed `log`. (The
      // pre-existing `console.log` snippet may still appear via the
      // keyword flow; what must never appear is its postfix expansion.)
      final CodeAutocompleteEditingValue? logged =
          buildAt(ctx, 'javascript', 'console.log');
      expect(logged, isNotNull);
      expect(logged!.input, 'log');
      expect(
        logged.prompts
            .whereType<CodeFieldPrompt>()
            .map((CodeFieldPrompt p) => p.autocomplete.word),
        isNot(contains('console.log(console)')),
      );
      // `console` owns a table but `if` matches no member: still no
      // postfix (falls through to the keyword flow instead).
      final CodeAutocompleteEditingValue? iff =
          buildAt(ctx, 'javascript', 'console.if');
      expect(wordsOf(iff), isNot(contains('console.if')));
    });

    testWidgets('php dollar receivers try the stripped table',
        (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      final CodeAutocompleteEditingValue? result =
          buildAt(ctx, 'php', r'$request.if');
      expect(wordsOf(result), isNot(contains(r'$request.if')));
    });

    testWidgets('unknown postfix never hijacks member completion',
        (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      final CodeAutocompleteEditingValue? result =
          buildAt(ctx, 'dart', 'foo.bar');
      expect(wordsOf(result), isNot(contains('foo.bar')));
    });

    testWidgets('no postfix inside string literals', (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      final CodeAutocompleteEditingValue? result =
          buildAt(ctx, 'dart', '"x.if"', offset: 5);
      expect(result, isNull);
    });

    testWidgets('unsupported combos fall through without a template word',
        (tester) async {
      final BuildContext ctx = await pumpContext(tester);
      expect(
        wordsOf(buildAt(ctx, 'python', 'x.null')),
        isNot(contains('x.null')),
      );
      expect(
        wordsOf(buildAt(ctx, 'java', 'x.null')),
        isNot(contains('x.null')),
      );
    });
  });

  group('auto-import tables', () {
    test('dart/js/ts/python entries map words to import lines', () {
      expect(
        importEditsFor('dart')['Widget'],
        "import 'package:flutter/widgets.dart';",
      );
      expect(
        importEditsFor('dart')['jsonDecode'],
        "import 'dart:convert';",
      );
      expect(
        importEditsFor('javascript')['useState'],
        "import { useState } from 'react';",
      );
      expect(
        importEditsFor('typescript')['useState'],
        "import { useState } from 'react';",
      );
      expect(
        importEditsFor('python')['Path'],
        'from pathlib import Path',
      );
      expect(importLineFor('python', 'nope'), isNull);
    });

    test('aliases resolve, unknown languages are empty', () {
      expect(importEditsFor('py')['Path'], 'from pathlib import Path');
      expect(
        importEditsFor('js')['useState'],
        "import { useState } from 'react';",
      );
      expect(importEditsFor('cobol'), isEmpty);
      expect(importEditsFor(null), isEmpty);
      // Only the four bounded languages ship tables.
      expect(importEditsFor('java'), isEmpty);
      expect(importEditsFor('php'), isEmpty);
    });

    test('tables stay bounded (~10-15 entries)', () {
      for (final lang in ['dart', 'javascript', 'typescript', 'python']) {
        final int count = importEditsFor(lang).length;
        expect(count, inInclusiveRange(10, 17), reason: lang);
      }
    });
  });

  group('applyAutoImport', () {
    test('inserts the import at the top', () {
      expect(
        applyAutoImport(
          text: 'void main() {}',
          languageId: 'dart',
          acceptedWord: 'Widget',
        ),
        "import 'package:flutter/widgets.dart';\nvoid main() {}",
      );
    });

    test('applied once: skipped when the line is present', () {
      const String text =
          "import 'package:flutter/widgets.dart';\nWidget build() {}";
      expect(
        applyAutoImport(
          text: text,
          languageId: 'dart',
          acceptedWord: 'Widget',
        ),
        same(text),
      );
    });

    test('unknown words leave the text untouched', () {
      const String text = 'void main() {}';
      expect(
        applyAutoImport(
          text: text,
          languageId: 'dart',
          acceptedWord: 'myLocal',
        ),
        same(text),
      );
    });

    test('shebang stays first, import goes to line 1', () {
      expect(
        applyAutoImport(
          text: '#!/usr/bin/env python3\nprint(1)',
          languageId: 'python',
          acceptedWord: 'Path',
        ),
        '#!/usr/bin/env python3\nfrom pathlib import Path\nprint(1)',
      );
      expect(autoImportInsertLine('#!/bin/sh\nx'), 1);
      expect(autoImportInsertLine('plain'), 0);
    });

    test('shebang-only file appends the import', () {
      expect(
        applyAutoImport(
          text: '#!/bin/sh',
          languageId: 'python',
          acceptedWord: 'os',
        ),
        '#!/bin/sh\nimport os',
      );
    });
  });
}
