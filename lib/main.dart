import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app.dart";
import "firebase_options.dart";
import "src/core/services/app_info_service.dart";
import "src/core/services/fcm_service.dart";
import "src/core/services/notification_service.dart";
import "src/features/notifications/notification_model.dart";
import "src/features/notifications/notifications_store.dart";
import "src/features/tour/tours/register_tours.dart";

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

/// FCM background entry point: runs in a separate isolate, so Firebase must
/// be re-initialized here. Shows a system notification on the `nova_high`
/// channel and mirrors the message into the in-app center's persisted queue
/// (`nova.notifications`) so it is listed on next launch. Never throws.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Offline / unconfigured: drop the background message silently.
    return;
  }
  // Shared resolver: data-only messages fall back to data title/body, and
  // fully empty messages are dropped (no blank "Nova" tray entries).
  final content = FcmService.resolveContent(message);
  if (content == null) return;
  final title = content.title;
  final body = content.body;
  final route = content.route;
  try {
    await NotificationService().showSystem(
      title: title,
      body: body,
      route: route,
    );
  } catch (_) {
    // Tray display is best-effort; the in-app copy below still lands.
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(NotificationsStore.storageKey);
    final List<dynamic> list = (raw == null || raw.isEmpty)
        ? <dynamic>[]
        : (jsonDecode(raw) as List<dynamic>);
    final item = AppNotification(
      id:
          message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: "fcm",
      route: route,
      createdAt: DateTime.now(),
    );
    list.insert(0, item.toJson());
    while (list.length > NotificationsStore.maxStored) {
      list.removeLast();
    }
    await prefs.setString(NotificationsStore.storageKey, jsonEncode(list));
  } catch (_) {
    // In-app mirror is best-effort; the tray copy already went out.
  }
}

/// Best-effort Firebase bootstrap. Never throws: on any failure (offline,
/// missing Play services, platform without generated options) the app keeps
/// running as guest without Firebase.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  } catch (_) {
    // Firebase unavailable — app works offline/guest without it.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase foundation (best-effort, never throws): offline / guest-safe.
  // Foreground notification + auth handling is owned by other agents;
  // this only guarantees Firebase is ready and background taps don't crash.
  await _initFirebase();
  // Wire tour content builders once so the first-run hub auto-start has
  // something to run (TourService.hubTargetsBuilder).
  registerTours();
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
