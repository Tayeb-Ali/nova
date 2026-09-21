import '../bridge/generated/ide_api.g.dart' as bridge;

/// An opened project in the IDE workspace (task.md §19 §23).
class ProjectInfo {
  final String name;
  final String path;
  final String? language;

  const ProjectInfo({
    required this.name,
    required this.path,
    this.language,
  });

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