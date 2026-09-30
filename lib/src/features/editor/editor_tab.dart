import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;
import "package:re_editor/re_editor.dart";

import "../editor/editor_engine.dart";
import "../files/files_providers.dart";
import "re_editor_adapter.dart";

/// Shows one open file: loads it, edits it, saves it.
class EditorTab extends ConsumerStatefulWidget {
  final EditorTabModel tab;

  /// 0-based line to jump to on mount (e.g. from project search results).
  final int? initialLine;

  const EditorTab({super.key, required this.tab, this.initialLine});

  @override
  ConsumerState<EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends ConsumerState<EditorTab> {
  Future<String>? _loadFuture;
  String _currentText = "";
  String _savedText = "";
  bool _loaded = false;
  bool _showFind = false;
  CodeFindController? _findController;

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
      _showFind = false;
      _findController = null;
      _loadFuture = _load();
    }
  }

  void _onFindControllerReady(CodeFindController controller) {
    if (mounted) setState(() => _findController = controller);
  }

  /// Toggle the in-file find bar. Opening it calls `findMode()` so the
  /// re_editor search state initializes (typing alone is not enough);
  /// closing it calls `close()` to clear highlights.
  void _toggleFind() {
    final controller = _findController;
    if (_showFind) {
      controller?.close();
      if (mounted) setState(() => _showFind = false);
    } else {
      if (mounted) setState(() => _showFind = true);
      controller?.findMode();
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
                  IconButton(
                    onPressed: _loaded ? _toggleFind : null,
                    tooltip: "Find in file",
                    icon: const Icon(Icons.search, size: 18),
                  ),
                  TextButton.icon(
                    onPressed: _loaded ? _save : null,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text("Save"),
                  ),
                ],
              ),
            ),
            if (_showFind && _findController != null)
              _InFileFindBar(
                controller: _findController!,
                onClose: _toggleFind,
              ),
            Expanded(
              child: ReEditorAdapter(
                key: ValueKey(widget.tab.path),
                initialText: initialText,
                language: widget.tab.language,
                onChanged: _onChanged,
                initialLine: widget.initialLine,
                onFindControllerReady: _onFindControllerReady,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact find bar bound to a re_editor [CodeFindController].
///
/// Typing in the field drives `findInputController` (search + highlight are
/// handled by re_editor); the arrows step through matches and the toggles
/// switch case-sensitivity / regex.
class _InFileFindBar extends StatelessWidget {
  final CodeFindController controller;
  final VoidCallback onClose;

  const _InFileFindBar({required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: ValueListenableBuilder<CodeFindValue?>(
        valueListenable: controller,
        builder: (context, value, _) {
          final result = value?.result;
          final searching = value?.searching ?? false;
          final countLabel = result == null
              ? (searching ? "…" : "0/0")
              : "${result.index + 1}/${result.matches.length}";
          final option = value?.option;
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.findInputController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Find",
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  onSubmitted: (_) => controller.nextMatch(),
                ),
              ),
              const SizedBox(width: 4),
              Text(countLabel, style: Theme.of(context).textTheme.bodySmall),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: "Previous match",
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                onPressed: result == null ? null : controller.previousMatch,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: "Next match",
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                onPressed: result == null ? null : controller.nextMatch,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: "Match case",
                isSelected: option?.caseSensitive ?? false,
                selectedIcon: Icon(
                  Icons.abc,
                  size: 18,
                  color: scheme.primary,
                ),
                icon: const Icon(Icons.abc, size: 18),
                onPressed: controller.toggleCaseSensitive,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: "Use regular expression",
                isSelected: option?.regex ?? false,
                selectedIcon: Icon(
                  Icons.star,
                  size: 18,
                  color: scheme.primary,
                ),
                icon: const Text(
                  ".*",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: controller.toggleRegex,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: "Close find bar",
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          );
        },
      ),
    );
  }
}