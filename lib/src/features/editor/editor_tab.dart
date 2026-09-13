import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../editor/editor_engine.dart";
import "../files/files_providers.dart";
import "re_editor_adapter.dart";

/// Shows one open file: loads it, edits it, saves it.
class EditorTab extends ConsumerStatefulWidget {
  final EditorTabModel tab;

  const EditorTab({super.key, required this.tab});

  @override
  ConsumerState<EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends ConsumerState<EditorTab> {
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
  void didUpdateWidget(covariant EditorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.path != widget.tab.path) {
      _loaded = false;
      _currentText = "";
      _savedText = "";
      _loadFuture = _load();
    }
  }

  Future<String> _load() async {
    final service = ref.read(fileServiceProvider);
    try {
      final text = await service.readFile(File(widget.tab.path));
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

  void _onChanged(String text) {
    _currentText = text;
    final dirty = text != _savedText;
    if (dirty != widget.tab.dirty) {
      ref.read(openTabsProvider.notifier).markDirty(widget.tab.id, dirty);
    }
  }

  Future<void> _save() async {
    final service = ref.read(fileServiceProvider);
    try {
      await service.writeFile(File(widget.tab.path), _currentText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e")),
        );
      }
      return;
    }
    _savedText = _currentText;
    ref.read(openTabsProvider.notifier).markDirty(widget.tab.id, false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved ${p.basename(widget.tab.path)}")),
      );
    }
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
          return Center(
            child: Text("Could not open file: ${snapshot.error}"),
          );
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