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
import "../ai/ai_completion_provider.dart";
import "../ai/ai_providers.dart";
import "../../../l10n/generated/app_localizations.dart";
import "ai_insert.dart";
import "editor_engine.dart";
import "selection_toolbar.dart";
import "autocomplete/autocomplete_popup.dart";
import "autocomplete/completion_assists.dart";
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

  /// Optional AI completion provider override (tests / explicit wiring).
  /// When null, the adapter lazily builds one from the persisted AI
  /// settings plus the secure-storage key on the first eligible keystroke;
  /// with no saved API key, AI fetching stays dormant.
  final AiCompletionProvider? aiCompletion;

  /// Optional bridge for AI insert + selection reads. When provided, the
  /// adapter publishes `readContent`/`readSelection`/`insertAtCursor` plus
  /// `readCaret`/`jumpToLine` (go to definition) on mount and clears them
  /// on dispose (same convention as the Markdown view's `readContent`).
  final TabContentBridge? bridge;

  /// Long-press selection action. When provided, the adapter shows a
  /// selection toolbar (cut/copy/paste/select-all + go to definition) on
  /// mobile long-press and desktop secondary-click; the definition item
  /// resolves [word] at ([line], [character], 0-based) through this
  /// callback. Null (default) keeps re_editor's behavior: no toolbar menu.
  final void Function(String word, int line, int character)? onGoToDefinition;

  const ReEditorAdapter({
    super.key,
    required this.initialText,
    required this.language,
    required this.onChanged,
    this.initialLine,
    this.onFindControllerReady,
    this.filePath,
    this.lspCompletion,
    this.aiCompletion,
    this.bridge,
    this.onGoToDefinition,
  });

  @override
  ConsumerState<ReEditorAdapter> createState() => _ReEditorAdapterState();
}

class _ReEditorAdapterState extends ConsumerState<ReEditorAdapter> {
  late final CodeLineEditingController _controller;
  late final CodeScrollController _scrollController;
  late final CodeFindController _findController;
  late NovaPromptsBuilder _promptsBuilder;
  MobileSelectionToolbarController? _toolbarController;
  bool _didInitialJump = false;
  Timer? _lspDebounce;
  int _lspRequestId = 0;
  Timer? _aiDebounce;
  int _aiRequestId = 0;
  AiCompletionProvider? _aiProvider;
  List<CodePrompt> _lspPrompts = const [];
  List<CodePrompt> _aiPrompts = const [];

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
    // Selection toolbar is opt-in per tab wiring (the shell passes its
    // definition callback for code files; nothing else does). The menu
    // items resolve against the controller re_editor hands the builder at
    // show time, so they always see the live caret — no caching here.
    final onGoToDefinition = widget.onGoToDefinition;
    if (onGoToDefinition != null) {
      _toolbarController = MobileSelectionToolbarController(
        builder: ({
          required BuildContext context,
          required TextSelectionToolbarAnchors anchors,
          required CodeLineEditingController controller,
          required VoidCallback onDismiss,
          required VoidCallback onRefresh,
        }) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: anchors,
            buttonItems: selectionMenuItems(
              controller: controller,
              definitionLabel:
                  AppLocalizations.of(context).editorGoToDefinition,
              onDismiss: onDismiss,
              onGoToDefinition: onGoToDefinition,
            ),
          );
        },
      );
    }
    widget.onFindControllerReady?.call(_findController);
    _publishBridge();
    if (widget.initialLine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialLine());
    }
  }

  /// Publishes text/selection/insert hooks for AI actions and save paths.
  void _publishBridge() {
    final bridge = widget.bridge;
    if (bridge == null) return;
    bridge.readContent = () => _controller.text;
    bridge.readSelection = () {
      final selected = _controller.selectedText;
      return selected.isEmpty ? null : selected;
    };
    bridge.insertAtCursor = (String insert) {
      final sel = _controller.selection;
      final result = applyInsert(
        text: _controller.text,
        baseLine: sel.baseIndex,
        baseColumn: sel.baseOffset,
        extentLine: sel.extentIndex,
        extentColumn: sel.extentOffset,
        insert: insert,
      );
      _controller.text = result.text;
      _controller.selection = CodeLineSelection.collapsed(
        index: result.cursorLine,
        offset: result.cursorColumn,
      );
    };
    bridge.readCaret = () {
      if (_controller.lineCount <= 0) return null;
      final sel = _controller.selection;
      final line = sel.extentIndex.clamp(0, _controller.lineCount - 1);
      return CaretPosition(
        line: line,
        character: sel.extentOffset,
        lineText: _controller.codeLines[line].text,
      );
    };
    bridge.jumpToLine = (int line) {
      if (!mounted || _controller.lineCount <= 0) return;
      final target = line.clamp(0, _controller.lineCount - 1);
      _controller.selection =
          CodeLineSelection.collapsed(index: target, offset: 0);
      _controller.makePositionCenterIfInvisible(
        CodeLinePosition(index: target, offset: 0),
      );
    };
  }

  void _clearBridge() {
    widget.bridge?.readContent = null;
    widget.bridge?.readSelection = null;
    widget.bridge?.insertAtCursor = null;
    widget.bridge?.readCaret = null;
    widget.bridge?.jumpToLine = null;
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
      // The fresh builder drops parked async prompts; re-apply them.
      _mergeExternal();
    }
    if (oldWidget.filePath != widget.filePath) {
      // Fresh file, fresh AI backoff budget (the failure mute ends here).
      _aiRequestId++;
      _aiProvider = null;
      _aiPrompts = const [];
      _mergeExternal();
    }
  }

  @override
  void dispose() {
    _lspDebounce?.cancel();
    _aiDebounce?.cancel();
    _clearBridge();
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
      _lspPrompts = prompts;
      _mergeExternal();
    });
  }

  /// Applies parked async prompts with AI first so stable ties keep the
  /// AI suggestion on top (see [rankPrompts]).
  void _mergeExternal() {
    _promptsBuilder.externalPrompts = <CodePrompt>[
      ..._aiPrompts,
      ..._lspPrompts,
    ];
  }

  /// Trailing identifier before the caret (mirrors the extraction in
  /// `NovaPromptsBuilder`, digits accepted so `var2` keeps working).
  static String _inputBeforeCaret(String lineText, int character) {
    final int end = character.clamp(0, lineText.length);
    int start = end;
    while (start > 0 && _isAiWordChar(lineText.codeUnitAt(start - 1))) {
      start--;
    }
    return lineText.substring(start, end);
  }

  static bool _isAiWordChar(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        (codeUnit >= 48 && codeUnit <= 57) ||
        codeUnit == 95;
  }

  /// Lazily builds the AI provider from settings + the saved API key.
  /// Null when no key is saved (fetching stays dormant) or the key read
  /// fails; an explicit [ReEditorAdapter.aiCompletion] override wins.
  Future<AiCompletionProvider?> _aiProviderForFetch() async {
    final AiCompletionProvider? override = widget.aiCompletion;
    if (override != null) return override;
    final AiCompletionProvider? cached = _aiProvider;
    if (cached != null) return cached;
    try {
      final Settings settings = ref.read(settingsStoreProvider);
      final String? apiKey = await ref.read(aiKeyProvider.future);
      if (apiKey == null || apiKey.trim().isEmpty) return null;
      final AiCompletionProvider built = AiCompletionProvider(
        baseUrl: settings.aiBaseUrl,
        apiKey: apiKey,
        model: settings.aiModel,
      );
      _aiProvider = built;
      return built;
    } catch (_) {
      return null;
    }
  }

  /// Debounced AI completion fetch, mirroring [_scheduleLspFetch]: the
  /// suggestion is parked as a top-ranked `CodeFieldPrompt` (see
  /// [AiCompletionProvider.promptFor]) and merged on the next keystroke.
  /// re_editor has no ghost-text API, so the existing popup carries the
  /// suggestion with free keyboard/mouse acceptance. Never throws:
  /// [AiCompletionProvider.suggest] resolves null on any failure, and the
  /// key/config reads above are guarded (plus belt-and-braces below, so a
  /// debounced callback can never raise an unhandled async error).
  void _scheduleAiFetch() {
    _aiDebounce?.cancel();
    _aiDebounce = Timer(AiCompletionPolicy.debounce, () async {
      final int request = ++_aiRequestId;
      try {
        if (_controller.lineCount <= 0) return;
        final CodeLineSelection sel = _controller.selection;
        final int caretLine =
            sel.extentIndex.clamp(0, _controller.lineCount - 1);
        final String lineText = _controller.codeLines[caretLine].text;
        final int caretOffset =
            sel.extentOffset.clamp(0, lineText.length);
        final StringBuffer before = StringBuffer();
        for (int i = 0; i < caretLine; i++) {
          before.write(_controller.codeLines[i].text);
          before.write('\n');
        }
        before.write(lineText.substring(0, caretOffset));
        final StringBuffer after =
            StringBuffer(lineText.substring(caretOffset));
        for (int i = caretLine + 1; i < _controller.lineCount; i++) {
          after.write('\n');
          after.write(_controller.codeLines[i].text);
        }
        final String prefix = before.toString();
        final bool enabled =
            ref.read(settingsStoreProvider).autocompleteEnabled;
        if (!AiCompletionPolicy.shouldFetch(
          enabled: enabled,
          documentText: _controller.text,
          prefix: prefix,
        )) {
          return;
        }
        final AiCompletionProvider? provider =
            await _aiProviderForFetch();
        if (provider == null || provider.isMuted) return;
        final String? suggestion = await provider.suggest(
          language: widget.language,
          prefix: prefix,
          suffix: after.toString(),
        );
        if (!mounted || request != _aiRequestId) return;
        if (suggestion == null || suggestion.isEmpty) {
          if (_aiPrompts.isNotEmpty) {
            _aiPrompts = const [];
            _mergeExternal();
          }
          return;
        }
        _aiPrompts = <CodePrompt>[
          AiCompletionProvider.promptFor(
            input: _inputBeforeCaret(lineText, caretOffset),
            suggestion: suggestion,
          ),
        ];
        _mergeExternal();
      } catch (_) {
        // Guarded above; never let a debounced fetch escape.
      }
    });
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
    _scheduleLspFetch();
    _scheduleAiFetch();
  }

  /// Leading identifier of an accepted expansion (`Widget` from `Widget`,
  /// `print` from `print(object)`, `console` from `console.log();`).
  /// Importable symbols complete to their bare name, so their leading
  /// identifier is the table key; snippet expansions resolve to a
  /// non-table word and become a no-op.
  static final RegExp _leadingIdentifierPattern =
      RegExp(r"[A-Za-z_$][A-Za-z0-9_$]*");

  /// JetBrains-style auto-import after a tap-accept: when the accepted
  /// expansion starts with a known external symbol whose import line is
  /// missing, inserts `<import>\n` at the top of the file (line 1 past a
  /// shebang) and shifts the caret down one line to stay on the edit.
  void _applyAutoImport(CodeAutocompleteResult result) {
    final RegExpMatch? match = _leadingIdentifierPattern.firstMatch(result.word);
    if (match == null || match.start != 0) {
      return;
    }
    final String text = _controller.text;
    final String updated = applyAutoImport(
      text: text,
      languageId: widget.language,
      acceptedWord: match.group(0)!,
    );
    if (updated == text) {
      return;
    }
    final int insertLine = autoImportInsertLine(text);
    final CodeLineSelection selection = _controller.selection;
    _controller.text = updated;
    _controller.selection = CodeLineSelection(
      baseIndex:
          insertLine <= selection.baseIndex ? selection.baseIndex + 1 : selection.baseIndex,
      baseOffset: selection.baseOffset,
      extentIndex: insertLine <= selection.extentIndex
          ? selection.extentIndex + 1
          : selection.extentIndex,
      extentOffset: selection.extentOffset,
    );
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
      toolbarController: _toolbarController,
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
        // Tap-accept interception: the wrapper forwards to the popup and
        // then applies the auto-import for the accepted symbol. Enter-key
        // acceptance is dispatched inside re_editor's private shortcut
        // action and bypasses this callback, so Enter does not auto-import
        // (documented limitation; no re_editor fork).
        viewBuilder: (context, notifier, onSelected) =>
            buildAutocompletePopup(context, notifier, (result) {
          onSelected(result);
          _applyAutoImport(result);
        }),
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
