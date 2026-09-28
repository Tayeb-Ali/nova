import '../bridge/generated/ide_api.g.dart' as bridge;

/// An opened project in the IDE workspace (task.md §19 §23).
///
/// Identity is the [path], not the instance. `listProjects()` mints a fresh
/// object on every call, so `activeProjectProvider` routinely holds an instance
/// that is equal-but-not-identical to the one in the current `projects` list.
/// Without value equality a `DropdownButton` keyed on this object finds zero
/// matching items for the active project and throws.
class ProjectInfo {
  final String name;
  final String path;
  final String? language;

  const ProjectInfo({
    required this.name,
    required this.path,
    this.language,
  });

  @override
  bool operator ==(Object other) =>
      other is ProjectInfo && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'ProjectInfo($name, $path)';

  factory ProjectInfo.fromBridge(bridge.ProjectInfo p) => ProjectInfo(
        name: p.name,
        path: p.path,
        language: p.language,
      );

  ProjectInfo copyWith({String? name, String? path, String? language}) {
    return ProjectInfo(
      name: name ?? this.name,
      path: path ?? this.path,
      language: language ?? this.language,
    );
  }
}

/// A file system entry returned by the explorer.
class FileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;

  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
  });

  factory FileEntry.fromBridge(bridge.FileEntry f) => FileEntry(
        name: f.name,
        path: f.path,
        isDirectory: f.isDirectory,
        size: f.size,
      );
}