import "package:dio/dio.dart";
import "package:flutter/services.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

/// Official Termux distribution points.
///
/// There is no Termux "SDK" to embed: Termux is a separate Android app.
/// The Play Store build is deprecated and cannot run code, so Nova fetches
/// the official F-Droid APK on demand instead of bundling ~109 MB inside
/// its own APK (see DECISIONS.md).
class TermuxSources {
  /// Direct APK download (F-Droid, version 0.119.0-beta.3, universal).
  static const String fdroidApkUrl =
      "https://f-droid.org/repo/com.termux_1022.apk";

  /// Human-readable pages (user picks a variant manually).
  static const String fdroidPage = "https://f-droid.org/en/packages/com.termux/";
  static const String githubReleases =
      "https://github.com/termux/termux-app/releases";

  static const String apkFileName = "termux-fdroid.apk";
}

/// Downloads the official Termux APK and hands it to the Android installer.
///
/// Native side lives in InstallBridge (channel `sd.adaa.codeide/install`).
class TermuxInstaller {
  static const MethodChannel _channel =
      MethodChannel("sd.adaa.codeide/install");

  final Dio _dio;

  TermuxInstaller({Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads the APK to the temp dir, reporting progress. Returns save path.
  Future<String> downloadApk({
    required void Function(int received, int total) onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final savePath = p.join(dir.path, TermuxSources.apkFileName);
    await _dio.download(
      TermuxSources.fdroidApkUrl,
      savePath,
      onReceiveProgress: onProgress,
      deleteOnError: true,
    );
    return savePath;
  }

  /// Fires the system package installer for [apkPath].
  Future<bool> installApk(String apkPath) async {
    final ok =
        await _channel.invokeMethod<bool>("installApk", {"path": apkPath});
    return ok ?? false;
  }

  /// Whether "install unknown apps" is already allowed for Nova.
  Future<bool> canRequestInstalls() async {
    final ok = await _channel.invokeMethod<bool>("canRequestInstalls");
    return ok ?? false;
  }

  /// Opens the system "install unknown apps" settings page for Nova.
  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod("openInstallPermissionSettings");

  /// Opens any URL in the user's browser.
  Future<void> openUrl(String url) =>
      _channel.invokeMethod("openUrl", {"url": url });
}
