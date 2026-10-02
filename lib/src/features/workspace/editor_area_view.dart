import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:path/path.dart" as p;
import "package:re_editor/re_editor.dart";

import "../../core/settings_store.dart";
import "../../core/ui/empty_state.dart";
import "../lsp/lsp_completion_provider.dart";
import "../lsp/lsp_providers.dart";
import "../lsp/server_registry.dart";
import "../ai/ai_actions.dart";
import "../editor/editor_engine.dart";
import "../editor/re_editor_adapter.dart";
import "../markdown/markdown_editor_view.dart";
import "recovery_store.dart";
import "save_coordinator.dart";
import "workspace_providers.dart";

/// Editor: tab strip + the active file edited with re_editor (task.md §35).
class EditorAreaView extends ConsumerWidget {
  const EditorAreaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(workspaceTabsProvider);
    final active = ref.watch(activeEditorTabModelProvider);
    final focus = ref.watch(focusModeProvider);
    final scheme = Theme.of(context).colorScheme;
    if (tabs.isEmpty || active == null) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: AppLocalizations.of(context).editorEmptyHint,
      );
    }
    return Column(
      children: [
        if (!focus) ...[
          _TabStrip(tabs: tabs, activeId: active.id),
          Divider(height: 1, color: scheme.outlineVariant),
        ] else ...[
          _FocusBar(tab: active),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
        Expanded(
          child: _EditorTabBody(key: ValueKey(active.id), tab: active),
        ),
      ],
    );
  }
}

/// Minimal chrome shown in focus mode: filename + dirty dot + actions.
class _FocusBar extends ConsumerWidget {
  final EditorTabModel tab;
  const _FocusBar({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final actions = ref.watch(activeEditorActionsProvider);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tab.dirty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.circle, size: 8, color: scheme.tertiary),
                  ),
                Flexible(
                  child: Tooltip(
                    message: tab.path,
                    child: Text(
                      p.basename(tab.path),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isMarkdown)
            IconButton(
              onPressed: actions.togglePreview,
              visualDensity: VisualDensity.compact,
              tooltip: actions.showPreview
                  ? l10n.editorEdit
                  : l10n.editorPreview,
              icon: Icon(
                actions.showPreview
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
            ),
          IconButton(
            onPressed: actions.loaded ? actions.reload : null,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.actionRefresh,
            icon: const Icon(Icons.refresh, size: 18),
          ),
          IconButton(
            onPressed: actions.loaded ? actions.save : null,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.save, size: 18),
          ),
          IconButton(
            onPressed: () => ref.read(focusModeProvider.notifier).state = false,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.editorFocusExit,
            icon: const Icon(Icons.fullscreen_exit, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TabStrip extends ConsumerWidget {
  final List<EditorTabModel> tabs;
  final String? activeId;

  const _TabStrip({required this.tabs, required this.activeId});

  void _close(WidgetRef ref, String id) {
    final wasActive = ref.read(activeEditorTabProvider) == id;
    EditorTabModel? closed;
    for (final t in ref.read(workspaceTabsProvider)) {
      if (t.id == id) closed = t;
    }
    ref.read(workspaceTabsProvider.notifier).close(id);
    if (wasActive) {
      final remaining = ref.read(workspaceTabsProvider);
      ref.read(activeEditorTabProvider.notifier).state = remaining.isEmpty
          ? null
          : remaining.last.id;
    }
    // Best-effort didClose so servers drop the document (no-op otherwise).
    final done = closed;
    if (done != null && serverArgvFor(done.language) != null) {
      final project = ref.read(activeProjectProvider);
      if (project != null) {
        unawaited(
          ref
              .read(goLspManagerProvider)
              .didCloseFile(project.path, done.path, done.language),
        );
      }
    }
  }

  /// Close with a guard: a dirty tab keeps its recovery draft (reopening
  /// offers restore), but the user must confirm abandoning unsaved edits.
  Future<void> _closeGuarded(
    BuildContext context,
    WidgetRef ref,
    EditorTabModel tab,
  ) async {
    if (tab.dirty) {
      final l10n = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.editorCloseDirtyTitle),
          content: Text(l10n.editorCloseDirtyBody(p.basename(tab.path))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDiscard),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    _close(ref, tab.id);
  }

  Widget _tabChip(BuildContext context, WidgetRef ref, EditorTabModel tab) {
    final selected = tab.id == activeId;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () =>
                ref.read(activeEditorTabProvider.notifier).state = tab.id,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.surfaceContainerHigh
                    : scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.dirty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: scheme.tertiary,
                      ),
                    ),
                  Text(
                    p.basename(tab.path),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => _closeGuarded(context, ref, tab),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Active tab 2px primary underline (DESIGN.md tabs language).
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 2),
            color: selected ? scheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final actions = ref.watch(activeEditorActionsProvider);
    final focus = ref.watch(focusModeProvider);

    return Container(
      height: 48,
      color: scheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On narrow panes (phone + explorer open) collapse all actions
          // into a single overflow menu so the strip never overflows.
          final compact = constraints.maxWidth < 250;

          return Row(
            children: [
              // Scrollable tab chips.
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final tab in tabs) _tabChip(context, ref, tab),
                  ],
                ),
              ),
              // Action buttons pinned to the trailing edge.
              if (actions.loaded) ...[
                VerticalDivider(
                  width: 1,
                  indent: 10,
                  endIndent: 10,
                  color: scheme.outlineVariant,
                ),
                if (compact)
                  PopupMenuButton<String>(
                    tooltip: l10n.editorTabActions,
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == "preview") {
                        actions.togglePreview?.call();
                      } else if (value == "save") {                        actions.save?.call();
                      } else if (value == "reload") {
                        actions.reload?.call();
                      } else if (value == "ai") {
                        actions.askAi?.call();
                      } else if (value == "focus") {
                        ref.read(focusModeProvider.notifier).state = !focus;
                      }
                    },
                    itemBuilder: (context) => [
                      if (actions.isMarkdown)
                        PopupMenuItem(
                          value: "preview",
                          child: Text(
                            actions.showPreview
                                ? l10n.editorEdit
                                : l10n.editorPreview,
                          ),
                        ),
                      PopupMenuItem(
                        value: "save",
                        child: Text(l10n.actionSave),
                      ),
                      PopupMenuItem(
                        value: "reload",
                        child: Text(l10n.actionRefresh),
                      ),
                      if (actions.askAi != null)
                        PopupMenuItem(
                          value: "ai",
                          child: Text(l10n.aiTitle),
                        ),
                      PopupMenuItem(
                        value: "focus",
                        child: Text(
                          focus
                              ? l10n.editorFocusExit
                              : l10n.editorFocusEnter,
                        ),
                      ),
                    ],
                  )
                else ...[
                  if (actions.isMarkdown)
                    IconButton(
                      onPressed: actions.togglePreview,
                      visualDensity: VisualDensity.compact,
                      tooltip: actions.showPreview
                          ? l10n.editorEdit
                          : l10n.editorPreview,
                      icon: Icon(
                        actions.showPreview
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                    ),
                  IconButton(
                    onPressed: () =>
                        ref.read(focusModeProvider.notifier).state = !focus,
                    visualDensity: VisualDensity.compact,
                    tooltip:
                        focus ? l10n.editorFocusExit : l10n.editorFocusEnter,
                    icon: Icon(
                      focus ? Icons.fullscreen_exit : Icons.fullscreen,
                      size: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: actions.reload,
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.actionRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                  if (actions.askAi != null)
                    IconButton(
                      onPressed: actions.askAi,
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.aiTitle,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                    ),
                  IconButton(
                    onPressed: actions.save,
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.actionSave,
                    icon: const Icon(Icons.save, size: 18),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EditorTabBody extends ConsumerStatefulWidget {
  final EditorTabModel tab;

  const _EditorTabBody({super.key, required this.tab});

  @override
  ConsumerState<_EditorTabBody> createState() => _EditorTabBodyState();
}

class _EditorTabBodyState extends ConsumerState<_EditorTabBody> {
  Future<String>? _loadFuture;
  String _currentText = "";
  String _savedText = "";
  bool _loaded = false;
  bool _dirty = false;
  bool _showPreview = false;
  final TabContentBridge _bridge = TabContentBridge();
  Timer? _autoSaveTimer;
  Timer? _recoveryTimer;
  final SaveGate _saveGate = SaveGate();
  final RecoveryStore _recovery = RecoveryStore();
  String? _pendingRecovery;
  bool _recoveryAsked = false;
  int _contentGen = 0;
  int _loadGen = 0;
  // Mount override for the editor content (crash-draft restore). The load
  // future still carries the disk text, so without this a remount would
  // clobber the restored draft with stale bytes.
  String? _mountOverride;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void deactivate() {
    // Clear actions before the widget leaves the tree so the tab strip
    // does not hold stale callbacks from a disposed state.
    ref.read(activeEditorActionsProvider.notifier).state =
        ActiveEditorActions.empty;
    super.deactivate();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _recoveryTimer?.cancel();
    super.dispose();
  }

  /// Push the current save / reload / preview callbacks into the shared
  /// provider so the combined tab strip (or focus bar) can render them.
  void _updateActions() {
    if (!mounted) return;
    ref.read(activeEditorActionsProvider.notifier).state = ActiveEditorActions(
      save: _loaded ? () => _save() : null,
      reload: _loaded ? _reload : null,
      togglePreview: () => setState(() {
        _showPreview = !_showPreview;
        // Re-publish so the button icon flips.
        _updateActions();
      }),
      // AI insert needs the code bridge (Markdown view has none).
      askAi: _loaded && widget.tab.kind != EditorKind.markdown
          ? _askAi
          : null,
      loaded: _loaded,
      showPreview: _showPreview,
      isMarkdown: widget.tab.kind == EditorKind.markdown,
    );
  }

  @override
  void didUpdateWidget(covariant _EditorTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.path != widget.tab.path) {
      _autoSaveTimer?.cancel();
      _recoveryTimer?.cancel();
      _loaded = false;
      _currentText = "";
      _savedText = "";
      _dirty = false;
      _showPreview = false;
      _pendingRecovery = null;
      _recoveryAsked = false;
      _contentGen = 0;
      _mountOverride = null;
      _clearBridge();
      _loadFuture = _load();
    }
  }

  Future<String> _load() async {
    final service = ref.read(projectServiceProvider);
    try {
      final text = await service.readFile(widget.tab.path);
      _currentText = text;
      _savedText = text;
      _dirty = false;
      _loaded = true;
      _notifyGoOpen();
      _updateActions();
      // Crash recovery (never blocks content): a draft left by unsaved
      // edits is offered once the editor sits pristine on disk text —
      // never applied silently, never clobbering fresh typing.
      final int gen = ++_loadGen;
      unawaited(_checkRecoveryDraft(text, gen));
      return text;
    } catch (_) {
      _currentText = "";
      _savedText = "";
      _dirty = false;
      _loaded = true;
      _updateActions();
      return "";
    }
  }

  Future<void> _checkRecoveryDraft(String diskText, int gen) async {
    final draft = await _recovery.readDraft(widget.tab.path);
    if (!mounted || gen != _loadGen) return;
    if (draft == null || draft.text == diskText) return;
    // Offer only while the editor still shows pristine disk content;
    // keystrokes that landed meanwhile always win over the old draft.
    if (!_loaded || _currentText != diskText) return;
    setState(() {
      _pendingRecovery = draft.text;
      _recoveryAsked = false;
    });
  }

  /// Best-effort didOpen for files whose language has a registered stdio
  /// server (silently skipped otherwise).
  void _notifyGoOpen() {
    if (serverArgvFor(widget.tab.language) == null) return;
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    ref
        .read(goLspManagerProvider)
        .didOpenFile(project.path, widget.tab.path, widget.tab.language);
  }

  /// Live server completions for languages with a registered stdio server
  /// (gopls, pyright, typescript-server, phpactor). Best-effort: null when
  /// the project is unknown or the language has no server, so the editor
  /// falls back to instant local candidates.
  Future<List<CodePrompt>> Function(String, int, int)? _lspCompletionFor() {
    if (serverArgvFor(widget.tab.language) == null) return null;
    final project = ref.read(activeProjectProvider);
    if (project == null) return null;
    final projectPath = project.path;
    final language = widget.tab.language;
    return (String filePath, int line, int character) async {
      try {
        final items = await ref
            .read(goLspManagerProvider)
            .completionFor(projectPath, language, filePath, line, character);
        return lspItemsToPrompts(items);
      } catch (_) {
        return const [];
      }
    };
  }

  /// Best-effort didChange after save (sends what was written).
  void _notifyGoSave(String written) {
    if (serverArgvFor(widget.tab.language) == null) return;
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    ref
        .read(goLspManagerProvider)
        .didChangeFile(project.path, widget.tab.path, widget.tab.language, written);
  }

  /// Clears every published bridge hook (called before remounts so a
  /// disposed adapter never serves stale callbacks).
  void _clearBridge() {
    _bridge.readContent = null;
    _bridge.readSelection = null;
    _bridge.insertAtCursor = null;
  }

  /// Opens the AI sheet for the selection (or the whole file) and
  /// inserts the result at the cursor. Best-effort: silently skipped when
  /// the bridge is not published yet.
  void _askAi() {
    final l10n = AppLocalizations.of(context);
    final selected = _bridge.readSelection?.call();
    final code = (selected != null && selected.trim().isNotEmpty)
        ? selected
        : (_bridge.readContent?.call() ?? _currentText);
    if (code.trim().isEmpty) {
      _toast(l10n.aiNoCode);
      return;
    }
    AiActionsSheet.show(
      context,
      selectedCode: code,
      onInsert: (String result) {
        _bridge.insertAtCursor?.call(result);
      },
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Reload the file from disk (refresh). With unsaved edits, asks first;
  /// confirming discards the edits AND the recovery draft, then remounts
  /// the editor on the fresh content.
  Future<void> _reload() async {
    if (!_loaded) return;
    final l10n = AppLocalizations.of(context);
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.editorReloadConfirmTitle),
          content: Text(l10n.editorReloadConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDiscard),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    _autoSaveTimer?.cancel();
    _recoveryTimer?.cancel();
    unawaited(_recovery.clearDraft(widget.tab.path));
    setState(() {
      _loaded = false;
      _currentText = "";
      _savedText = "";
      _dirty = false;
      _pendingRecovery = null;
      _recoveryAsked = false;
      _mountOverride = null;
      _contentGen++;
      _clearBridge();
      _loadFuture = _load();
    });
    ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, false);
    _toast(l10n.editorReloaded(p.basename(widget.tab.path)));
  }

  /// One-shot restore offer for a crash-recovery draft, shown after the
  /// editor mounts on disk content. Restore remounts the editor on the
  /// draft (kept dirty); discard deletes the draft.
  void _maybeOfferRecovery() {
    if (_pendingRecovery == null || _recoveryAsked || !_loaded) return;
    _recoveryAsked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _askRecovery());
  }

  Future<void> _askRecovery() async {
    final draft = _pendingRecovery;
    if (!mounted || draft == null) return;
    final l10n = AppLocalizations.of(context);
    final restore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.editorRecoverTitle),
        content: Text(l10n.editorRecoverBody(p.basename(widget.tab.path))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionDiscard),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionRestore),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _pendingRecovery = null;
    if (restore == true) {
      setState(() {
        _currentText = draft;
        _mountOverride = draft;
        _dirty = true;
        _contentGen++;
      });
      ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, true);
      _scheduleRecoveryWrite();
    } else {
      unawaited(_recovery.clearDraft(widget.tab.path));
    }
  }

  void _onChanged(String text) {
    _currentText = text;
    final dirty = _loaded && text != _savedText;
    _dirty = dirty;
    ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, dirty);
    _scheduleAutoSave(dirty);
    _scheduleRecoveryWrite();
  }

  // Debounced auto-save: 1.5s after the last keystroke, reuses [_save].
  void _scheduleAutoSave(bool dirty) {
    _autoSaveTimer?.cancel();
    if (!dirty || !_loaded) return;
    if (!ref.read(settingsStoreProvider).autoSave) return;
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (!ref.read(settingsStoreProvider).autoSave) return;
      _save(silent: true);
    });
  }

  /// Debounced crash-recovery snapshot: the dirty buffer is parked 2s after
  /// the last keystroke so a killed app (or closed tab) can offer restore.
  void _scheduleRecoveryWrite() {
    _recoveryTimer?.cancel();
    if (!_dirty || !_loaded) return;
    _recoveryTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_dirty) return;
      final latest = _bridge.readContent?.call() ?? _currentText;
      // Fire-and-forget: the store never throws.
      unawaited(_recovery.writeDraft(widget.tab.path, latest));
    });
  }

  /// Serialized save: overlapping saves (manual + auto, double-tap) are
  /// coalesced through [SaveGate] so an older write can never finish after
  /// a newer one and regress the disk to stale content. A manual save also
  /// cancels any pending auto-save for the same snapshot.
  Future<void> _save({bool silent = false}) async {
    _autoSaveTimer?.cancel();
    if (!_saveGate.begin()) return;
    do {
      await _writeCurrent(silent: silent);
    } while (_saveGate.end() && mounted);
  }

  Future<void> _writeCurrent({bool silent = false}) async {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(projectServiceProvider);
    final text = _bridge.readContent?.call() ?? _currentText;
    try {
      await service.writeFile(widget.tab.path, text);
    } catch (e) {
      if (!mounted) return;
      _toast(l10n.editorSaveFailed("$e"));
      return;
    }
    if (!mounted) return;
    unawaited(_recovery.clearDraft(widget.tab.path));
    // The editor may have moved on while the write was in flight: only a
    // tab that still holds exactly what was written may go clean. Anything
    // newer keeps its dirty dot (and re-arms auto-save) instead of faking
    // a clean state over stale bytes.
    final current = _bridge.readContent?.call() ?? _currentText;
    if (settleSave(written: text, current: current) == SaveSettle.clean) {
      _currentText = text;
      _savedText = text;
      _dirty = false;
      ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, false);
    } else {
      _currentText = current;
      _savedText = text;
      _dirty = true;
      ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, true);
      _scheduleRecoveryWrite();
      _scheduleAutoSave(true);
    }
    _notifyGoSave(text);
    if (!silent) _toast(l10n.editorSaved(p.basename(widget.tab.path)));
  }

  @override
  Widget build(BuildContext context) {
    // Dropping a pending auto-save when the toggle is switched off.
    ref.listen(settingsStoreProvider.select((s) => s.autoSave), (
      previous,
      next,
    ) {
      if (next == false) _autoSaveTimer?.cancel();
    });
    return FutureBuilder<String>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)
                          .editorOpenFailed("${snapshot.error}"),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final initialText = _mountOverride ?? snapshot.data ?? "";
        final isMarkdown = widget.tab.kind == EditorKind.markdown;
        _maybeOfferRecovery();

        return isMarkdown
            ? MarkdownEditorView(
                key: ValueKey("${widget.tab.path}#$_contentGen"),
                initialText: initialText,
                onChanged: _onChanged,
                bridge: _bridge,
                preview: _showPreview,
              )
            : ReEditorAdapter(
                key: ValueKey("${widget.tab.path}#$_contentGen"),
                initialText: initialText,
                language: widget.tab.language,
                onChanged: _onChanged,
                filePath: widget.tab.path,
                lspCompletion: _lspCompletionFor(),
                bridge: _bridge,
              );
      },
    );
  }
}
