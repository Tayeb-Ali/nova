import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/core/bridge/generated/ide_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/sd/adaa/codeide/bridge/IdeApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'sd.adaa.codeide.bridge'),
))

/// Setup / bootstrap status.
class SetupStatus {
  SetupStatus({
    required this.ready,
    this.bootstrapVersion,
    this.error,
  });

  bool ready;
  String? bootstrapVersion;
  String? error;
}

/// A runtime (php / node / python / ...) inspected on the host.
class RuntimeInfo {
  RuntimeInfo({
    required this.id,
    required this.displayName,
    this.version,
    required this.installed,
    this.executable,
  });

  String id;
  String displayName;
  String? version;
  bool installed;
  String? executable;
}

/// A managed background process.
class ProcessInfo {
  ProcessInfo({
    required this.pid,
    required this.command,
    this.cwd,
    this.exitCode,
    this.status,
  });

  String pid;
  String command;
  String? cwd;
  int? exitCode;
  String? status;
}

/// Request to spawn a managed process.
class ProcessRequest {
  ProcessRequest({
    required this.command,
    required this.args,
    this.cwd,
    this.environment,
  });

  String command;
  List<String> args;
  String? cwd;
  Map<String, String>? environment;
}

/// An opened project.
class ProjectInfo {
  ProjectInfo({
    required this.name,
    required this.path,
    this.language,
  });

  String name;
  String path;
  String? language;
}

/// A filesystem entry listing.
class FileEntry {
  FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
  });

  String name;
  String path;
  bool isDirectory;
  int? size;
}

/// Git working tree status.
class GitStatus {
  GitStatus({
    required this.branch,
    required this.modified,
    required this.added,
    required this.deleted,
    required this.untracked,
    this.error,
  });

  String branch;
  List<String> modified;
  List<String> added;
  List<String> deleted;
  List<String> untracked;
  String? error;
}

@HostApi()
abstract class SetupApi {
  SetupStatus getStatus();

  void startSetup();
}

@HostApi()
abstract class RuntimeApi {
  List<RuntimeInfo> getRuntimes();

  RuntimeInfo getRuntime(String id);

  void installRuntime(String id);

  void uninstallRuntime(String id);

  void updateRuntime(String id);
}

@HostApi()
abstract class TerminalApi {
  String createSession(String cwd, int cols, int rows);

  void write(String sessionId, String data);

  void resize(String sessionId, int cols, int rows);

  void close(String sessionId);

  void sendSignal(String sessionId, String signal);
}

@HostApi()
abstract class ProcessApi {
  ProcessInfo startProcess(ProcessRequest request);

  void killProcess(String pid);

  List<ProcessInfo> listProcesses();
}

@HostApi()
abstract class ProjectApi {
  ProjectInfo createProject(String name, String language);

  List<ProjectInfo> listProjects();

  void openProject(String path);

  void deleteProject(String path);
}

@HostApi()
abstract class FileApi {
  String readFile(String path);

  void writeFile(String path, String content);

  List<FileEntry> listFiles(String path);

  bool rename(String oldPath, String newPath);

  bool delete(String path);

  bool mkdir(String path);
}

@HostApi()
abstract class GitApi {
  GitStatus status(String projectPath);

  void add(String projectPath, List<String> paths);

  void commit(String projectPath, String message);

  String diff(String projectPath);
}

@HostApi()
abstract class WebPreviewApi {
  String? previewUrl();
}