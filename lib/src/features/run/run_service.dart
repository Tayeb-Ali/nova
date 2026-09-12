import 'termux_bridge.dart';

/// Thrown when inline code is too large for an intent extra and must be run
/// from a file inside a shared workdir instead.
class RunNeedsWorkdirException implements Exception {
  final String message;
  const RunNeedsWorkdirException(this.message);

  @override
  String toString() => 'RunNeedsWorkdirException: $message';
}

/// Builds Termux commands for single-file and project-file runs.
///
/// The service never touches the filesystem itself: for [runSingleFile] the
/// code is passed inline (`-c` / `-e` / `-r`), for [runProjectFile] the
/// caller supplies a Termux-visible [filePath] plus its [workdir].
class RunService {
  final TermuxBridge _bridge;

  RunService({TermuxBridge? bridge})
      : _bridge = bridge ?? TermuxBridge.instance;

  /// Max inline code length before an intent extra becomes unreliable.
  static const int maxInlineCodeLength = 45000;

  /// Absolute Termux prefix used to resolve interpreter executable paths.
  static const String termuxBinDir = '/data/data/com.termux/files/usr/bin';

  /// Supported editor language ids mapped to Termux binary names.
  static const Map<String, String> languageBins = {
    'py': 'python3',
    'python': 'python3',
    'python3': 'python3',
    'js': 'node',
    'javascript': 'node',
    'node': 'node',
    'php': 'php',
  };

  /// Interpreter binary names mapped to their `pkg` package names.
  static const Map<String, String> binPackages = {
    'python3': 'python',
    'node': 'nodejs',
    'php': 'php',
  };

  /// Resolves an editor [language] id to a Termux binary name.
  /// Throws [ArgumentError] for unsupported languages.
  String binForLanguage(String language) {
    final String bin = languageBins[language.trim().toLowerCase()] ?? '';
    if (bin.isEmpty) {
      throw ArgumentError('Unsupported language: $language');
    }
    return bin;
  }

  /// Runs a code snippet inline via `python3 -c` / `node -e` / `php -r`.
  ///
  /// Throws [RunNeedsWorkdirException] when [code] exceeds
  /// [maxInlineCodeLength]; callers should then save the code to a file and
  /// use [runProjectFile] instead. Note: `php -r` code must not include
  /// `<?php` tags.
  Future<RunResult> runSingleFile({
    required String code,
    required String language,
    Duration timeout = const Duration(seconds: 25),
  }) {
    if (code.length > maxInlineCodeLength) {
      throw const RunNeedsWorkdirException(
        'Code is too large to run inline (>45000 chars). '
        'Save it to a project file and run it with a workdir instead.',
      );
    }
    final String bin = binForLanguage(language);
    final String flag = switch (bin) {
      'node' => '-e',
      'php' => '-r',
      _ => '-c',
    };
    return _bridge.runCode(
      path: '$termuxBinDir/$bin',
      args: [flag, code],
      timeout: timeout,
    );
  }

  /// Runs a file that already exists at a Termux-visible path.
  ///
  /// The interpreter is inferred from the file extension
  /// (.py -> python3, .js -> node, .php -> php).
  Future<RunResult> runProjectFile({
    required String filePath,
    required String workdir,
    List<String> args = const [],
    String? stdin,
    Duration timeout = const Duration(seconds: 25),
  }) {
    final String bin = _binForExtension(filePath);
    return _bridge.runCode(
      path: '$termuxBinDir/$bin',
      args: [filePath, ...args],
      workdir: workdir,
      stdin: stdin,
      timeout: timeout,
    );
  }

  /// Ensures [bin] is available, installing its `pkg` package on first miss.
  ///
  /// Returns true when the interpreter is (probably) usable afterwards.
  /// Note the native probe is optimistic, so this may return true while the
  /// install is still settling; rerunning then succeeds.
  Future<bool> ensureInterpreter(
    String bin, {
    Duration installTimeout = const Duration(minutes: 2),
  }) async {
    if (await _bridge.checkInterpreter(bin)) return true;
    final String pkg = binPackages[bin] ?? bin;
    await _bridge.runCode(
      path: '$termuxBinDir/pkg',
      args: ['install', '-y', pkg],
      timeout: installTimeout,
    );
    return _bridge.checkInterpreter(bin);
  }

  String _binForExtension(String filePath) {
    final int dot = filePath.lastIndexOf('.');
    if (dot < 0 || dot == filePath.length - 1) {
      throw ArgumentError(
        'Cannot infer interpreter for file without extension: $filePath',
      );
    }
    final String ext = filePath.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'py' => 'python3',
      'js' => 'node',
      'php' => 'php',
      _ => throw ArgumentError('Unsupported file extension: .$ext'),
    };
  }
}
