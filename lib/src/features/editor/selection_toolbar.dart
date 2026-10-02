import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:re_editor/re_editor.dart";

import "../lsp/definition_service.dart" show wordAtCaret;
import "ai_insert.dart";

/// Items for the long-press selection toolbar (mobile) / secondary-click
/// menu (desktop), shown through re_editor's [MobileSelectionToolbarController].
///
/// Standard editing items first (cut/copy only with a real selection,
/// paste/select-all always), then — only when the caret sits on a symbol —
/// the go-to-definition entry, which resolves ([word] at ([line],
/// [character], 0-based) through [onGoToDefinition]. re_editor shows no
/// toolbar at all unless the adapter provides a controller, so wiring this
/// is what enables the menu in the first place.
List<ContextMenuButtonItem> selectionMenuItems({
  required CodeLineEditingController controller,
  required String definitionLabel,
  required VoidCallback onDismiss,
  required void Function(String word, int line, int character) onGoToDefinition,
}) {
  final CodeLineSelection selection = controller.selection;
  final bool collapsed =
      selection.baseIndex == selection.extentIndex &&
      selection.baseOffset == selection.extentOffset;
  final List<ContextMenuButtonItem> items = <ContextMenuButtonItem>[
    if (!collapsed) ...[
      ContextMenuButtonItem(
        onPressed: () {
          onDismiss();
          _cut(controller);
        },
        type: ContextMenuButtonType.cut,
      ),
      ContextMenuButtonItem(
        onPressed: () {
          onDismiss();
          _copy(controller);
        },
        type: ContextMenuButtonType.copy,
      ),
    ],
    ContextMenuButtonItem(
      onPressed: () {
        onDismiss();
        unawaited(_paste(controller));
      },
      type: ContextMenuButtonType.paste,
    ),
    ContextMenuButtonItem(
      onPressed: () {
        onDismiss();
        controller.selectAll();
      },
      type: ContextMenuButtonType.selectAll,
    ),
  ];
  if (controller.lineCount > 0) {
    final int line =
        selection.extentIndex.clamp(0, controller.lineCount - 1);
    final String? word = wordAtCaret(
      controller.codeLines[line].text,
      selection.extentOffset,
    );
    if (word != null && word.isNotEmpty) {
      items.add(
        ContextMenuButtonItem(
          onPressed: () {
            onDismiss();
            onGoToDefinition(word, line, selection.extentOffset);
          },
          type: ContextMenuButtonType.custom,
          label: definitionLabel,
        ),
      );
    }
  }
  return items;
}

void _copy(CodeLineEditingController controller) {
  final String selected = controller.selectedText;
  if (selected.isEmpty) return;
  unawaited(Clipboard.setData(ClipboardData(text: selected)));
}

void _cut(CodeLineEditingController controller) {
  final String selected = controller.selectedText;
  if (selected.isEmpty) return;
  unawaited(Clipboard.setData(ClipboardData(text: selected)));
  _replaceSelection(controller, "");
}

Future<void> _paste(CodeLineEditingController controller) async {
  final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
  final String? clip = data?.text;
  if (clip == null || clip.isEmpty) return;
  _replaceSelection(controller, clip);
}

/// Replaces the current selection (or caret) with [insert], mirroring the
/// adapter's insert path so cut/paste behave identically everywhere.
void _replaceSelection(CodeLineEditingController controller, String insert) {
  final CodeLineSelection selection = controller.selection;
  final result = applyInsert(
    text: controller.text,
    baseLine: selection.baseIndex,
    baseColumn: selection.baseOffset,
    extentLine: selection.extentIndex,
    extentColumn: selection.extentOffset,
    insert: insert,
  );
  controller.text = result.text;
  controller.selection = CodeLineSelection.collapsed(
    index: result.cursorLine,
    offset: result.cursorColumn,
  );
}
