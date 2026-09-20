import '../bridge/generated/ide_api.g.dart' as bridge;

/// Runtime kinds supported by the embedded environment (task.md §4).
enum RuntimeType {
  php,
  node,
  python,
  git,
  composer,
  other;

  static RuntimeType fromId(String id) {
    switch (id) {
      case 'php':
        return RuntimeType.php;
      case 'node':
        return RuntimeType.node;
      case 'python':
        return RuntimeType.python;
      case 'git':
        return RuntimeType.git;
      case 'composer':
        return RuntimeType.composer;
      default:
        return RuntimeType.other;
    }
  }
}

class RuntimeInfo {
  final String id;
  final String displayName;
  final String? version;
  final bool installed;
  final String? executable;

  RuntimeInfo({
    required this.id,
    required this.displayName,
    this.version,
    this.installed = false,
    this.executable,
  });

  RuntimeType get type => RuntimeType.fromId(id);

  factory RuntimeInfo.fromBridge(bridge.RuntimeInfo b) => RuntimeInfo(
        id: b.id,
        displayName: b.displayName,
        version: b.version,
        installed: b.installed,
        executable: b.executable,
      );
}