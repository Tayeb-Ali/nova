import "package:flutter_test/flutter_test.dart";
import "package:re_editor/re_editor.dart";

import "package:nova/src/features/editor/autocomplete/autocomplete_popup.dart";

void main() {
  group("signatureDetailFor", () {
    test("renders name, parameters, and return type", () {
      final prompt = CodeFunctionPrompt(
        word: "println",
        type: "Unit",
        parameters: {"message": "Any?"},
      );
      expect(signatureDetailFor(prompt), "println(message: Any?) → Unit");
    });

    test("renders empty parameter lists", () {
      final prompt = CodeFunctionPrompt(word: "foo", type: "void");
      expect(signatureDetailFor(prompt), "foo() → void");
    });

    test("joins multiple parameters in order", () {
      final prompt = CodeFunctionPrompt(
        word: "add",
        type: "int",
        parameters: {"a": "int", "b": "int"},
      );
      expect(signatureDetailFor(prompt), "add(a: int, b: int) → int");
    });

    test("leaves short signatures untouched", () {
      final prompt = CodeFunctionPrompt(word: "f", type: "R");
      expect(signatureDetailFor(prompt).endsWith("…"), isFalse);
    });

    test("truncates long signatures at the cap", () {
      final prompt = CodeFunctionPrompt(
        word: "someVeryLongFunctionName",
        type: "SomeVeryLongReturnType",
        parameters: {
          "firstArgument": "FirstArgumentType",
          "secondArgument": " SecondArgumentType".trim(),
          "thirdArgument": "ThirdArgumentType",
          "fourthArgument": "FourthArgumentType",
        },
      );
      final detail = signatureDetailFor(prompt);
      expect(detail.length, lessThanOrEqualTo(kMaxSignatureDetailLength));
      expect(detail, endsWith("…"));
      expect(detail.startsWith("someVeryLongFunctionName("), isTrue);
    });

    test("respects a custom maxLength", () {
      final prompt = CodeFunctionPrompt(
        word: "add",
        type: "int",
        parameters: {"a": "int", "b": "int"},
      );
      expect(signatureDetailFor(prompt, maxLength: 10), "add(a: in…");
    });
  });
}
