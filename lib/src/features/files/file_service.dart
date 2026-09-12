import "dart:io";

import "package:path/path.dart" as p;

/// Thin filesystem helper for the file explorer.
class FileService {
  const FileService();

  /// List direct children of [dir], directories first, then files,
  /// each group sorted alphabetically (case-insensitive).
  /// Returns empty list if [dir] does not exist.
  Future<List<FileSystemEntity>> listFiles(Directory dir) async {
    if (!await dir.exists()) return <FileSystemEntity>[];
    final entries = await dir.list().toList();
    entries.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          );
    });
    return entries;
  }

  Future<String> readFile(File file) => file.readAsString();

  Future<void> writeFile(File file, String content) =>
      file.writeAsString(content);

  Future<File> createFile(String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create();
    }
    return file;
  }

  Future<Directory> createDir(String dirPath) async {
    final dir = Directory(dirPath);
    await dir.create(recursive: true);
    return dir;
  }

  /// Delete any [FileSystemEntity] (file, dir, or link).
  /// Directories are deleted recursively.
  Future<void> delete(FileSystemEntity entity) async {
    if (entity is Directory) {
      if (await entity.exists()) {
        await entity.delete(recursive: true);
      }
    } else {
      if (await entity.exists()) {
        await entity.delete();
      }
    }
  }
}