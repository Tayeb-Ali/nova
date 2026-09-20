import 'package:nova/src/features/editor/autocomplete/language_members.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

/// JSON maintenance contract: tables are data (`assets/autocomplete/`),
/// so tests seed the registry directly instead of touching assets.
const _sampleJson = {
  "receivers": {
    "console": {
      "methods": {"log": "void", "error": "void"},
      "fields": {},
    },
    "Math": {
      "methods": {"random": "number"},
      "fields": {"PI": "number"},
    },
    "broken": "not-a-map",
  },
};

void main() {
  setUpAll(() => MemberRegistry.debugFill('javascript', _sampleJson));

  group('memberPrompts', () {
    test('console members unfiltered on empty partial', () {
      final prompts = memberPrompts('javascript', 'console', '')!;
      final words = prompts.map((p) => p.word).toSet();
      expect(words, containsAll(['log', 'error']));
    });

    test('filters by partial prefix', () {
      final prompts = memberPrompts('javascript', 'console', 'e')!;
      final words = prompts.map((p) => p.word).toSet();
      expect(words, contains('error'));
      expect(words, isNot(contains('log')));
    });

    test('exact word is excluded like other prompts', () {
      expect(memberPrompts('javascript', 'console', 'log'), isNull);
    });

    test('unknown receiver or language falls through', () {
      expect(memberPrompts('javascript', 'frobnicate', ''), isNull);
      expect(memberPrompts('php', 'console', ''), isNull);
      expect(memberPrompts(null, 'console', ''), isNull);
    });

    test('methods carry function prompts with return types', () {
      final prompts = memberPrompts('javascript', 'console', 'err')!;
      final prompt = prompts.single as CodeFunctionPrompt;
      expect(prompt.word, 'error');
      expect(prompt.type, 'void');
    });

    test('fields parse as field prompts', () {
      final prompts = memberPrompts('javascript', 'Math', 'P')!;
      final prompt = prompts.single as CodeFieldPrompt;
      expect(prompt.word, 'PI');
      expect(prompt.type, 'number');
    });

    test('malformed receiver entries are skipped', () {
      expect(memberPrompts('javascript', 'broken', ''), isNull);
    });
  });
}
