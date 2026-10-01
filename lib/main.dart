import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app.dart";
import "src/core/services/app_info_service.dart";

/// Key holding the first framework error of the current process, if any.
/// Read on-device without racing logcat:
/// `run-as sd.adaa.codeide cat .../shared_prefs/FlutterSharedPreferences.xml`
const _crashKey = "nova_last_crash";

Future<void> _persistFirstError(FlutterErrorDetails details) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_crashKey) == null) {
      final text = "${details.exception}\n${details.stack}";
      await prefs.setString(
        _crashKey,
        text.length > 4000 ? text.substring(0, 4000) : text,
      );
    }
  } catch (_) {
    // Crash reporting must never crash the app.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Detect version/build from the platform package before the first frame,
  // so the splash footer and Settings > About read them synchronously.
  // Best-effort (never throws): labels hide themselves if it fails.
  await AppInfo.load();
  // Brand-colored system bars from the very first frame: the native launch
  // theme already paints #13151B, and this keeps the status/nav bars dark
  // while Flutter initializes (no white flash on either edge).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF13151B),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF13151B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_crashKey);
  } catch (_) {
    // Non-fatal; reporting just stays disabled this launch.
  }
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(_persistFirstError(details));
    (previousOnError ?? FlutterError.presentError)(details);
  };
  runApp(const ProviderScope(child: NovaApp()));
}
