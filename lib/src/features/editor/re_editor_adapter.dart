import "dart:async";

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

  /// 0-based line to jump to on mount (e.g. from project search results).
  /// Null means keep the cursor at the start.
  final int? initialLine;

  /// Receives the in-file find controller bound to the editor's
  /// [CodeLineEditingController] (re_editor ^0.10.0 `CodeFindController`).
  /// The parent renders its own find bar with it: type into
  /// `findInputController`, read match state from the `ValueNotifier`,
  /// and call `nextMatch()` / `previousMatch()` / `close()`.
  /// Call `findMode()` once before typing so the search state initializes.
  final void Function(CodeFindController controller)? onFindControllerReady;

  /// Absolute file path of the edited document, when known. Used only to
  /// scope live LSP completion fetches; null disables them.
  final String? filePath;

  /// Live server completions at (`filePath`, 0-based line/char), or null
  /// when no server is available for the file. Results are cached into the
  /// prompts builder (debounced) and merged with instant local candidates.
  final Future<List<CodePrompt>> Function(String filePath, int line, int char)?
      lspCompletion;

  const ReEditorAdapter({
    super.key,
    required this.initialText,
    required this.language,
    required this.onChanged,
    this.initialLine,
    this.onFindControllerReady,
    this.filePath,
    this.lspCompletion,
  });

  @override
  ConsumerState<ReEditorAdapter> createState() => _ReEditorAdapterState();
}

class _ReEditorAdapterState extends ConsumerState<ReEditorAdapter> {
  late final CodeLineEditingController _controller;
  late final CodeScrollController _scrollController;
  late final CodeFindController _findController;
  late NovaPromptsBuilder _promptsBuilder;
  bool _didInitialJump = false;
  Timer? _lspDebounce;
  int _lspRequestId = 0;

  @override
  void initState() {
    super.initState();

    EditorFontLoader.ensureLoaded(
      ref.read(settingsStoreProvider).editorFont,
    ).then((_) {
      if (mounted) setState(() {});
    });
    _controller = CodeLineEditingController.fromText(widget.initialText);
    // Verified against re_editor 0.10.0: CodeFindController(controller)
    // drives highlight + next/previous match; CodeEditor picks it up via
    // its `findController` param even with `findBuilder` left null.
    _findController = CodeFindController(_controller);
    _scrollController = CodeScrollController(
      verticalScroller: ScrollController(),
      horizontalScroller: ScrollController(),
    );
    _promptsBuilder = NovaPromptsBuilder(
      language: _modeFor(widget.language),
      languageId: widget.language,
    );
    widget.onFindControllerReady?.call(_findController);
    if (widget.initialLine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialLine());
    }
  }

  /// Move the cursor to [ReEditorAdapter.initialLine] and scroll it into view.
  void _jumpToInitialLine() {
    if (!mounted || _didInitialJump) return;
    _didInitialJump = true;
    final target = widget.initialLine;
    if (target == null || _controller.lineCount <= 0) return;
    final line = target.clamp(0, _controller.lineCount - 1);
    _controller.selection = CodeLineSelection.collapsed(index: line, offset: 0);
    _controller.makePositionCenterIfInvisible(
      CodeLinePosition(index: line, offset: 0),
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
    _lspDebounce?.cancel();
    _findController.dispose();
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

  /// Debounced live-completion fetch: the sync autocomplete contract cannot
  /// await the server, so results are parked in
  /// [NovaPromptsBuilder.externalPrompts] and merged on the next keystroke.
  /// Stale responses (a newer keystroke has since fired) are dropped.
  void _scheduleLspFetch() {
    final fetch = widget.lspCompletion;
    final path = widget.filePath;
    if (fetch == null || path == null) return;
    _lspDebounce?.cancel();
    final int line = _controller.selection.extentIndex;
    final int character = _controller.selection.extentOffset;
    _lspDebounce = Timer(const Duration(milliseconds: 400), () async {
      final int request = ++_lspRequestId;
      final List<CodePrompt> prompts = await fetch(path, line, character);
      if (!mounted || request != _lspRequestId) return;
      _promptsBuilder.externalPrompts = prompts;
    });
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
    _scheduleLspFetch();
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

    final editorStyle = _styleFor(
      widget.language,
      pack.toHighlightTokens(),
      pack.chrome.foreground,
      pack.chrome.background,
      pack.chrome.cursor,
      pack.chrome.selection,
      pack.chrome.lineHighlight,
      fontFamilyFor(appSettings.editorFont),
      appSettings.editorFontSize,
    );
    // The CodeEditor element stays mounted at the SAME slot in every frame.
    // When the pane is squeezed to zero height (open keyboard + tall tool
    // drawer), it is laid out at 1px via OverflowBox: re_editor's
    // line-number gutter asserts maxHeight > 0, and — critically — focus
    // survives, so the keyboard does not flap. Unmounting here used to drop
    // focus, hide the keyboard, regrow the pane, remount with
    // autofocus=true, and oscillate forever.
    Widget editorTree = CodeEditor(
      controller: _controller,
      findController: _findController,
      scrollController: _scrollController,
      style: editorStyle,
      wordWrap: appSettings.wordWrap,
      indicatorBuilder: (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
            ),
          ],
        );
      },
      onChanged: (_) => _onTextChanged(),
    );
    if (autocompleteEnabled) {
      _promptsBuilder.documentText = _controller.text;
      editorTree = CodeAutocomplete(
        viewBuilder: buildAutocompletePopup,
        promptsBuilder: _promptsBuilder,
        child: editorTree,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final effMax = h.isFinite ? h.clamp(1.0, double.infinity).toDouble() : h;
        return OverflowBox(
          minHeight: 1,
          maxHeight: effMax,
          alignment: Alignment.topCenter,
          child: editorTree,
        );
      },
    );
  }
}
