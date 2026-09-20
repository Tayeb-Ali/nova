import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models/project.dart";
import "editor_area_view.dart";
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
    ProjectInfo created;
    try {
      created = await ref.read(projectServiceProvider).createProject(
            result.$1,
            result.$2,
          );
    } catch (e) {
      _toast("Create failed: $e");
      return;
    }
    await _loadProjects(select: created);
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
    try {
      await ref.read(projectServiceProvider).deleteProject(project.path);
    } catch (e) {
      _toast("Delete failed: $e");
      return;
    }
    await _loadProjects();
  }

  Widget _projectSelector(List<ProjectInfo>? projects, ProjectInfo? active) {
    if (projects == null || projects.isEmpty) {
      return const Text("Workspace");
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<ProjectInfo>(
        value: active == null || !projects.any((p) => p.path == active.path)
            ? null
            : active,
        isExpanded: true,
        hint: const Text("Select project"),
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
          Text("No projects yet", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _newProject,
            icon: const Icon(Icons.create_new_folder),
            label: const Text("New project"),
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
      appBar: AppBar(
        title: _projectSelector(projects, activeProject),
        actions: [
          IconButton(
            onPressed: _newProject,
            tooltip: "New project",
            icon: const Icon(Icons.create_new_folder),
          ),
          IconButton(
            onPressed: activeProject == null ? null : () => _deleteProject(activeProject),
            tooltip: "Delete project",
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
                          const SizedBox(width: 264, child: FileExplorerView()),
                          const VerticalDivider(width: 1),
                          const Expanded(child: EditorAreaView()),
                        ],
                      ),
                    ),
                    const RunPanel(),
                  ],
                ),
    );
  }
}