import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/legacy.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

import "../editor/editor_engine.dart";
import "file_service.dart";

/// Filesystem access.
final fileServiceProvider = Provider<FileService>((ref) {
  return const FileService();
});

/// Workspace root. Null until resolved to a writable folder.
final rootDirProvider = StateProvider<Directory?>((ref) => null);

/// App-private writable workspace (always permitted, no storage permission needed).
final appRootProvider = FutureProvider<Directory>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  final nova = Directory(p.join(docs.path, "Nova"));
  if (!await nova.exists()) await nova.create(recursive: true);
  return nova;
});

/// Direct children of [dir], dirs-first sorted (see [FileService.listFiles]).
final fileListProvider =
    FutureProvider.family<List<FileSystemEntity>, Directory>((ref, dir) {
  return ref.watch(fileServiceProvider).listFiles(dir);
});

/// Open editor tabs.
class OpenTabsNotifier extends StateNotifier<List<EditorTabModel>> {
  OpenTabsNotifier() : super(const <EditorTabModel>[]);

  /// Open [filePath] in a tab (re-uses existing tab) and return its id.
  String open(String filePath) {
    final tab = EditorTabModel.fromPath(filePath);
    final index = state.indexWhere((t) => t.id == tab.id);
    if (index >= 0) {
      return state[index].id;
    }
    state = [...state, tab];
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

  /// Generic field update for a tab.
  void update(String id, EditorTabModel Function(EditorTabModel) fn) {
    state = [
      for (final t in state)
        if (t.id == id) fn(t) else t,
    ];
  }

  void closeAll() => state = const <EditorTabModel>[];
}

final openTabsProvider =
    StateNotifierProvider<OpenTabsNotifier, List<EditorTabModel>>((ref) {
  return OpenTabsNotifier();
});

/// Id of the currently visible tab (matches [EditorTabModel.id]).
final activeTabProvider = StateProvider<String?>((ref) => null);

/// The active tab model, or null when no tab is selected/open.
final activeTabModelProvider = Provider<EditorTabModel?>((ref) {
  final tabs = ref.watch(openTabsProvider);
  final activeId = ref.watch(activeTabProvider);
  if (activeId == null || tabs.isEmpty) return null;
  for (final t in tabs) {
    if (t.id == activeId) return t;
  }
  return null;
});