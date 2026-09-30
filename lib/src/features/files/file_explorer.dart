import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../../core/ui/text_prompt_dialog.dart";
import "../../../l10n/generated/app_localizations.dart";
import "files_providers.dart";

/// Drawer with workspace root picker, file list, and new/delete actions.
class FileExplorer extends ConsumerStatefulWidget {
  const FileExplorer({super.key});

  @override
  ConsumerState<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends ConsumerState<FileExplorer> {
  late final TextEditingController _rootController;
  Directory? _currentDir;

  @override
  void initState() {
    super.initState();
    _rootController = TextEditingController();
    final root = ref.read(rootDirProvider);
    if (root != null) {
      _currentDir = root;
      _rootController.text = root.path;
    } else {
      ref.read(appRootProvider.future).then((dir) {
        if (!mounted) return;
        ref.read(rootDirProvider.notifier).state = dir;
        setState(() {
          _currentDir = dir;
          _rootController.text = dir.path;
        });
      });
    }
  }

  void _showFsError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Storage not writable here: $e")));
  }

  @override
  void dispose() {
    _rootController.dispose();
    super.dispose();
  }

  void _applyRoot() {
    final path = _rootController.text.trim();
    if (path.isEmpty) return;
    final dir = Directory(path);
    ref.read(rootDirProvider.notifier).state = dir;
    setState(() => _currentDir = dir);
    // ignore: unused_result
    ref.refresh(fileListProvider(dir));
  }

  void _openFile(String filePath) {
    final id = ref.read(openTabsProvider.notifier).open(filePath);
    ref.read(activeTabProvider.notifier).state = id;
    Navigator.of(context).maybePop();
  }

  Future<void> _confirmDelete(FileSystemEntity entity) async {
    final name = p.basename(entity.path);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).explorerDeleteTitle),
        content: Text(
          AppLocalizations.of(context).explorerDeleteMessage(name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(fileServiceProvider).delete(entity);
    } catch (e) {
      _showFsError(e);
      return;
    }
    final dir = _currentDir;
    if (dir != null) {
      // ignore: unused_result
      ref.refresh(fileListProvider(dir));
    }
  }

  Future<void> _promptNewFile() async {
    final l10n = AppLocalizations.of(context);
    final name = await showTextPromptDialog(
      context: context,
      title: l10n.explorerNewFile,
      hintText: "e.g. main.py",
      confirmLabel: l10n.actionCreate,
      cancelLabel: l10n.actionCancel,
    );
    if (name == null || name.isEmpty) return;
    final dir = _currentDir;
    if (dir == null) return;
    late final File file;
    try {
      file = await ref
          .read(fileServiceProvider)
          .createFile(p.join(dir.path, name));
    } catch (e) {
      _showFsError(e);
      return;
    }
    // ignore: unused_result
    ref.refresh(fileListProvider(dir));
    _openFile(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final dir = _currentDir;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).workspaceTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rootController,
                          decoration: const InputDecoration(
                            hintText: "/sdcard/Nova",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _applyRoot(),
                        ),
                      ),
                      IconButton(
                        onPressed: _applyRoot,
                        icon: const Icon(Icons.folder_open),
                        tooltip: AppLocalizations.of(
                          context,
                        ).projectsOpenFolder,
                      ),
                    ],
                  ),
                  if (dir != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dir.path,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (dir != null &&
                _rootController.text.trim() != dir.path &&
                dir.parent.path != dir.path)
              ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_upward),
                title: const Text(".."),
                onTap: () {
                  setState(() => _currentDir = dir.parent);
                },
              ),
            Expanded(
              child: dir == null
                  ? const Center(child: Text("No folder selected"))
                  : Consumer(
                      builder: (context, ref, _) {
                        final files = ref.watch(fileListProvider(dir));
                        return files.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text(
                              AppLocalizations.of(context).commonError("$e"),
                            ),
                          ),
                          data: (entries) {
                            if (entries.isEmpty) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).explorerEmptyFolder,
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (context, i) {
                                final entity = entries[i];
                                final isDir = entity is Directory;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isDir
                                        ? Icons.folder
                                        : Icons.insert_drive_file,
                                  ),
                                  title: Text(
                                    p.basename(entity.path),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    if (isDir) {
                                      setState(
                                        () => _currentDir = Directory(
                                          entity.path,
                                        ),
                                      );
                                    } else {
                                      _openFile(entity.path);
                                    }
                                  },
                                  onLongPress: () => _confirmDelete(entity),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: _promptNewFile,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).explorerNewFile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
