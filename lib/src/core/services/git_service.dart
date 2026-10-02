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

  Future<List<String>> listBranches(String projectPath) =>
      NativeBridge.git.listBranches(projectPath);

  Future<String> currentBranch(String projectPath) =>
      NativeBridge.git.currentBranch(projectPath);

  Future<void> checkout(String projectPath, String branch) =>
      NativeBridge.git.checkout(projectPath, branch);

  Future<void> createBranch(String projectPath, String branch) =>
      NativeBridge.git.createBranch(projectPath, branch);

  Future<void> deleteBranch(String projectPath, String branch) =>
      NativeBridge.git.deleteBranch(projectPath, branch);

  Future<List<String>> stashList(String projectPath) =>
      NativeBridge.git.stashList(projectPath);

  Future<void> stashSave(String projectPath, String message) =>
      NativeBridge.git.stashSave(projectPath, message);

  Future<void> stashPop(String projectPath, int index) =>
      NativeBridge.git.stashPop(projectPath, index);

  Future<void> stashDrop(String projectPath, int index) =>
      NativeBridge.git.stashDrop(projectPath, index);

  /// Remote operations over SSH (clone/fetch/pull/push).
  Future<void> clone(String url, String directory) =>
      NativeBridge.git.clone(url, directory);

  Future<void> fetch(String projectPath) => NativeBridge.git.fetch(projectPath);

  Future<void> pull(String projectPath) => NativeBridge.git.pull(projectPath);

  Future<void> push(String projectPath) => NativeBridge.git.push(projectPath);

  /// SSH key management (ed25519, created on demand in the app home).
  Future<String> generateSshKey() => NativeBridge.git.generateSshKey();

  Future<String> getSshPublicKey() => NativeBridge.git.getSshPublicKey();
}