import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/services/search_service.dart";
import "../workspace/workspace_providers.dart";

/// Preview of [hit.lineText] with the matched range swapped for
/// [replacement]. Pure helper so replace preview stays unit-testable.
String searchHitPreview(SearchHit hit, String replacement) {
  final start = (hit.column - 1).clamp(0, hit.lineText.length);
  final end = (start + hit.matchLength).clamp(0, hit.lineText.length);
  return hit.lineText.replaceRange(start, end, replacement);
}

/// Project-wide text search with replace (NEXT_PLAN 2.3, S1+S2).
///
/// Searches via [SearchService] (recursive walk of the active project),
/// opens a tapped hit in the editor at its line, and offers replace in
/// file / replace all with a dirty-tab confirm guard.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  late final TextEditingController _replaceController;
  bool _caseSensitive = false;
  bool _regex = false;
  bool _searching = false;
  ProjectSearchResult? _result;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery ?? "");
    _replaceController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  SearchOptions get _options => SearchOptions(
        caseSensitive: _caseSensitive,
        regex: _regex,
      );

  SearchService get _service =>
      SearchService(ref.read(projectServiceProvider));

  Future<void> _search() async {
    final project = ref.read(activeProjectProvider);
    if (project == null) {
      setState(() {
        _error = "No project open";
        _result = null;
      });
      return;
    }
    final query = _queryController.text;
    if (query.isEmpty) {
      setState(() {
        _error = "Type something to search for";
        _result = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await _service.search(project.path, query, _options);
      if (!mounted) return;
      setState(() {
        _result = result;
        _searching = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _error = "Invalid regular expression";
        _result = null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Search failed: $e";
        _result = null;
        _searching = false;
      });
    }
  }

  /// Open [hit] in the editor and jump to its (1-based) line.
  void _openHit(SearchHit hit) {
    final id = ref
        .read(workspaceTabsProvider.notifier)
        .open(hit.path, initialLine: hit.line - 1);
    ref.read(activeEditorTabProvider.notifier).state = id;
    if (mounted) Navigator.of(context).pop();
  }

  static String _parentDir(String path) {
    final normalized = path.replaceAll("\\", "/");
    final slash = normalized.lastIndexOf("/");
    return slash < 0 ? path : normalized.substring(0, slash);
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll("\\", "/");
    final slash = normalized.lastIndexOf("/");
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  /// Confirm overwriting unsaved tabs; lists dirty files that would lose edits.
  Future<bool> _confirmDirtyOverwrite(List<String> dirtyPaths) async {
    if (dirtyPaths.isEmpty) return true;
    if (!mounted) return false;
    final names = dirtyPaths.map(_baseName).join(", ");
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Unsaved changes"),
            content: Text(
              "These open tabs have unsaved edits that replace would "
              "overwrite: $names. Replace anyway?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Replace anyway"),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Open tabs with unsaved edits among [paths].
  List<String> _dirtyTabsIn(Set<String> paths) {
    return ref
        .read(workspaceTabsProvider)
        .where((t) => t.dirty && paths.contains(t.path))
        .map((t) => t.path)
        .toList();
  }

  void _invalidateParents(Iterable<String> paths) {
    final dirs = {for (final p in paths) _parentDir(p)};
    for (final dir in dirs) {
      ref.invalidate(fileEntriesProvider(dir));
    }
  }

  Future<void> _replaceAll() async {
    final project = ref.read(activeProjectProvider);
    final hits = _result?.hits;
    if (project == null || hits == null || hits.isEmpty) return;
    final query = _queryController.text;
    if (query.isEmpty) return;
    final paths = {for (final h in hits) h.path};
    if (!await _confirmDirtyOverwrite(_dirtyTabsIn(paths))) return;
    setState(() {
      _searching = true;
      _notice = null;
    });
    try {
      final outcome = await _service.replaceAll(
        rootPath: project.path,
        query: query,
        replacement: _replaceController.text,
        options: _options,
      );
      if (!mounted) return;
      _invalidateParents(outcome.perFile.keys);
      setState(() {
        _searching = false;
        _notice = outcome.totalReplacements == 0
            ? "No matches to replace"
            : "Replaced ${outcome.totalReplacements} in "
                "${outcome.perFile.length} files. "
                "Reopen affected tabs to reload.";
      });
      await _search();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = "Replace failed: $e";
      });
    }
  }

  Future<void> _replaceInFile(String path) async {
    final query = _queryController.text;
    if (query.isEmpty) return;
    if (!await _confirmDirtyOverwrite(_dirtyTabsIn({path}))) return;
    try {
      final count = await _service.replaceInFile(
        path: path,
        query: query,
        replacement: _replaceController.text,
        options: _options,
      );
      if (!mounted) return;
      _invalidateParents([path]);
      setState(() {
        _notice = count == 0
            ? "No matches in ${_baseName(path)}"
            : "Replaced $count in ${_baseName(path)}. "
                "Reopen the tab to reload.";
      });
      await _search();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Replace failed: $e");
    }
  }

  Widget _hitLine(SearchHit hit) {
    const mono = TextStyle(fontFamily: "monospace");
    final start = (hit.column - 1).clamp(0, hit.lineText.length);
    final end = (start + hit.matchLength).clamp(0, hit.lineText.length);
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(mono),
        children: [
          TextSpan(text: hit.lineText.substring(0, start)),
          TextSpan(
            text: hit.lineText.substring(start, end),
            style: TextStyle(backgroundColor: scheme.tertiaryContainer),
          ),
          TextSpan(text: hit.lineText.substring(end)),
        ],
      ),
    );
  }

  Widget _results() {
    final result = _result;
    if (result == null) {
      return const Center(child: Text("Search the active project above"));
    }
    if (result.hits.isEmpty) {
      return const Center(child: Text("No matches"));
    }
    final replacement = _replaceController.text;
    final groups = <String, List<SearchHit>>{};
    for (final hit in result.hits) {
      groups.putIfAbsent(hit.path, () => []).add(hit);
    }
    return ListView(
      children: [
        if (result.truncated)
          const ListTile(
            dense: true,
            leading: Icon(Icons.warning_amber_outlined, size: 18),
            title: Text("Showing the first matches only (limits reached)"),
          ),
        for (final entry in groups.entries) ...[
          ListTile(
            dense: true,
            title: Text(
              _baseName(entry.key),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              entry.key,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: "monospace"),
            ),
            trailing: TextButton(
              onPressed: () => _replaceInFile(entry.key),
              child: Text("Replace (${entry.value.length})"),
            ),
          ),
          for (final hit in entry.value)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              leading: Text(
                "${hit.line}",
                style: const TextStyle(fontFamily: "monospace"),
              ),
              title: _hitLine(hit),
              subtitle: replacement.isEmpty
                  ? null
                  : Text(
                      "→ ${searchHitPreview(hit, replacement)}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: "monospace"),
                    ),
              onTap: () => _openHit(hit),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final hits = _result?.hits.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search in project"),
        bottom: project == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search text or pattern…",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _replaceController,
                  decoration: const InputDecoration(
                    hintText: "Replace with…",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.find_replace),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    FilterChip(
                      label: const Text("Aa"),
                      tooltip: "Match case",
                      selected: _caseSensitive,
                      onSelected: (v) =>
                          setState(() => _caseSensitive = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text(".*"),
                      tooltip: "Use regular expression",
                      selected: _regex,
                      onSelected: (v) => setState(() => _regex = v),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _searching ? null : _search,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(hits == 0 ? "Search" : "Search ($hits)"),
                    ),
                  ],
                ),
                if (_replaceController.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          (_searching || hits == 0) ? null : _replaceAll,
                      icon: const Icon(Icons.find_replace, size: 18),
                      label: const Text("Replace all"),
                    ),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_notice != null)
                  Text(
                    _notice!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _results()),
        ],
      ),
    );
  }
}
