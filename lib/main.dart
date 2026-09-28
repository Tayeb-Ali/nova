import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app.dart";

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
