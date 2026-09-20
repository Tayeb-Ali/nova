import '../bridge/generated/ide_api.g.dart';
import '../bridge/native_bridge.dart';

/// Git via the embedded git binary (task.md §24).
class GitService {
  Future<GitStatus> status(String projectPath) =>
      NativeBridge.git.status(projectPath);

  Future<void> add(String projectPath, List<String> paths) =>
      NativeBridge.git.add(projectPath, paths);

  Future<void> commit(String projectPath, String message) =>
      NativeBridge.git.commit(projectPath, message);

  Future<String> diff(String projectPath) => NativeBridge.git.diff(projectPath);
}