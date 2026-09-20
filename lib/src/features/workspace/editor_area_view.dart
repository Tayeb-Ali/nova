import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../editor/editor_engine.dart";
import "../editor/re_editor_adapter.dart";
import "../markdown/markdown_editor_view.dart";
import "workspace_providers.dart";

/// Editor: tab strip + the active file edited with re_editor (task.md §35).
class EditorAreaView extends ConsumerWidget {
  const EditorAreaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(workspaceTabsProvider);
    final active = ref.watch(activeEditorTabModelProvider);
    final scheme = Theme.of(context).colorScheme;
    if (tabs.isEmpty || active == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 28, color: scheme.outline),
            const SizedBox(height: 8),
            Text(
              "Open a file from the explorer",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _TabStrip(tabs: tabs, activeId: active.id),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(child: _EditorTabBody(key: ValueKey(active.id), tab: active)),
      ],
    );
  }
}

class _TabStrip extends ConsumerWidget {
  final List<EditorTabModel> tabs;
  final String? activeId;

  const _TabStrip({required this.tabs, required this.activeId});

  void _close(WidgetRef ref, String id) {
    final wasActive = ref.read(activeEditorTabProvider) == id;
    ref.read(workspaceTabsProvider.notifier).close(id);
    if (wasActive) {
      final remaining = ref.read(workspaceTabsProvider);
      ref.read(activeEditorTabProvider.notifier).state =
          remaining.isEmpty ? null : remaining.last.id;
    }
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
                      child: Icon(Icons.circle,
                          size: 8, color: scheme.tertiary),
                    ),
                  Text(
                    p.basename(tab.path),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => _close(ref, tab.id),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 14, color: scheme.onSurfaceVariant),
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
    return Container(
      height: 48,
      color: scheme.surfaceContainerLow,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [for (final tab in tabs) _tabChip(context, ref, tab)],
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
  bool _showPreview = false;
  final TabContentBridge _bridge = TabContentBridge();

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant _EditorTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.path != widget.tab.path) {
      _loaded = false;
      _currentText = "";
      _savedText = "";
      _showPreview = false;
      _bridge.readContent = null;
      _loadFuture = _load();
    }
  }

  Future<String> _load() async {
    final service = ref.read(projectServiceProvider);
    try {
      final text = await service.readFile(widget.tab.path);
      _currentText = text;
      _savedText = text;
      _loaded = true;
      return text;
    } catch (_) {
      _currentText = "";
      _savedText = "";
      _loaded = true;
      return "";
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onChanged(String text) {
    _currentText = text;
    final dirty = _loaded && text != _savedText;
    ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, dirty);
  }

  Future<void> _save() async {
    final service = ref.read(projectServiceProvider);
    final text = _bridge.readContent?.call() ?? _currentText;
    try {
      await service.writeFile(widget.tab.path, text);
    } catch (e) {
      _toast("Save failed: $e");
      return;
    }
    _currentText = text;
    _savedText = text;
    ref.read(workspaceTabsProvider.notifier).markDirty(widget.tab.id, false);
    _toast("Saved ${p.basename(widget.tab.path)}");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Could not open file: ${snapshot.error}"));
        }
        final initialText = snapshot.data ?? "";
        final isMarkdown = widget.tab.kind == EditorKind.markdown;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              // Narrow panes (phone + explorer open) get an overflow menu
              // instead of inline buttons so the header never overflows.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 200;
                  return Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: widget.tab.path,
                          child: Text(
                            p.basename(widget.tab.path),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      if (widget.tab.dirty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.circle,
                              size: 8,
                              color: Theme.of(context).colorScheme.tertiary),
                        ),
                      if (isMarkdown && !compact)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: _loaded
                              ? () => setState(
                                  () => _showPreview = !_showPreview)
                              : null,
                          tooltip: _showPreview ? "Edit" : "Preview",
                          icon: Icon(
                            _showPreview
                                ? Icons.edit_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                        ),
                      if (compact)
                        PopupMenuButton<String>(
                          tooltip: "Tab actions",
                          icon: Icon(Icons.more_vert,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          onSelected: (value) {
                            if (value == "preview") {
                              setState(
                                  () => _showPreview = !_showPreview);
                            } else if (value == "save") {
                              _save();
                            }
                          },
                          itemBuilder: (context) => [
                            if (isMarkdown)
                              PopupMenuItem(
                                value: "preview",
                                child: Text(
                                    _showPreview ? "Edit" : "Preview"),
                              ),
                            const PopupMenuItem(
                              value: "save",
                              child: Text("Save"),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: _loaded ? _save : null,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text("Save"),
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: isMarkdown
                  ? MarkdownEditorView(
                      key: ValueKey(widget.tab.path),
                      initialText: initialText,
                      onChanged: _onChanged,
                      bridge: _bridge,
                      preview: _showPreview,
                    )
                  : ReEditorAdapter(
                      key: ValueKey(widget.tab.path),
                      initialText: initialText,
                      language: widget.tab.language,
                      onChanged: _onChanged,
                    ),
            ),
          ],
        );
      },
    );
  }
}