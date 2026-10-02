import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:re_editor/re_editor.dart";

import "package:nova/src/features/editor/selection_toolbar.dart";

/// Builds a controller over [text] with a collapsed caret at ([line],
/// [offset]), mirroring a fresh tap in the editor.
CodeLineEditingController _caret(
  String text, {
  int line = 0,
  required int offset,
}) {
  final controller = CodeLineEditingController.fromText(text);
  controller.selection = CodeLineSelection.collapsed(
    index: line,
    offset: offset,
  );
  return controller;
}

List<ContextMenuButtonItem> _items(
  CodeLineEditingController controller, {
  void Function(String, int, int)? onGoToDefinition,
  List<(String, int, int)>? seen,
}) {
  return selectionMenuItems(
    controller: controller,
    definitionLabel: "Go to definition",
    onDismiss: () {},
    onGoToDefinition: (word, line, character) {
      seen?.add((word, line, character));
      onGoToDefinition?.call(word, line, character);
    },
  );
}

Set<ContextMenuButtonType> _types(List<ContextMenuButtonItem> items) =>
    items.map((item) => item.type).toSet();

void main() {
  group("definition item", () {
    test("caret on a word offers go to definition", () {
      final items = _items(_caret("foo(", offset: 1));
      final definition = items.where(
        (item) => item.type == ContextMenuButtonType.custom,
      );
      expect(definition, hasLength(1));
      expect(definition.single.label, "Go to definition");
    });

    test("definition callback receives word, line and character", () {
      final seen = <(String, int, int)>[];
      final items = _items(_caret("foo(\nbar", line: 1, offset: 1), seen: seen);
      final definition = items.singleWhere(
        (item) => item.type == ContextMenuButtonType.custom,
      );
      definition.onPressed!();
      expect(seen, [("bar", 1, 1)]);
    });

    test("caret on whitespace omits the definition item", () {
      final items = _items(_caret("foo(1, 2)", offset: 6));
      expect(
        items.where((item) => item.type == ContextMenuButtonType.custom),
        isEmpty,
      );
      // Standard items still show.
      expect(
        _types(items),
        containsAll([
          ContextMenuButtonType.paste,
          ContextMenuButtonType.selectAll,
        ]),
      );
    });

    test("collapsed caret omits copy and cut", () {
      final items = _items(_caret("foo", offset: 1));
      expect(_types(items), isNot(contains(ContextMenuButtonType.copy)));
      expect(_types(items), isNot(contains(ContextMenuButtonType.cut)));
    });

    test("ranged selection offers copy and cut", () {
      final controller = CodeLineEditingController.fromText("foo()");
      controller.selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 0,
        extentIndex: 0,
        extentOffset: 3,
      );
      final types = _types(_items(controller));
      expect(
        types,
        containsAll([
          ContextMenuButtonType.copy,
          ContextMenuButtonType.cut,
          ContextMenuButtonType.paste,
          ContextMenuButtonType.selectAll,
        ]),
      );
    });
  });

  group("clipboard actions", () {
    const channel = SystemChannels.platform;
    String? clipboard;
    final List<MethodCall> calls = [];

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      clipboard = null;
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == "Clipboard.getData") {
          final text = clipboard;
          return text == null ? null : <String, dynamic>{"text": text};
        }
        if (call.method == "Clipboard.setData") {
          clipboard =
              (call.arguments as Map<dynamic, dynamic>)["text"] as String?;
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test("copy writes the selection to the clipboard", () {
      final controller = CodeLineEditingController.fromText("foo()");
      controller.selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 0,
        extentIndex: 0,
        extentOffset: 3,
      );
      _items(controller)
          .singleWhere((i) => i.type == ContextMenuButtonType.copy)
          .onPressed!();
      expect(clipboard, "foo");
      // Document untouched.
      expect(controller.text, "foo()");
    });

    test("cut copies and deletes the selection", () {
      final controller = CodeLineEditingController.fromText("foo()");
      controller.selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 0,
        extentIndex: 0,
        extentOffset: 3,
      );
      _items(controller)
          .singleWhere((i) => i.type == ContextMenuButtonType.cut)
          .onPressed!();
      expect(clipboard, "foo");
      expect(controller.text, "()");
      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, 0);
    });

    test("paste inserts clipboard text at the caret", () async {
      clipboard = "XY";
      final controller = _caret("foo", offset: 3);
      _items(controller)
          .singleWhere((i) => i.type == ContextMenuButtonType.paste)
          .onPressed!();
      // Clipboard read is async: flush microtasks.
      await Future<void>.delayed(Duration.zero);
      expect(controller.text, "fooXY");
    });

    test("paste with empty clipboard is a no-op", () async {
      clipboard = null;
      final controller = _caret("foo", offset: 1);
      _items(controller)
          .singleWhere((i) => i.type == ContextMenuButtonType.paste)
          .onPressed!();
      await Future<void>.delayed(Duration.zero);
      expect(controller.text, "foo");
    });

    test("select all covers the document", () {
      final controller = _caret("ab\ncd", offset: 0);
      _items(controller)
          .singleWhere((i) => i.type == ContextMenuButtonType.selectAll)
          .onPressed!();
      final selection = controller.selection;
      expect(selection.baseIndex, 0);
      expect(selection.baseOffset, 0);
      expect(selection.extentIndex, 1);
      expect(selection.extentOffset, 2);
    });
  });
}
