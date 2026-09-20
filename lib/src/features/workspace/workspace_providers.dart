import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/legacy.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/models/project.dart";
import "../../core/models/task.dart";
import "../../core/services/process_service.dart";
import "../../core/services/project_service.dart";
import "../editor/editor_engine.dart";

/// Native-bridge services for the workspace (task.md §19 §23).
final projectServiceProvider = Provider<ProjectService>((ref) => ProjectService());

final processServiceProvider = Provider<ProcessService>((ref) => ProcessService());

/// Project list. null while the first load is in flight.
final projectsProvider = StateProvider<List<ProjectInfo>?>((ref) => null);

/// Currently selected project, or null before any project is picked.
final activeProjectProvider = StateProvider<ProjectInfo?>((ref) => null);

/// Folder currently shown in the file explorer.
final currentDirProvider = StateProvider<String?>((ref) => null);

/// Direct children of [path] via the native FileApi.
final fileEntriesProvider =
    FutureProvider.family<List<FileEntry>, String>((ref, path) {
  return ref.watch(projectServiceProvider).listFiles(path);
});

/// Open editor tabs; the tab id is the full file path (task.md §35).
class WorkspaceTabsNotifier extends StateNotifier<List<EditorTabModel>> {
  WorkspaceTabsNotifier(this._ref) : super(const <EditorTabModel>[]);

  final Ref _ref;

  /// Open [filePath] in a tab (re-uses an existing one) and return its id.
  String open(String filePath) {
    final tab = EditorTabModel.fromPath(filePath);
    final index = state.indexWhere((t) => t.id == tab.id);
    if (index >= 0) {
      _recordRecent(filePath);
      return state[index].id;
    }
    state = [...state, tab];
    _recordRecent(filePath);
    return tab.id;
  }

  void close(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void markDirty(String id, bool dirty) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(dirty: dirty) else t,
    ];
  }

  /// Point a tab (and any content) at a new path after a rename.
  void rename(String oldId, String newPath) {
    state = [
      for (final t in state)
        if (t.id == oldId)
          EditorTabModel.fromPath(newPath).copyWith(dirty: t.dirty)
        else
          t,
    ];
  }

  void closeAll() => state = const <EditorTabModel>[];

  /// Push [filePath] to the recent-files list and persist it.
  /// Never throws: recents must never break opening.
  void _recordRecent(String filePath) {
    try {
      final next = pushRecentFile(_ref.read(recentFilesProvider), filePath);
      _ref.read(recentFilesProvider.notifier).state = next;
      // Fire-and-forget persist; errors are swallowed inside.
      saveRecentFiles(next);
    } catch (_) {
      // Ignore: recents must never break opening.
    }
  }
}

final workspaceTabsProvider =
    StateNotifierProvider<WorkspaceTabsNotifier, List<EditorTabModel>>(
        (ref) => WorkspaceTabsNotifier(ref));

/// SharedPreferences key for the persisted recent-files list.
const kRecentFilesKey = "nova.recentFiles";

/// Max entries kept in [recentFilesProvider].
const kMaxRecentFiles = 10;

/// Recently opened files, most-recent-first (max 10, deduped by path).
/// Recorded automatically inside [WorkspaceTabsNotifier.open] so every
/// opener (explorer, hub, tests) is covered; loaded lazily via
/// [loadRecentFiles].
final recentFilesProvider = StateProvider<List<String>>((ref) => const []);

/// Most-recent-first insert with path dedup and [kMaxRecentFiles] cap.
/// Pure helper so the ordering logic stays testable.
List<String> pushRecentFile(List<String> current, String path) {
  final next = <String>[path, for (final p in current) if (p != path) p];
  return next.length > kMaxRecentFiles
      ? next.sublist(0, kMaxRecentFiles)
      : next;
}

/// Lazily load the persisted recents; returns empty on any failure.
Future<List<String>> loadRecentFiles() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(kRecentFilesKey);
    if (stored == null || stored.isEmpty) return const [];
    return stored.take(kMaxRecentFiles).toList();
  } catch (_) {
    return const [];
  }
}

/// Persist [files]; never throws.
Future<void> saveRecentFiles(List<String> files) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kRecentFilesKey, files);
  } catch (_) {
    // Ignore: recents must never break opening.
  }
}

/// Id of the currently visible editor tab.
final activeEditorTabProvider = StateProvider<String?>((ref) => null);

/// The active editor tab model, or null when no tab is selected.
final activeEditorTabModelProvider = Provider<EditorTabModel?>((ref) {
  final tabs = ref.watch(workspaceTabsProvider);
  final activeId = ref.watch(activeEditorTabProvider);
  if (activeId == null) return null;
  for (final t in tabs) {
    if (t.id == activeId) return t;
  }
  return null;
});

/// Tasks detected in the active project (task.md §20).
final runTasksProvider = StateProvider<List<IdeTask>>((ref) => const []);

/// Task selected in the run dropdown.
final runTaskProvider = StateProvider<IdeTask?>((ref) => null);

/// PID of the task process, or null while idle.
final runningPidProvider = StateProvider<String?>((ref) => null);

/// Collected stdout/stderr of the running task.
class RunOutputNotifier extends StateNotifier<String> {
  RunOutputNotifier() : super("");

  void clear() => state = "";

  void append(String chunk) {
    if (chunk.isEmpty) return;
    final text = state.isEmpty ? chunk : "$state$chunk";
    state = text.length > 200000 ? text.substring(text.length - 200000) : text;
  }
}

final runOutputProvider =
    StateNotifierProvider<RunOutputNotifier, String>((ref) => RunOutputNotifier());