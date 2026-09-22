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

  // -- Downloadable bootstrap variants (Phase 2, not bundled in the APK). --
  // The setup screen offers slim (~67MB: shell + core + apt) and full
  // (~283MB: + node/python/php/git preinstalled). The choice is persisted
  // under [bootstrapVariantKey], which the Kotlin installer reads from the
  // same FlutterSharedPreferences file (see EnvironmentManager).
  static const String bootstrapVariantKey = 'nova_bootstrap_variant';
  static const String bootstrapVariantSlim = 'slim';
  static const String bootstrapVariantFull = 'full';

  /// Approximate download size in bytes, per variant and ABI folder name.
  static const Map<String, int> bootstrapVariantBytes = {
    'slim-aarch64': 70724606,
    'slim-x86_64': 70577631,
    'full-aarch64': 297616258,
    'full-x86_64': 296451792,
  };
}