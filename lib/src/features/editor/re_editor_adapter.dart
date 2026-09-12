import "package:flutter/material.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/re_highlight.dart";
import "package:re_highlight/languages/dart.dart";
import "package:re_highlight/languages/javascript.dart";
import "package:re_highlight/languages/php.dart";
import "package:re_highlight/languages/python.dart";
import "package:re_highlight/languages/json.dart";
import "package:re_highlight/styles/atom-one-light.dart";

/// Thin wrapper around re_editor [CodeEditor].
///
/// [language] is one of: python, javascript, php, dart, json, plaintext.
/// [onChanged] receives the full current text on every edit.
class ReEditorAdapter extends StatefulWidget {
  final String initialText;
  final String language;
  final ValueChanged<String> onChanged;

  const ReEditorAdapter({
    super.key,
    required this.initialText,
    required this.language,
    required this.onChanged,
  });

  @override
  State<ReEditorAdapter> createState() => _ReEditorAdapterState();
}

class _ReEditorAdapterState extends State<ReEditorAdapter> {
  late final CodeLineEditingController _controller;
  late final CodeScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.initialText);
    _scrollController = CodeScrollController(
      verticalScroller: ScrollController(),
      horizontalScroller: ScrollController(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.verticalScroller.dispose();
    _scrollController.horizontalScroller.dispose();
    super.dispose();
  }

  CodeEditorStyle? _styleFor(String language) {
    Mode? mode;
    switch (language) {
      case "python":
        mode = langPython;
        break;
      case "javascript":
        mode = langJavascript;
        break;
      case "php":
        mode = langPhp;
        break;
      case "dart":
        mode = langDart;
        break;
      case "json":
        mode = langJson;
        break;
      default:
        mode = null;
    }
    if (mode == null) return null;
    return CodeEditorStyle(
      codeTheme: CodeHighlightTheme(
        languages: {
          language: CodeHighlightThemeMode(mode: mode),
        },
        theme: atomOneLightTheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      controller: _controller,
      scrollController: _scrollController,
      style: _styleFor(widget.language),
      wordWrap: false,
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
            ),
          ],
        );
      },
      onChanged: (_) => widget.onChanged(_controller.text),
    );
  }
}