import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/re_highlight.dart";
import "package:re_highlight/languages/dart.dart";
import "package:re_highlight/languages/javascript.dart";
import "package:re_highlight/languages/php.dart";
import "package:re_highlight/languages/python.dart";
import "package:re_highlight/languages/json.dart";

import "../../core/settings_store.dart";
import "autocomplete/autocomplete_popup.dart";
import "autocomplete/nova_prompts_builder.dart";
import "theme/editor_fonts.dart";
import "theme/theme_pack_store.dart";

/// Thin wrapper around re_editor [CodeEditor].
///
/// [language] is one of: python, javascript, php, dart, json, plaintext.
/// [onChanged] receives the full current text on every edit.
///
/// The editor follows the app brightness through the active theme pack
/// (built-in VSCode-like defaults, user-importable JSON packs), and offers
/// VSCode-style autocomplete (keywords + snippets + words from the open file)
/// unless disabled in settings.
class ReEditorAdapter extends ConsumerStatefulWidget {
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
  ConsumerState<ReEditorAdapter> createState() => _ReEditorAdapterState();
}

class _ReEditorAdapterState extends ConsumerState<ReEditorAdapter> {
  late final CodeLineEditingController _controller;
  late final CodeScrollController _scrollController;
  late NovaPromptsBuilder _promptsBuilder;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.initialText);
    _scrollController = CodeScrollController(
      verticalScroller: ScrollController(),
      horizontalScroller: ScrollController(),
    );
    _promptsBuilder = NovaPromptsBuilder(
      language: _modeFor(widget.language),
      languageId: widget.language,
    );
  }

  @override
  void didUpdateWidget(covariant ReEditorAdapter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      _promptsBuilder = NovaPromptsBuilder(
        language: _modeFor(widget.language),
        languageId: widget.language,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.verticalScroller.dispose();
    _scrollController.horizontalScroller.dispose();
    super.dispose();
  }

  static Mode? _modeFor(String language) {
    switch (language) {
      case "python":
        return langPython;
      case "javascript":
        return langJavascript;
      case "php":
        return langPhp;
      case "dart":
        return langDart;
      case "json":
        return langJson;
      default:
        return null;
    }
  }

  CodeEditorStyle? _styleFor(
    String language,
    Map<String, TextStyle> tokens,
    Color textColor,
    Color backgroundColor,
    Color cursorColor,
    Color selectionColor,
    Color lineHighlightColor,
    String? fontFamily,
    double fontSize,
  ) {
    final mode = _modeFor(language);
    if (mode == null) return null;
    return CodeEditorStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      textColor: textColor,
      backgroundColor: backgroundColor,
      cursorColor: cursorColor,
      selectionColor: selectionColor,
      cursorLineColor: lineHighlightColor,
      codeTheme: CodeHighlightTheme(
        languages: {
          language: CodeHighlightThemeMode(mode: mode),
        },
        theme: tokens,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Rebuild when the active pack id for either brightness changes.
    ref.watch(editorThemeStoreProvider.select((s) => s.lightPackId));
    ref.watch(editorThemeStoreProvider.select((s) => s.darkPackId));
    final pack = ref
        .read(editorThemeStoreProvider.notifier)
        .packFor(brightness);
    final appSettings = ref.watch(settingsStoreProvider);
    final autocompleteEnabled = appSettings.autocompleteEnabled;

    final editor = CodeEditor(
      controller: _controller,
      scrollController: _scrollController,
      style: _styleFor(
        widget.language,
        pack.toHighlightTokens(),
        pack.chrome.foreground,
        pack.chrome.background,
        pack.chrome.cursor,
        pack.chrome.selection,
        pack.chrome.lineHighlight,
        fontFamilyFor(appSettings.editorFont),
        appSettings.editorFontSize,
      ),
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
    if (!autocompleteEnabled) return editor;
    _promptsBuilder.documentText = _controller.text;
    return CodeAutocomplete(
      viewBuilder: buildAutocompletePopup,
      promptsBuilder: _promptsBuilder,
      child: editor,
    );
  }
}
