import '../bridge/native_bridge.dart';
import '../models/project.dart';

/// Project workspace + file operations through the native layer (task.md §19 §23).
class ProjectService {
  Future<ProjectInfo> createProject(String name, String language) async {
    final p = await NativeBridge.project.createProject(name, language);
    return ProjectInfo.fromBridge(p);
  }

  Future<List<ProjectInfo>> listProjects() async {
    final list = await NativeBridge.project.listProjects();
    return list.map(ProjectInfo.fromBridge).toList();
  }

  Future<void> openProject(String path) => NativeBridge.project.openProject(path);

  Future<void> deleteProject(String path) => NativeBridge.project.deleteProject(path);

  Future<List<FileEntry>> listFiles(String path) async {
    final list = await NativeBridge.files.listFiles(path);
    return list.map(FileEntry.fromBridge).toList();
  }

  Future<String> readFile(String path) => NativeBridge.files.readFile(path);

  Future<void> writeFile(String path, String content) =>
      NativeBridge.files.writeFile(path, content);

  Future<bool> rename(String oldPath, String newPath) =>
      NativeBridge.files.rename(oldPath, newPath);

  Future<bool> delete(String path) => NativeBridge.files.delete(path);

  Future<bool> mkdir(String path) => NativeBridge.files.mkdir(path);
}