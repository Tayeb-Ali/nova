import "package:package_info_plus/package_info_plus.dart";

/// App version info, always read from the platform package via
/// package_info_plus (mirrors pubspec.yaml `version: <version>+<buildNumber>`
/// at build time). There are no hardcoded version values anywhere.
///
/// Call [load] once at startup (see main) before the first frame, so every
/// label can read [version]/[buildNumber] synchronously afterwards.
abstract final class AppInfo {
  static PackageInfo? _info;

  static bool get isLoaded => _info != null;

  /// Empty until [load] completes; callers should check [isLoaded] first.
  static String get version => _info?.version ?? "";
  static String get buildNumber => _info?.buildNumber ?? "";

  static Future<void> load() async {
    try {
      _info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {
      // Platform lookup failed; labels hide themselves via [isLoaded].
    }
  }

  /// Test seam: reset to the unloaded state.
  static void debugReset() {
    _info = null;
  }
}
