import "../models/project.dart";
import "project_service.dart";

/// Options for project-wide text search (and replace).
class SearchOptions {
  final bool caseSensitive;
  final bool regex;

  /// Max files read per search/replace-all walk.
  final int maxFiles;

  /// Max file content length (chars) read per file; larger files are skipped.
  final int maxFileSize;

  /// Max hits collected per search before truncating.
  final int maxHits;

  const SearchOptions({
    this.caseSensitive = false,
    this.regex = false,
    this.maxFiles = 500,
    this.maxFileSize = 512 * 1024,
    this.maxHits = 1000,
  });
}

/// One match of a project search.
class SearchHit {
  /// Full file path of the match.
  final String path;

  /// 1-based line number.
  final int line;

  /// 1-based character column where the match starts.
  final int column;

  /// Full text of the matched line (without line break).
  final String lineText;

  /// Length of the match in characters (for highlight/preview).
  final int matchLength;

  const SearchHit({
    required this.path,
    required this.line,
    required this.column,
    required this.lineText,
    required this.matchLength,
  });
}

/// Result of [SearchService.search].
class ProjectSearchResult {
  final List<SearchHit> hits;
  final int filesScanned;

  /// True when [SearchOptions.maxFiles] / [SearchOptions.maxHits] stopped
  /// the walk early; more matches may exist.
  final bool truncated;

  const ProjectSearchResult({
    this.hits = const [],
    this.filesScanned = 0,
    this.truncated = false,
  });
}

/// Outcome of [SearchService.replaceAll].
class ProjectReplaceResult {
  /// Total replacements applied across all files.
  final int totalReplacements;

  /// Per-file replacement counts.
  final Map<String, int> perFile;

  const ProjectReplaceResult({
    this.totalReplacements = 0,
    this.perFile = const {},
  });
}

/// Project-wide find/replace over [ProjectService.listFiles] + `readFile`.
///
/// Skips generated/dependency directories, caps files/size/hits so a search
/// stays cheap on device. Throws [FormatException] for an invalid regex when
/// [SearchOptions.regex] is true.
class SearchService {
  SearchService(this._projects);

  final ProjectService _projects;

  /// Directory names never descended into during a search/replace walk.
  static const skipDirNames = {
    ".git",
    "node_modules",
    ".dart_tool",
    "build",
  };

  /// Build the match pattern for [query]; throws [FormatException] on a bad
  /// regex. Pure helper so matching semantics stay unit-testable.
  static RegExp buildPattern(String query, SearchOptions options) {
    if (options.regex) {
      return RegExp(query, caseSensitive: options.caseSensitive);
    }
    return RegExp(RegExp.escape(query), caseSensitive: options.caseSensitive);
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll("\\", "/");
    final slash = normalized.lastIndexOf("/");
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  /// Recursive (breadth-first) search of [rootPath] for [query].
  Future<ProjectSearchResult> search(
    String rootPath,
    String query, [
    SearchOptions options = const SearchOptions(),
  ]) async {
    if (query.isEmpty) return const ProjectSearchResult();
    final pattern = buildPattern(query, options);
    final hits = <SearchHit>[];
    var filesScanned = 0;
    var truncated = false;
    final queue = <String>[rootPath];
    while (queue.isNotEmpty) {
      if (hits.length >= options.maxHits ||
          filesScanned >= options.maxFiles) {
        truncated = true;
        break;
      }
      final dir = queue.removeAt(0);
      List<FileEntry> entries;
      try {
        entries = await _projects.listFiles(dir);
      } catch (_) {
        continue;
      }
      for (final entry in entries) {
        if (hits.length >= options.maxHits) {
          truncated = true;
          break;
        }
        if (entry.isDirectory) {
          if (!skipDirNames.contains(_baseName(entry.path))) {
            queue.add(entry.path);
          }
          continue;
        }
        if (filesScanned >= options.maxFiles) {
          truncated = true;
          break;
        }
        if (entry.size != null && entry.size! > options.maxFileSize) {
          continue;
        }
        String content;
        try {
          content = await _projects.readFile(entry.path);
        } catch (_) {
          continue;
        }
        if (content.length > options.maxFileSize) continue;
        // Cheap binary guard.
        if (content.contains("\x00")) continue;
        filesScanned++;
        final lines = content.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var lineText = lines[i];
          if (lineText.endsWith("\r")) {
            lineText = lineText.substring(0, lineText.length - 1);
          }
          for (final match in pattern.allMatches(lineText)) {
            if (match.start == match.end) continue;
            hits.add(
              SearchHit(
                path: entry.path,
                line: i + 1,
                column: match.start + 1,
                lineText: lineText,
                matchLength: match.end - match.start,
              ),
            );
            if (hits.length >= options.maxHits) {
              truncated = true;
              break;
            }
          }
          if (hits.length >= options.maxHits) break;
        }
      }
    }
    return ProjectSearchResult(
      hits: hits,
      filesScanned: filesScanned,
      truncated: truncated,
    );
  }

  /// Replace every occurrence of [query] with [replacement] in the single
  /// file [path] (`readFile` + `writeFile`). Returns the replacement count;
  /// writes nothing when there is no match.
  Future<int> replaceInFile({
    required String path,
    required String query,
    required String replacement,
    SearchOptions options = const SearchOptions(),
  }) async {
    if (query.isEmpty) return 0;
    final pattern = buildPattern(query, options);
    final content = await _projects.readFile(path);
    final matches = pattern
        .allMatches(content)
        .where((m) => m.start != m.end)
        .toList();
    if (matches.isEmpty) return 0;
    await _projects.writeFile(path, content.replaceAll(pattern, replacement));
    return matches.length;
  }

  /// Replace every occurrence of [query] with [replacement] in all files
  /// under [rootPath] (same walk/caps/skips as [search]). Returns totals.
  Future<ProjectReplaceResult> replaceAll({
    required String rootPath,
    required String query,
    required String replacement,
    SearchOptions options = const SearchOptions(),
  }) async {
    if (query.isEmpty) return const ProjectReplaceResult();
    final pattern = buildPattern(query, options);
    final perFile = <String, int>{};
    var total = 0;
    var filesScanned = 0;
    final queue = <String>[rootPath];
    while (queue.isNotEmpty) {
      if (filesScanned >= options.maxFiles) break;
      final dir = queue.removeAt(0);
      List<FileEntry> entries;
      try {
        entries = await _projects.listFiles(dir);
      } catch (_) {
        continue;
      }
      for (final entry in entries) {
        if (entry.isDirectory) {
          if (!skipDirNames.contains(_baseName(entry.path))) {
            queue.add(entry.path);
          }
          continue;
        }
        if (filesScanned >= options.maxFiles) break;
        if (entry.size != null && entry.size! > options.maxFileSize) {
          continue;
        }
        String content;
        try {
          content = await _projects.readFile(entry.path);
        } catch (_) {
          continue;
        }
        if (content.length > options.maxFileSize) continue;
        if (content.contains("\x00")) continue;
        filesScanned++;
        final count = pattern
            .allMatches(content)
            .where((m) => m.start != m.end)
            .length;
        if (count == 0) continue;
        await _projects.writeFile(
          entry.path,
          content.replaceAll(pattern, replacement),
        );
        perFile[entry.path] = count;
        total += count;
      }
    }
    return ProjectReplaceResult(
      totalReplacements: total,
      perFile: perFile,
    );
  }
}
