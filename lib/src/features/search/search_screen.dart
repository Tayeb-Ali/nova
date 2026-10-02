import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../l10n/generated/app_localizations.dart";
import "../../core/services/search_service.dart";
import "../../core/ui/empty_state.dart";
import "../tour/tour.dart";
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
    final l10n = AppLocalizations.of(context);
    final project = ref.read(activeProjectProvider);
    if (project == null) {
      setState(() {
        _error = l10n.searchNoProject;
        _result = null;
      });
      return;
    }
    final query = _queryController.text;
    if (query.isEmpty) {
      setState(() {
        _error = l10n.searchTypeSomething;
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
        _error = l10n.searchInvalidRegex;
        _result = null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n.searchFailed("$e");
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
    final l10n = AppLocalizations.of(context);
    final names = dirtyPaths.map(_baseName).join(", ");
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.searchUnsavedTitle),
            content: Text(
              l10n.searchUnsavedBody(names),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.searchReplaceAnyway),
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
    final l10n = AppLocalizations.of(context);
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
            ? l10n.searchNoMatchesReplace
            : l10n.searchReplaced(outcome.totalReplacements, outcome.perFile.length);
      });
      await _search();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = l10n.searchReplaceFailed("$e");
      });
    }
  }

  Future<void> _replaceInFile(String path) async {
    final l10n = AppLocalizations.of(context);
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
            ? l10n.searchNoMatchesIn(_baseName(path))
            : l10n.searchReplacedIn(count, _baseName(path));
      });
      await _search();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.searchReplaceFailed("$e"));
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
    final l10n = AppLocalizations.of(context);
    final result = _result;
    if (result == null) {
      return EmptyState(
        icon: Icons.search,
        title: l10n.searchEmptyHint,
      );
    }
    if (result.hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: l10n.searchNoMatches,
      );
    }
    final replacement = _replaceController.text;
    final groups = <String, List<SearchHit>>{};
    for (final hit in result.hits) {
      groups.putIfAbsent(hit.path, () => []).add(hit);
    }
    return ListView(
      children: [
        if (result.truncated)
          ListTile(
            dense: true,
            leading: const Icon(Icons.warning_amber_outlined, size: 18),
            title: Text(l10n.searchTruncated),
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
              child: Text(l10n.searchReplaceCount(entry.value.length)),
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
    final l10n = AppLocalizations.of(context);
    final project = ref.watch(activeProjectProvider);
    final hits = _result?.hits.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
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
      body: Align(
        // Tablet: keep the form readable on wide screens.
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  key: TourKeys.searchField,
                  controller: _queryController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _replaceController,
                  decoration: InputDecoration(
                    hintText: l10n.searchReplaceHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.find_replace),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    FilterChip(
                      label: const Text("Aa"),
                      tooltip: l10n.searchMatchCase,
                      selected: _caseSensitive,
                      onSelected: (v) =>
                          setState(() => _caseSensitive = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text(".*"),
                      tooltip: l10n.searchUseRegex,
                      selected: _regex,
                      onSelected: (v) => setState(() => _regex = v),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      key: TourKeys.searchButton,
                      onPressed: _searching ? null : _search,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(hits == 0 ? l10n.searchButton : l10n.searchButtonCount(hits)),
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
                      label: Text(l10n.searchReplaceAll),
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
        ),
      ),
    );
  }
}
