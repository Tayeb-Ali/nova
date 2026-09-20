import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/models/project.dart";
import "../git/git_screen.dart";
import "../process/process_screen.dart";
import "../terminal/terminal_screen.dart";
import "editor_area_view.dart";
import "command_palette.dart";
import "file_explorer_view.dart";
import "run_panel.dart";
import "task_detector.dart";
import "workspace_providers.dart";

/// Workspace: project selector + file explorer + editor + run (task.md §35).
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  bool _initialLoading = true;
  bool _explorerVisible = true;
  bool _appBarCollapsed = false;

  // Bottom tool drawer tab: 0 Run, 1 Terminal, 2 Git, 3 Processes, -1 hidden.
  // Only the selected tool is inserted so sessions start lazily on first open.
  int _toolIndex = 0;

  static const _toolIcons = [
    Icons.play_arrow,
    Icons.terminal,
    Icons.account_tree,
    Icons.settings_input_component_outlined,
  ];

  // Tab labels follow the app locale (rebuilt via NovaApp on locale change).
  List<String> _toolLabels(AppLocalizations l10n) => [
        l10n.actionRun,
        l10n.toolTerminal,
        l10n.toolGit,
        l10n.toolProcesses,
      ];

  Widget _toolDrawer(BuildContext context, ColorScheme scheme) {
    final l10n = AppLocalizations.of(context);
    final labels = _toolLabels(l10n);
    final decoration = BoxDecoration(
      color: scheme.surfaceContainerLow,
      border: Border(top: BorderSide(color: scheme.outlineVariant)),
    );
    // Collapsed: slim 24px grabber bar only, tappable to reopen.
    if (_toolIndex == -1) {
      return Container(
        decoration: decoration,
        child: InkWell(
          onTap: () => setState(() => _toolIndex = 0),
          child: SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _toolIndex = 0),
                  tooltip: l10n.toolsShow,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  icon: const Icon(Icons.expand_less, size: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: decoration,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < labels.length; i++)
                            TextButton.icon(
                              onPressed: () => setState(
                                () => _toolIndex = _toolIndex == i ? -1 : i,
                              ),
                              icon: Icon(_toolIcons[i], size: 16),
                              label: Text(labels[i]),
                              style: TextButton.styleFrom(
                                foregroundColor: _toolIndex == i
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 40),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _toolIndex = -1),
                    tooltip: l10n.toolsHide,
                    icon: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
            if (_toolIndex == 0) const RunPanel(),
            if (_toolIndex == 1)
              const SizedBox(height: 320, child: TerminalScreen()),
            if (_toolIndex == 2)
              const SizedBox(height: 320, child: GitScreen()),
            if (_toolIndex == 3)
              const SizedBox(height: 320, child: ProcessScreen()),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _init() async {
    await _loadProjects();
    if (!mounted) return;
    setState(() => _initialLoading = false);
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

  void _selectProject(ProjectInfo project) {
    final current = ref.read(activeProjectProvider);
    if (current != null && current.path == project.path) {
      if (!identical(current, project)) {
        ref.read(activeProjectProvider.notifier).state = project;
      }
      return;
    }
    ref.read(projectServiceProvider).openProject(project.path);
    ref.read(activeProjectProvider.notifier).state = project;
    ref.read(currentDirProvider.notifier).state = project.path;
    ref.read(workspaceTabsProvider.notifier).closeAll();
    ref.read(activeEditorTabProvider.notifier).state = null;
    ref.read(runOutputProvider.notifier).clear();
    ref.read(runningPidProvider.notifier).state = null;
    _refreshTasks(project);
  }

  Future<void> _refreshTasks(ProjectInfo project) async {
    final tasks = await TaskDetector(ref.read(projectServiceProvider)).detect(project);
    if (!mounted) return;
    if (ref.read(activeProjectProvider)?.path != project.path) return;
    ref.read(runTasksProvider.notifier).state = tasks;
    ref.read(runTaskProvider.notifier).state =
        tasks.isNotEmpty ? tasks.first : null;
  }

  Future<void> _newProject() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    var selectedLanguage = "php";
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.projectNew),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration:
                    InputDecoration(hintText: l10n.projectNameHint),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "php", label: Text("PHP"), icon: Icon(Icons.language)),
                  ButtonSegment(value: "node", label: Text("Node"), icon: Icon(Icons.integration_instructions)),
                  ButtonSegment(value: "python", label: Text("Python"), icon: Icon(Icons.terminal)),
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
    ProjectInfo created;
    try {
      created = await ref.read(projectServiceProvider).createProject(
            result.$1,
            result.$2,
          );
    } catch (e) {
      if (!mounted) return;
      _toast(l10n.commonCreateFailed(e.toString()));
      return;
    }
    await _loadProjects(select: created);
  }

  Future<void> _deleteProject(ProjectInfo project) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectDeleteTitle),
        content: Text(l10n.projectDeleteBody(project.name)),
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
    try {
      await ref.read(projectServiceProvider).deleteProject(project.path);
    } catch (e) {
      if (!mounted) return;
      _toast(l10n.commonDeleteFailed(e.toString()));
      return;
    }
    await _loadProjects();
  }

  Widget _projectSelector(
      BuildContext context, List<ProjectInfo>? projects, ProjectInfo? active) {
    if (projects == null || projects.isEmpty) {
      return Text(AppLocalizations.of(context).workspaceTitle);
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<ProjectInfo>(
        value: active == null || !projects.any((p) => p.path == active.path)
            ? null
            : active,
        isExpanded: true,
        hint: Text(AppLocalizations.of(context).projectSelect),
        items: [
          for (final project in projects)
            DropdownMenuItem(
              value: project,
              child: Text(project.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (project) {
          if (project != null) _selectProject(project);
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).workspaceEmpty,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _newProject,
            icon: const Icon(Icons.create_new_folder),
            label: Text(AppLocalizations.of(context).projectNew),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final activeProject = ref.watch(activeProjectProvider);
    return Scaffold(
      appBar: _appBarCollapsed
          ? PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Container(
                height: 28,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        activeProject?.name ??
                            AppLocalizations.of(context).workspaceTitle,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _appBarCollapsed = false),
                      tooltip: AppLocalizations.of(context).toolbarShow,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      icon: const Icon(Icons.expand_more, size: 18),
                    ),
                  ],
                ),
              ),
            )
          : AppBar(
              title: _projectSelector(context, projects, activeProject),
              actions: [
                IconButton(
                  onPressed: () =>
                      setState(() => _appBarCollapsed = true),
                  tooltip: AppLocalizations.of(context).toolbarHide,
                  icon: const Icon(Icons.expand_less),
                ),
                IconButton(
                  onPressed: () => showCommandPalette(
                    context,
                    ref,
                    onOpenTool: (i) => setState(
                      () => _toolIndex = _toolIndex == i ? -1 : i,
                    ),
                  ),
                  tooltip: "Command palette",
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _explorerVisible = !_explorerVisible,
                  ),
                  tooltip: _explorerVisible
                      ? AppLocalizations.of(context).explorerHide
                      : AppLocalizations.of(context).explorerShow,
                  icon: Icon(
                    _explorerVisible ? Icons.menu_open : Icons.menu,
                  ),
                ),
                IconButton(
                  onPressed: _newProject,
                  tooltip: AppLocalizations.of(context).projectNew,
                  icon: const Icon(Icons.create_new_folder),
                ),
                IconButton(
                  onPressed: activeProject == null
                      ? null
                      : () => _deleteProject(activeProject),
                  tooltip: AppLocalizations.of(context).projectDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : projects == null || projects.isEmpty || activeProject == null
              ? _emptyState()
              : Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (_explorerVisible) ...[
                            const SizedBox(width: 264, child: FileExplorerView()),
                            const VerticalDivider(width: 1),
                          ],
                          const Expanded(child: EditorAreaView()),
                        ],
                      ),
                    ),
                    _toolDrawer(
                        context, Theme.of(context).colorScheme),
                  ],
                ),
    );
  }
}