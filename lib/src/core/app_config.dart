// Nova IDE core configuration constants.

/// Centralised constants for bridges, timeouts, and language mapping.
abstract final class AppConfig {
  /// Default execution timeout in milliseconds.
  static const int defaultTimeoutMs = 25000;

  /// Max stdin payload size in characters (~45KB).
  static const int stdinLimit = 45000;

  /// Kotlin -> Flutter event stream channel.
  static const String eventsChannel = 'sd.adaa.codeide/events';

  /// File extension -> interpreter binary.
  static const Map<String, String> languageCommands = {
    'py': 'python',
    'js': 'node',
    'php': 'php',
    'dart': 'dart',
  };

  /// Interpreter binary -> embedded bootstrap package name.
  static const Map<String, String> bootstrapPackages = {
    'python': 'python',
    'node': 'nodejs',
    'php': 'php',
    'dart': 'dart',
  };

  /// Resolve interpreter for a file extension, or null if unsupported.
  static String? commandForExtension(String ext) =>
      languageCommands[ext.toLowerCase().trim()];
}