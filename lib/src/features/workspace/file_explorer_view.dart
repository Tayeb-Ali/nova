import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../../core/models/project.dart";
import "workspace_providers.dart";

/// File explorer for the active project, walking ProjectService.listFiles
/// and opening files in the editor (task.md §23).
class FileExplorerView extends ConsumerStatefulWidget {
  const FileExplorerView({super.key});

  @override
  ConsumerState<FileExplorerView> createState() => _FileExplorerViewState();
}

class _FileExplorerViewState extends ConsumerState<FileExplorerView> {
  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openTab(String path) {
    final id = ref.read(workspaceTabsProvider.notifier).open(path);
    ref.read(activeEditorTabProvider.notifier).state = id;
  }

  void _reload(String dir) {
    ref.invalidate(fileEntriesProvider(dir));
  }

  Future<void> _newFile() async {
    final dir = ref.read(currentDirProvider);
    final project = ref.read(activeProjectProvider);
    if (dir == null || project == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New file"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. main.py"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            child: const Text("Create"),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty) return;
    final path = p.join(dir, name);
    try {
      await ref.read(projectServiceProvider).writeFile(path, "");
    } catch (e) {
      _toast("Create failed: $e");
      return;
    }
    _reload(dir);
    _openTab(path);
  }

  Future<void> _rename(FileEntry entry) async {
    final dir = ref.read(currentDirProvider);
    if (dir == null) return;
    final nameController = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "New name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            child: const Text("Rename"),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (newName == null || newName.isEmpty || newName == entry.name) return;
    final newPath = p.join(dir, newName);
    bool ok;
    try {
      ok = await ref.read(projectServiceProvider).rename(entry.path, newPath);
    } catch (e) {
      _toast("Rename failed: $e");
      return;
    }
    if (!ok) {
      _toast("Rename failed");
      return;
    }
    _reload(dir);
    _renameOpenTabs(entry.path, newPath);
  }

  void _renameOpenTabs(String oldPath, String newPath) {
    final notifier = ref.read(workspaceTabsProvider.notifier);
    final tabs = ref.read(workspaceTabsProvider);
    var wasActive = false;
    for (final t in tabs) {
      if (t.id == oldPath) {
        notifier.rename(oldPath, newPath);
        wasActive = ref.read(activeEditorTabProvider) == oldPath;
      }
    }
    if (wasActive) {
      ref.read(activeEditorTabProvider.notifier).state = newPath;
    }
  }

  Future<void> _confirmDelete(FileEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete?"),
        content: Text("Delete ${entry.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (ok != true) return;
    bool deleted;
    try {
      deleted = await ref.read(projectServiceProvider).delete(entry.path);
    } catch (e) {
      _toast("Delete failed: $e");
      return;
    }
    if (!deleted) {
      _toast("Delete failed");
      return;
    }
    final dir = ref.read(currentDirProvider);
    if (dir != null) _reload(dir);
    if (ref.read(workspaceTabsProvider).any((t) => t.id == entry.path)) {
      ref.read(workspaceTabsProvider.notifier).close(entry.path);
      if (ref.read(activeEditorTabProvider) == entry.path) {
        ref.read(activeEditorTabProvider.notifier).state = null;
      }
    }
  }

  void _showEntryMenu(FileEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text("Rename ${entry.name}"),
              onTap: () {
                Navigator.of(context).pop();
                _rename(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text("Delete ${entry.name}"),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _crumbs(String dir, String root) {
    var current = p.normalize(dir);
    final rootNorm = p.normalize(root);
    final crumbs = <(String, String)>[];
    while (true) {
      crumbs.insert(0, (p.basename(current), current));
      if (current == rootNorm) break;
      final parent = p.dirname(current);
      if (parent == current) break;
      current = parent;
    }
    return crumbs;
  }

  Widget _breadcrumb(WidgetRef ref, String dir, ProjectInfo project) {
    final rootLabel = project.name;
    final crumbs = _crumbs(dir, project.path);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0) const Icon(Icons.chevron_right, size: 14),
            InkWell(
              onTap: () =>
                  ref.read(currentDirProvider.notifier).state = crumbs[i].$2,
              child: Text(
                i == 0 ? rootLabel : crumbs[i].$1,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fileList(WidgetRef ref, String? dir) {
    if (dir == null) {
      return const Center(child: Text("Select a project"));
    }
    final files = ref.watch(fileEntriesProvider(dir));
    return files.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text("Empty folder"));
        }
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return ListTile(
              dense: true,
              leading: Icon(
                entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
              ),
              title: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                if (entry.isDirectory) {
                  ref.read(currentDirProvider.notifier).state = entry.path;
                } else {
                  _openTab(entry.path);
                }
              },
              onLongPress: () => _showEntryMenu(entry),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dir = ref.watch(currentDirProvider);
    final project = ref.watch(activeProjectProvider);
    final upEnabled = dir != null && project != null &&
        p.normalize(dir) != p.normalize(project.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Text(
            "EXPLORER",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        if (dir != null && project != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: "Go up",
                  visualDensity: VisualDensity.compact,
                  onPressed: upEnabled
                      ? () => ref.read(currentDirProvider.notifier).state =
                          p.dirname(dir)
                      : null,
                ),
                const Icon(Icons.folder, size: 16),
                const SizedBox(width: 4),
                Expanded(child: _breadcrumb(ref, dir, project)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonalIcon(
            onPressed: _newFile,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("New file"),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _fileList(ref, dir)),
      ],
    );
  }
}