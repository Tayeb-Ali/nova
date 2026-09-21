import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/re_highlight.dart";
import "package:re_highlight/languages/dart.dart";
import "package:re_highlight/languages/javascript.dart";
import "package:re_highlight/languages/php.dart";
import "package:re_highlight/languages/python.dart";
import "package:re_highlight/languages/json.dart";
import "package:re_highlight/languages/latex.dart";
import "package:re_highlight/languages/typescript.dart";
import "package:re_highlight/languages/java.dart";
import "package:re_highlight/languages/kotlin.dart";
import "package:re_highlight/languages/go.dart";
import "package:re_highlight/languages/rust.dart";
import "package:re_highlight/languages/c.dart";
import "package:re_highlight/languages/cpp.dart";
import "package:re_highlight/languages/csharp.dart";
import "package:re_highlight/languages/swift.dart";
import "package:re_highlight/languages/ruby.dart";
import "package:re_highlight/languages/sql.dart";
import "package:re_highlight/languages/css.dart";
import "package:re_highlight/languages/scss.dart";
import "package:re_highlight/languages/xml.dart";
import "package:re_highlight/languages/yaml.dart";
import "package:re_highlight/languages/shell.dart";
import "package:re_highlight/languages/gradle.dart";
import "package:re_highlight/languages/dockerfile.dart";
import "package:re_highlight/languages/makefile.dart";

import "../../core/settings_store.dart";
import "autocomplete/autocomplete_popup.dart";
import "autocomplete/nova_prompts_builder.dart";
import "theme/editor_fonts.dart";
import "theme/font_loader.dart";
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
    
    EditorFontLoader.ensureLoaded(
      ref.read(settingsStoreProvider).editorFont,
    ).then((_) {
      if (mounted) setState(() {});
    });
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
      case "typescript":
        return langTypescript;
      case "java":
        return langJava;
      case "kotlin":
        return langKotlin;
      case "go":
        return langGo;
      case "rust":
        return langRust;
      case "c":
        return langC;
      case "cpp":
        return langCpp;
      case "csharp":
        return langCsharp;
      case "swift":
        return langSwift;
      case "ruby":
        return langRuby;
      case "sql":
        return langSql;
      case "css":
        return langCss;
      case "scss":
        return langScss;
      case "xml":
        return langXml;
      case "yaml":
        return langYaml;
      case "shell":
        return langShell;
      case "gradle":
        return langGradle;
      case "dockerfile":
        return langDockerfile;
      case "makefile":
        return langMakefile;
      case "php":
        return langPhp;
      case "dart":
        return langDart;
      case "json":
        return langJson;
      case "latex":
        return langLatex;
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
      wordWrap: appSettings.wordWrap,
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
