// Nova IDE core configuration constants.
// Package: sd.adaa.codeide, App: Nova.

/// Centralised constants for run bridge, timeouts, and language mapping.
abstract final class AppConfig {
  /// MethodChannel name for Termux RUN_COMMAND bridge.
  static const String runChannel = 'sd.adaa.codeide/run';

  /// Default execution timeout in milliseconds.
  static const int defaultTimeoutMs = 25000;

  /// Max stdin payload size in characters (~45KB).
  static const int stdinLimit = 45000;

  /// Termux package name for queries + RUN_COMMAND permission.
  static const String termuxPkg = 'com.termux';

  /// File extension -> interpreter binary.
  static const Map<String, String> languageCommands = {
    'py': 'python3',
    'js': 'node',
    'php': 'php',
  };

  /// Interpreter binary -> Termux (pkg) bootstrap package name.
  static const Map<String, String> bootstrapPackages = {
    'python3': 'python',
    'node': 'nodejs',
    'php': 'php',
  };

  /// Resolve interpreter for a file extension, or null if unsupported.
  static String? commandForExtension(String ext) =>
      languageCommands[ext.toLowerCase().trim()];
}
