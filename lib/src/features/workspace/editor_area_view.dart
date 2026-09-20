import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../editor/editor_engine.dart";
import "../editor/re_editor_adapter.dart";
import "workspace_providers.dart";

/// Editor: tab strip + the active file edited with re_editor (task.md §35).
class EditorAreaView extends ConsumerWidget {
  const EditorAreaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(workspaceTabsProvider);
    final active = ref.watch(activeEditorTabModelProvider);
    if (tabs.isEmpty || active == null) {
      return Center(
        child: Text("Open a file from the explorer", style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Column(
      children: [
        _TabStrip(tabs: tabs, activeId: active.id),
        const Divider(height: 1),
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref.read(activeEditorTabProvider.notifier).state = tab.id,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.dirty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.circle, size: 8, color: scheme.tertiary),
              ),
            Text(p.basename(tab.path), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 2),
            InkWell(
              onTap: () => _close(ref, tab.id),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 40,
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
    try {
      await service.writeFile(widget.tab.path, _currentText);
    } catch (e) {
      _toast("Save failed: $e");
      return;
    }
    _savedText = _currentText;
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
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.tab.path,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (widget.tab.dirty)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.circle, size: 8),
                    ),
                  TextButton.icon(
                    onPressed: _loaded ? _save : null,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text("Save"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReEditorAdapter(
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