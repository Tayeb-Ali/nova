import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

import 'package:nova/src/features/editor/autocomplete/language_members.dart';
import 'package:nova/src/features/editor/autocomplete/nova_prompts_builder.dart';

/// Member-trigger coverage for `->` (PHP) and `::` (PHP/C++/Rust) alongside
/// the legacy `.` path. The registry is seeded directly so tests never touch
/// `assets/autocomplete/`.
void main() {
  setUpAll(() {
    MemberRegistry.debugFill('php', {
      'receivers': {
        'request': {
          'methods': {'input': 'mixed', 'all': 'array', 'validate': 'array'},
          'fields': {},
        },
        'this': {
          'methods': {'validate': 'array', 'view': 'View'},
          'fields': {'value': 'string'},
        },
        'DB': {
          'methods': {'table': 'Builder', 'select': 'mixed'},
          'fields': {},
        },
        'foo': {
          'methods': {'bar': 'void', 'baz': 'void'},
          'fields': {},
        },
        'a': {
          'methods': {'spacedDotBogusMember': 'void'},
          'fields': {},
        },
        'b': {
          'methods': {'ternaryBogusMember': 'void', 'cat': 'void'},
          'fields': {},
        },
        'String': {
          'methods': {'genericsBogusMember': 'void'},
          'fields': {},
        },
      },
    });
    MemberRegistry.debugFill('javascript', {
      'receivers': {
        'console': {
          // `logo` exists so `lgo` is a genuine fuzzy (subsequence, not
          // prefix) hit; `lgo` is a transposition of `log` and does not
          // match `log` under `fuzzyScore` by design.
          'methods': {'log': 'void', 'logo': 'void', 'error': 'void'},
          'fields': {},
        },
      },
    });
    MemberRegistry.debugFill('cpp', {
      'receivers': {
        'std': {
          'methods': {'vector': 'type', 'sort': 'void'},
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
    String text,
  ) {
    final NovaPromptsBuilder builder =
        NovaPromptsBuilder(languageId: languageId);
    return builder.build(
      ctx,
      CodeLine(text),
      CodeLineSelection.collapsed(index: 0, offset: text.length),
    );
  }

  Set<String> wordsOf(CodeAutocompleteEditingValue? result) =>
      result == null
          ? <String>{}
          : result.prompts.map((CodePrompt p) => p.word).toSet();

  testWidgets(r'$request->inp strips $ and finds input', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', r'$request->inp');
    expect(result, isNotNull);
    expect(result!.input, 'inp');
    expect(wordsOf(result), contains('input'));
  });

  testWidgets(r'$this-> bare offers all members', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', r'$this->');
    expect(result, isNotNull);
    expect(result!.input, isEmpty);
    expect(wordsOf(result), containsAll(['validate', 'value']));
  });

  testWidgets('bare foo-> without dollar offers all members', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'foo->');
    expect(result, isNotNull);
    expect(result!.input, isEmpty);
    expect(wordsOf(result), containsAll(['bar', 'baz']));
  });

  testWidgets('DB::ta resolves scope receiver', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'DB::ta');
    expect(result, isNotNull);
    expect(result!.input, 'ta');
    expect(wordsOf(result), contains('table'));
  });

  testWidgets('bare DB:: offers all members', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'DB::');
    expect(result, isNotNull);
    expect(result!.input, isEmpty);
    expect(wordsOf(result), containsAll(['table', 'select']));
  });

  testWidgets('std::v resolves cpp scope receiver', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'cpp', 'std::v');
    expect(result, isNotNull);
    expect(result!.input, 'v');
    expect(wordsOf(result), contains('vector'));
  });

  testWidgets('console.lgo dot path still fuzzy-matches', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'javascript', 'console.lgo');
    expect(result, isNotNull);
    expect(result!.input, 'lgo');
    // `lgo` is a subsequence (not prefix) hit for `logo`.
    expect(wordsOf(result), contains('logo'));
  });

  testWidgets('rightmost operator wins for a.b::c', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'a.b::c');
    expect(result, isNotNull);
    expect(result!.input, 'c');
    expect(wordsOf(result), contains('cat'));
    expect(wordsOf(result), isNot(contains('spacedDotBogusMember')));
  });

  testWidgets('spaced dot does not enter member completion', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', r'$a . $b');
    // Falls through to the keyword path (or null) — never the seeded
    // member for the bogus receiver.
    expect(wordsOf(result), isNot(contains('spacedDotBogusMember')));
    expect(wordsOf(result), isNot(contains('ternaryBogusMember')));
  });

  testWidgets('ternary colon does not enter member completion', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'a ? b : c');
    expect(wordsOf(result), isNot(contains('ternaryBogusMember')));
  });

  testWidgets('generics do not enter member completion', (tester) async {
    final BuildContext ctx = await pumpContext(tester);
    final CodeAutocompleteEditingValue? result =
        buildAt(ctx, 'php', 'Map<String, int>');
    expect(wordsOf(result), isNot(contains('genericsBogusMember')));
  });
}
