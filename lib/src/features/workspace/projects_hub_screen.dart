import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/bridge/generated/ide_api.g.dart" as bridge;
import "../../core/models/project.dart";
import "../../core/services/setup_service.dart";
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
  final _setupService = SetupService();
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _actionBusy = false;
  String _query = "";
  String? _languageFilter;
  bridge.SetupStatus? _setupStatus;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _init() async {
    await Future.wait([_loadProjects(), _loadSetupStatus()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadSetupStatus() async {
    try {
      final status = await _setupService.getStatus();
      if (!mounted) return;
      setState(() => _setupStatus = status);
    } catch (_) {
      // Leave _setupStatus null; the ribbon shows "unavailable".
    }
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

  Future<void> _newProject() async {
    final nameController = TextEditingController();
    var selectedLanguage = "php";
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("New project"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: "Project name"),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: "php",
                      label: Text("PHP"),
                      icon: Icon(Icons.language)),
                  ButtonSegment(
                      value: "node",
                      label: Text("Node"),
                      icon: Icon(Icons.integration_instructions)),
                  ButtonSegment(
                      value: "python",
                      label: Text("Python"),
                      icon: Icon(Icons.terminal)),
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
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop((name, selectedLanguage));
              },
              child: const Text("Create"),
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
      _toast("Create failed: $e");
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _deleteProject(ProjectInfo project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete project?"),
        content: Text("Delete '${project.name}' and all its files?"),
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
      _toast("Delete failed: $e");
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
    return Scaffold(
      appBar: AppBar(title: const Text("Projects")),
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
                    setupStatus: _setupStatus,
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
                    decoration: const InputDecoration(
                      hintText: "Search projects...",
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
                  Text("Recent projects",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (projects == null || projects.isEmpty)
                    _EmptyProjects(
                        colors: colors, onNewProject: _newProject)
                  else
                    ..._filtered(projects).map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ProjectCard(
                            colors: colors,
                            project: p,
                            isActive: active?.path == p.path,
                            onOpen: () =>
                                _selectProject(p, openEditor: true),
                            onDelete: () => _deleteProject(p),
                          ),
                        )),
                  const SizedBox(height: 12),
                  _TipsCard(colors: colors),
                ],
              ),
            ),
    );
  }
}

/// Top ribbon: bootstrap status + project count.
class _StatsRibbon extends StatelessWidget {
  const _StatsRibbon({
    required this.colors,
    required this.projectCount,
    required this.setupStatus,
  });

  final ColorScheme colors;
  final int projectCount;
  final bridge.SetupStatus? setupStatus;

  @override
  Widget build(BuildContext context) {
    final status = setupStatus;
    final String statusText;
    final IconData statusIcon;
    if (status == null) {
      statusText = "Runtime status unavailable";
      statusIcon = Icons.help_outline;
    } else if (status.error != null) {
      statusText = "Setup error: ${status.error}";
      statusIcon = Icons.error_outline;
    } else if (status.ready) {
      final version = status.bootstrapVersion;
      statusText =
          version == null ? "Runtime ready" : "Runtime ready ($version)";
      statusIcon = Icons.check_circle_outline;
    } else {
      statusText = "Runtime setup needed";
      statusIcon = Icons.download_outlined;
    }
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    "$projectCount project${projectCount == 1 ? "" : "s"}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
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
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _ActionTile(
          colors: colors,
          icon: Icons.create_new_folder,
          label: "New project",
          hint: "Start from a template",
          enabled: !busy,
          onTap: onNewProject,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.code,
          label: "Open editor",
          hint: "Continue working",
          enabled: canOpenEditor && !busy,
          onTap: onOpenEditor,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.refresh,
          label: "Refresh",
          hint: "Reload project list",
          enabled: !busy,
          onTap: onRefresh,
        ),
        _ActionTile(
          colors: colors,
          icon: Icons.delete_outline,
          label: "Delete project",
          hint: "Remove active project",
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
              Icon(icon,
                  color: enabled
                      ? colors.primary
                      : colors.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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
          label: Text("All (${projects.length})"),
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
            Text(project.path,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
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
          tooltip: "Delete project",
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
            Icon(Icons.folder_open,
                size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text("No projects yet",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onNewProject,
              icon: const Icon(Icons.create_new_folder),
              label: const Text("New project"),
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
                Text("Tips",
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Tap a project to open it in the editor. "
              "Use the Packages tab to install runtimes before "
              "creating Node or Python projects.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
