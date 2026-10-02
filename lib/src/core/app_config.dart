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
    'slim-aarch64': 73753122,
    'slim-x86_64': 73663496,
    'full-aarch64': 297616258,
    'full-x86_64': 296451792,
  };

  // -- Binary distribution sources (Phase 2). --
  // Dart-side mirror of the BuildConfig fields in
  // android/app/build.gradle.kts (github/play flavors). Used only for
  // reachability probing (RepoHealthService) — the Kotlin installer owns
  // the real download logic. Keep in sync when the flavors change.
  static const String repoUrl = 'http://elteyab.sd/nova/apt';
  static const String repoSuite = 'stable';
  static const String bootstrapSlimBaseUrl =
      'http://elteyab.sd/nova/bootstrap';
  static const String bootstrapFullBaseUrl =
      'https://github.com/Tayeb-Ali/nova/releases/download/bootstrap-v1';

  // -- Public project / contact links (Settings > About & Contact). --
  // Single source of truth so the UI, tests, and README never drift.
  static const String githubRepoUrl = 'https://github.com/Tayeb-Ali/nova';
  static const String githubReleasesUrl =
      'https://github.com/Tayeb-Ali/nova/releases';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=sd.adaa.codeide';
  static const String contactEmail = 'elteyab@smart.sd';
  static const String licenseUrlAr =
      'https://ojuba.org/waqf:رخصة_وقف_العامة';
  static const String licenseUrlEn = 'https://ojuba.org/waqf:license';
}