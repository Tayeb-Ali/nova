import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models/project.dart";
import "../editor/theme/theme_pack_store.dart";
import "workspace_providers.dart";

/// Command palette: fuzzy-ish file + command search for the workspace.
///
/// Shows open tabs first, then project files (top level + one depth, capped
/// to stay cheap), then static tool/theme commands. Selecting a file opens it
/// with the same call sequence the explorer uses; selecting a command runs it
/// and closes the dialog.
Future<void> showCommandPalette(
  BuildContext context,
  WidgetRef ref, {
  ValueChanged<int>? onOpenTool,
  ValueChanged<String>? onGoToTab,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CommandPaletteDialog(
      onOpenTool: onOpenTool,
      onGoToTab: onGoToTab,
    ),
  );
}

enum _EntryKind { openTab, projectFile, command }

class _PaletteEntry {
  const _PaletteEntry({
    required this.kind,
    required this.title,
    this.subtitle,
    this.icon,
    this.filePath,
    this.toolIndex,
    this.commandId,
  });

  final _EntryKind kind;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? filePath;
  final int? toolIndex;
  final String? commandId;
}

class _CommandPaletteDialog extends ConsumerStatefulWidget {
  const _CommandPaletteDialog({this.onOpenTool, this.onGoToTab});

  final ValueChanged<int>? onOpenTool;
  final ValueChanged<String>? onGoToTab;

  @override
  ConsumerState<_CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState
    extends ConsumerState<_CommandPaletteDialog> {
  static const _maxDirs = 20;
  static const _maxFiles = 200;

  final _controller = TextEditingController();
  var _query = "";
  var _loadingFiles = true;
  var _files = const <FileEntry>[];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Top-level entries plus one directory depth, capped. listFiles is
  /// non-recursive, so a second level keeps the palette useful without
  /// walking the whole tree.
  Future<void> _loadFiles() async {
    final project = ref.read(activeProjectProvider);
    if (project == null) {
      if (mounted) setState(() => _loadingFiles = false);
      return;
    }
    final service = ref.read(projectServiceProvider);
    try {
      final top = await service.listFiles(project.path);
      final collected = <FileEntry>[];
      final dirs = <FileEntry>[];
      for (final entry in top) {
        if (!entry.isDirectory) collected.add(entry);
        if (entry.isDirectory && dirs.length < _maxDirs) dirs.add(entry);
      }
      for (final dir in dirs) {
        if (collected.length >= _maxFiles) break;
        try {
          final children = await service.listFiles(dir.path);
          for (final child in children) {
            if (collected.length >= _maxFiles) break;
            collected.add(child);
          }
        } catch (_) {
          // Skip unreadable subdirectories.
        }
      }
      if (!mounted) return;
      setState(() {
        _files = List.unmodifiable(collected);
        _loadingFiles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFiles = false);
    }
  }

  void _openFile(String path) {
    final id = ref.read(workspaceTabsProvider.notifier).open(path);
    ref.read(activeEditorTabProvider.notifier).state = id;
  }

  Future<void> _cycleTheme() async {
    final brightness = Theme.of(context).brightness;
    final store = ref.read(editorThemeStoreProvider.notifier);
    final packs =
        store.allPacks.where((p) => p.brightness == brightness).toList();
    if (packs.isEmpty) return;
    final currentId = store.packFor(brightness).id;
    final index = packs.indexWhere((p) => p.id == currentId);
    final next = packs[(index + 1) % packs.length];
    await store.setPackFor(brightness, next.id);
  }

  List<_PaletteEntry> _commands() {
    final entries = <_PaletteEntry>[];
    final onOpenTool = widget.onOpenTool;
    if (onOpenTool != null) {
      entries.addAll(const [
        _PaletteEntry(
          kind: _EntryKind.command,
          title: "Toggle Run panel",
          icon: Icons.play_arrow,
          toolIndex: 0,
        ),
        _PaletteEntry(
          kind: _EntryKind.command,
          title: "Toggle Terminal",
          icon: Icons.terminal,
          toolIndex: 1,
        ),
        _PaletteEntry(
          kind: _EntryKind.command,
          title: "Toggle Git panel",
          icon: Icons.account_tree,
          toolIndex: 2,
        ),
        _PaletteEntry(
          kind: _EntryKind.command,
          title: "Toggle Processes panel",
          icon: Icons.settings_input_component_outlined,
          toolIndex: 3,
        ),
      ]);
    }
    entries.add(
      const _PaletteEntry(
        kind: _EntryKind.command,
        title: "Switch editor theme",
        icon: Icons.palette_outlined,
        commandId: "cycle-theme",
      ),
    );
    final onGoToTab = widget.onGoToTab;
    if (onGoToTab != null) {
      entries.add(
        const _PaletteEntry(
          kind: _EntryKind.command,
          title: "Open settings",
          icon: Icons.settings_outlined,
          commandId: "open-settings",
        ),
      );
    }
    return entries;
  }

  List<_PaletteEntry> _filtered() {
    final tabs = ref.watch(workspaceTabsProvider);
    final q = _query.trim().toLowerCase();
    bool matches(String haystack) =>
        q.isEmpty || haystack.toLowerCase().contains(q);

    final results = <_PaletteEntry>[];
    for (final tab in tabs) {
      if (matches("${tab.path} ${tab.language}")) {
        results.add(
          _PaletteEntry(
            kind: _EntryKind.openTab,
            title: tab.path.split("/").last,
            subtitle: tab.path,
            icon: Icons.history,
            filePath: tab.path,
          ),
        );
      }
    }
    final openPaths = tabs.map((t) => t.path).toSet();
    for (final file in _files) {
      if (file.isDirectory) continue;
      if (openPaths.contains(file.path)) continue;
      if (matches("${file.path} ${file.name}")) {
        results.add(
          _PaletteEntry(
            kind: _EntryKind.projectFile,
            title: file.name,
            subtitle: file.path,
            icon: Icons.insert_drive_file,
            filePath: file.path,
          ),
        );
      }
    }
    for (final command in _commands()) {
      if (matches(command.title)) results.add(command);
    }
    return results;
  }

  Future<void> _activate(_PaletteEntry entry) async {
    switch (entry.kind) {
      case _EntryKind.openTab:
      case _EntryKind.projectFile:
        final path = entry.filePath;
        if (path == null) return;
        _openFile(path);
        if (mounted) Navigator.of(context).pop();
      case _EntryKind.command:
        if (entry.toolIndex != null) {
          final index = entry.toolIndex!;
          if (mounted) Navigator.of(context).pop();
          widget.onOpenTool?.call(index);
        } else if (entry.commandId == "cycle-theme") {
          if (mounted) Navigator.of(context).pop();
          await _cycleTheme();
        } else if (entry.commandId == "open-settings") {
          if (mounted) Navigator.of(context).pop();
          widget.onGoToTab?.call("settings");
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Type a command or file name…",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (_) {
                  if (results.isNotEmpty) _activate(results.first);
                },
              ),
              const SizedBox(height: 8),
              if (_loadingFiles) const LinearProgressIndicator(minHeight: 2),
              Flexible(
                child: results.isEmpty && !_loadingFiles
                    ? const Center(child: Text("No matches"))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final entry = results[i];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(entry.icon, size: 18),
                            title: Text(
                              entry.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: entry.subtitle == null
                                ? null
                                : Text(
                                    entry.subtitle!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: "monospace",
                                    ),
                                  ),
                            onTap: () => _activate(entry),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
