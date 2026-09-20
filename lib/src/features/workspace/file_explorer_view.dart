import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openTab(String path) {
    final id = ref.read(workspaceTabsProvider.notifier).open(path);
    ref.read(activeEditorTabProvider.notifier).state = id;
  }

  void _reload(String dir) {
    ref.invalidate(fileEntriesProvider(dir));
  }

  Future<void> _newFile() async {
    final l10n = AppLocalizations.of(context);
    final dir = ref.read(currentDirProvider);
    final project = ref.read(activeProjectProvider);
    if (dir == null || project == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.explorerNewFile),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g. main.py",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionCreate),
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
      _toast(l10n.commonCreateFailed("$e"));
      return;
    }
    _reload(dir);
    _openTab(path);
  }

  Future<void> _rename(FileEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final dir = ref.read(currentDirProvider);
    if (dir == null) return;
    final nameController = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.actionRename),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.explorerNewNameHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionRename),
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
      _toast(l10n.commonRenameFailed("$e"));
      return;
    }
    if (!ok) {
      _toast(l10n.commonRenameFailed(entry.name));
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
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.explorerDeleteTitle),
        content: Text(l10n.explorerDeleteMessage(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    bool deleted;
    try {
      deleted = await ref.read(projectServiceProvider).delete(entry.path);
    } catch (e) {
      _toast(l10n.commonDeleteFailed("$e"));
      return;
    }
    if (!deleted) {
      _toast(l10n.commonDeleteFailed(entry.name));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(
                "${AppLocalizations.of(context).actionRename} ${entry.name}",
              ),
              onTap: () {
                Navigator.of(context).pop();
                _rename(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                "${AppLocalizations.of(context).actionDelete} ${entry.name}",
              ),
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
            if (i > 0)
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () =>
                  ref.read(currentDirProvider.notifier).state = crumbs[i].$2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  i == 0 ? rootLabel : crumbs[i].$1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: "monospace",
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fileList(WidgetRef ref, String? dir) {
    if (dir == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).explorerSelectProject,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final files = ref.watch(fileEntriesProvider(dir));
    return files.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          AppLocalizations.of(context).commonError("$e"),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).explorerEmptyFolder,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                leading: Icon(
                  entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  size: 18,
                  color: entry.isDirectory
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  if (entry.isDirectory) {
                    ref.read(currentDirProvider.notifier).state = entry.path;
                  } else {
                    _openTab(entry.path);
                  }
                },
                onLongPress: () => _showEntryMenu(entry),
              ),
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
    final upEnabled =
        dir != null &&
        project != null &&
        p.normalize(dir) != p.normalize(project.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text(
            AppLocalizations.of(context).explorerTitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (dir != null && project != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: AppLocalizations.of(context).explorerGoUp,
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
                  onPressed: upEnabled
                      ? () => ref.read(currentDirProvider.notifier).state = p
                            .dirname(dir)
                      : null,
                ),
                Icon(
                  Icons.folder,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(child: _breadcrumb(ref, dir, project)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonalIcon(
            onPressed: _newFile,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).explorerNewFile),
          ),
        ),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(child: _fileList(ref, dir)),
      ],
    );
  }
}
