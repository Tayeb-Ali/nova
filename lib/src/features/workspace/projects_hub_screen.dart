import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";

import "../../core/models/project.dart";
import "workspace_providers.dart";

/// Projects hub: stats ribbon + quick actions + searchable project list.
///
/// Reuses the same providers and service calls as [WorkspaceScreen]
/// ([projectServiceProvider], [projectsProvider], [activeProjectProvider]).
/// Task detection is intentionally left to the editor tab: selecting a
/// project here clears the run-task state so the editor never shows
/// another project's tasks.
class ProjectsHubScreen extends ConsumerStatefulWidget {
  const ProjectsHubScreen({super.key, required this.onOpenEditor});

  /// Switches the [IdeShell] to the editor tab.
  final VoidCallback onOpenEditor;

  @override
  ConsumerState<ProjectsHubScreen> createState() => _ProjectsHubScreenState();
}

class _ProjectsHubScreenState extends ConsumerState<ProjectsHubScreen> {
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _actionBusy = false;
  String _query = "";
  String? _languageFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _init() async {
    await Future.wait([_loadProjects(), _loadRecentFiles()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadProjects({ProjectInfo? select}) async {
    List<ProjectInfo> projects;
    try {
      projects = await ref.read(projectServiceProvider).listProjects();
    } catch (_) {
      projects = const [];
    }
    ref.read(projectsProvider.notifier).state = projects;
    ProjectInfo? target;
    if (select != null) {
      for (final p in projects) {
        if (p.path == select.path) {
          target = p;
          break;
        }
      }
    }
    target ??= (projects.isNotEmpty ? projects.first : null);
    if (target == null) {
      ref.read(activeProjectProvider.notifier).state = null;
      ref.read(currentDirProvider.notifier).state = null;
    } else {
      _selectProject(target);
    }
  }

  Future<void> _loadRecentFiles() async {
    final stored = await loadRecentFiles();
    if (!mounted) return;
    ref.read(recentFilesProvider.notifier).state = stored;
  }

  void _selectProject(ProjectInfo project, {bool openEditor = false}) {
    final current = ref.read(activeProjectProvider);
    if (current == null || current.path != project.path) {
      ref.read(projectServiceProvider).openProject(project.path);
      ref.read(activeProjectProvider.notifier).state = project;
      ref.read(currentDirProvider.notifier).state = project.path;
      ref.read(workspaceTabsProvider.notifier).closeAll();
      ref.read(activeEditorTabProvider.notifier).state = null;
      ref.read(runOutputProvider.notifier).clear();
      ref.read(runningPidProvider.notifier).state = null;
      // Task detection runs in the editor tab; clear stale tasks so the
      // run panel never shows another project's tasks.
      ref.read(runTasksProvider.notifier).state = const [];
      ref.read(runTaskProvider.notifier).state = null;
    }
    if (openEditor) widget.onOpenEditor();
  }

  void _openRecentFile(String path) {
    // Keep the workspace project in sync when the file belongs to a
    // known project, reusing the existing select flow (which resets
    // tabs/run state on project switch), then open the tab.
    final projects = ref.read(projectsProvider);
    if (projects != null) {
      ProjectInfo? owner;
      for (final p in projects) {
        final root = p.path.endsWith("/") || p.path.endsWith("\\")
            ? p.path.substring(0, p.path.length - 1)
            : p.path;
        if (path == root ||
            path.startsWith("$root/") ||
            path.startsWith("$root\\")) {
          if (owner == null || root.length > owner.path.length) owner = p;
        }
      }
      if (owner != null) _selectProject(owner);
    }
    final id = ref.read(workspaceTabsProvider.notifier).open(path);
    ref.read(activeEditorTabProvider.notifier).state = id;
    widget.onOpenEditor();
  }

  Future<void> _newProject() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    var selectedLanguage = "php";
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.projectsNewProject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.projectsProjectNameHint,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: "php",
                    label: Text("PHP"),
                    icon: Icon(Icons.language),
                  ),
                  ButtonSegment(
                    value: "node",
                    label: Text("Node"),
                    icon: Icon(Icons.integration_instructions),
                  ),
                  ButtonSegment(
                    value: "python",
                    label: Text("Python"),
                    icon: Icon(Icons.terminal),
                  ),
                ],
                selected: {selectedLanguage},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setDialogState(() => selectedLanguage = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop((name, selectedLanguage));
              },
              child: Text(l10n.actionCreate),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;
    setState(() => _actionBusy = true);
    try {
      final created = await ref
          .read(projectServiceProvider)
          .createProject(result.$1, result.$2);
      await _loadProjects(select: created);
    } catch (e) {
      _toast(l10n.commonCreateFailed("$e"));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _deleteProject(ProjectInfo project) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectsDeleteTitle),
        content: Text(l10n.projectsDeleteMessage(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final pid = ref.read(runningPidProvider);
    if (pid != null) {
      try {
        await ref.read(processServiceProvider).kill(pid);
      } catch (_) {
        // Ignore: process may already be gone.
      }
      ref.read(runningPidProvider.notifier).state = null;
    }
    setState(() => _actionBusy = true);
    try {
      await ref.read(projectServiceProvider).deleteProject(project.path);
    } catch (e) {
      _toast(l10n.commonDeleteFailed("$e"));
      return;
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
    await _loadProjects();
  }

  List<ProjectInfo> _filtered(List<ProjectInfo> projects) {
    return [
      for (final p in projects)
        if ((_languageFilter == null || p.language == _languageFilter) &&
            (_query.isEmpty || p.name.toLowerCase().contains(_query)))
          p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final projects = ref.watch(projectsProvider);
    final active = ref.watch(activeProjectProvider);
    final recentFiles = ref.watch(recentFilesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navProjects)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadProjects(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsRibbon(
                    colors: colors,
                    projectCount: projects?.length ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _HubActions(
                    colors: colors,
                    busy: _actionBusy,
                    canOpenEditor: active != null,
                    onNewProject: _newProject,
                    onOpenEditor: active == null
                        ? null
                        : () => _selectProject(active, openEditor: true),
                    onRefresh: () => _loadProjects(),
                    onDelete: active == null
                        ? null
                        : () => _deleteProject(active),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).projectsSearchHint,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LanguageChips(
                    projects: projects ?? const [],
                    selected: _languageFilter,
                    onSelected: (language) =>
                        setState(() => _languageFilter = language),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).projectsRecentProjects,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (projects == null || projects.isEmpty)
                    _EmptyProjects(colors: colors, onNewProject: _newProject)
                  else
                    ..._filtered(projects).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ProjectCard(
                          colors: colors,
                          project: p,
                          isActive: active?.path == p.path,
                          onOpen: () => _selectProject(p, openEditor: true),
                          onDelete: () => _deleteProject(p),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (recentFiles.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context).projectsRecentFiles,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _RecentFilesCard(
                      colors: colors,
                      files: recentFiles,
                      onOpen: _openRecentFile,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _TipsCard(colors: colors),
                ],
              ),
            ),
    );
  }
}

/// Top ribbon: project count (bootstrap state lives on the runtime screen).
class _StatsRibbon extends StatelessWidget {
  const _StatsRibbon({required this.colors, required this.projectCount});

  final ColorScheme colors;
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.folder_open, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.projectsCount(projectCount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2x2 grid of hub actions, all wired to real project service calls.
class _HubActions extends StatelessWidget {
  const _HubActions({
    required this.colors,
    required this.busy,
    required this.canOpenEditor,
    required this.onNewProject,
    required this.onOpenEditor,
    required this.onRefresh,
    required this.onDelete,
  });

  final ColorScheme colors;
  final bool busy;
  final bool canOpenEditor;
  final VoidCallback onNewProject;
  final VoidCallback? onOpenEditor;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;

  @override
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.45,
      children: [
        _ActionTile(
          colors: colors,
          icon: Icons.create_new_folder,
          label: l10n.projectsNewProject,
          hint: l10n.projectsHintTemplate,
          enabled: !busy,
          onTap: onNewProject,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.code,
          label: l10n.projectsOpenEditor,
          hint: l10n.projectsHintContinue,
          enabled: canOpenEditor && !busy,
          onTap: onOpenEditor,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.refresh,
          label: l10n.actionRefresh,
          hint: l10n.projectsHintReload,
          enabled: !busy,
          onTap: onRefresh,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.delete_outline,
          label: l10n.projectsDeleteProject,
          hint: l10n.projectsHintRemoveActive,
          enabled: canOpenEditor && !busy,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onTap,
  });

  final ColorScheme colors;
  final IconData icon;
  final String label;
  final String hint;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chips: All + one chip per language present in the project list.
class _LanguageChips extends StatelessWidget {
  const _LanguageChips({
    required this.projects,
    required this.selected,
    required this.onSelected,
  });

  final List<ProjectInfo> projects;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languages = <String>[];
    for (final p in projects) {
      final language = p.language;
      if (language != null &&
          language.isNotEmpty &&
          !languages.contains(language)) {
        languages.add(language);
      }
    }
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.projectsFilterAll(projects.length)),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final language in languages)
          ChoiceChip(
            label: Text(language),
            selected: selected == language,
            onSelected: (_) => onSelected(language),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.colors,
    required this.project,
    required this.isActive,
    required this.onOpen,
    required this.onDelete,
  });

  final ColorScheme colors;
  final ProjectInfo project;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActive ? colors.primaryContainer : null,
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(project.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.path,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (project.language != null && project.language!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(project.language!),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: AppLocalizations.of(context).projectsDeleteProject,
          onPressed: onDelete,
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.colors, required this.onNewProject});

  final ColorScheme colors;
  final VoidCallback onNewProject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).projectsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onNewProject,
              icon: const Icon(Icons.create_new_folder),
              label: Text(AppLocalizations.of(context).projectsNewProject),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).projectsTipsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).projectsTipsBody,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent-files card below recent projects. Same card language:
/// surfaceContainer, 12px radius, 1px outlineVariant border.
/// Hidden entirely when the list is empty.
class _RecentFilesCard extends StatelessWidget {
  const _RecentFilesCard({
    required this.colors,
    required this.files,
    required this.onOpen,
  });

  final ColorScheme colors;
  final List<String> files;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < files.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.outlineVariant),
            ListTile(
              leading: Icon(_iconForPath(files[i]), color: colors.primary),
              title: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _fileName(files[i]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              subtitle: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _parentDir(files[i]),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              onTap: () => onOpen(files[i]),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _iconForPath(String path) {
  final slash = path.lastIndexOf("/");
  final backslash = path.lastIndexOf("\\");
  final sep = slash > backslash ? slash : backslash;
  final dot = path.lastIndexOf(".");
  if (dot < 0 || dot < sep || dot == path.length - 1) {
    return Icons.description_outlined;
  }
  switch (path.substring(dot + 1).toLowerCase()) {
    case "dart":
    case "java":
    case "kt":
    case "kts":
    case "swift":
    case "py":
    case "js":
    case "ts":
    case "jsx":
    case "tsx":
    case "php":
    case "rb":
    case "go":
    case "rs":
    case "c":
    case "h":
    case "cpp":
    case "cs":
      return Icons.code;
    case "md":
    case "markdown":
    case "mdown":
    case "txt":
      return Icons.article_outlined;
    case "json":
    case "yaml":
    case "yml":
    case "xml":
      return Icons.data_object;
    case "png":
    case "jpg":
    case "jpeg":
    case "gif":
    case "webp":
    case "svg":
      return Icons.image_outlined;
    case "pdf":
      return Icons.picture_as_pdf_outlined;
    case "zip":
    case "tar":
    case "gz":
    case "deb":
    case "apk":
      return Icons.archive_outlined;
    default:
      return Icons.description_outlined;
  }
}

String _fileName(String path) {
  final slash = path.lastIndexOf("/");
  final backslash = path.lastIndexOf("\\");
  final sep = slash > backslash ? slash : backslash;
  return sep < 0 ? path : path.substring(sep + 1);
}

String _parentDir(String path) {
  final slash = path.lastIndexOf("/");
  final backslash = path.lastIndexOf("\\");
  final sep = slash > backslash ? slash : backslash;
  return sep <= 0 ? path : path.substring(0, sep);
}
