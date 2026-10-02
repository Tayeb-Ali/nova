import "dart:async";

import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:shared_preferences/shared_preferences.dart";

/// System-tray notifications (flutter_local_notifications).
///
/// Channels: `nova_high` (max importance — FCM alerts) and `nova_runtime`
/// (low importance — progress-style runtime updates). Small icon is the app
/// launcher icon. Android 13+ runtime permission is requested best-effort on
/// init and NEVER gates showing: [showSystem] works regardless.
///
/// Test seam: pass a fake [plugin], [clock], or [prefsFactory]. The default
/// [instance] singleton is what the app and the FCM background isolate use.
class NotificationService {
  static const String highChannelId = "nova_high";
  static const String runtimeChannelId = "nova_runtime";
  static const String androidIcon = "@mipmap/ic_launcher";

  /// Last-show timestamp key (diagnostics only).
  static const String lastShownKey = "nova.lastNotificationAt";

  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _prefsFactory;

  bool _ready = false;
  String? _initialRoute;
  final StreamController<String> _taps = StreamController<String>.broadcast();

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now,
       _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  /// Routes tapped while the app was alive (payload == in-app route).
  Stream<String> get onRouteTap => _taps.stream;

  /// Route from the tap that cold-started the app, if any.
  Future<String?> getInitialRoute() async {
    await _ensureInitialized();
    return _initialRoute;
  }

  Future<void> _ensureInitialized() async {
    if (_ready) return;
    try {
      const androidInit = AndroidInitializationSettings(androidIcon);
      const settings = InitializationSettings(android: androidInit);
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onTap,
      );
      _ready = true;
    } catch (_) {
      // Plugin unavailable (e.g. desktop test): show() degrades to no-op.
    }
    // Channels + permission + launch details are each best-effort and
    // independent: one failing must not skip the others.
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          highChannelId,
          "Nova alerts",
          description: "High-priority app alerts",
          importance: Importance.max,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          runtimeChannelId,
          "Runtime updates",
          description: "Low-priority runtime progress",
          importance: Importance.low,
        ),
      );
    } catch (_) {}
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.isNotEmpty) {
        _initialRoute = payload;
      }
    } catch (_) {}
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _taps.add(payload);
    }
  }

  /// Shows a system notification. The tap payload IS the in-app [route], so
  /// tapping the tray entry deep-links back into the app via [onRouteTap] /
  /// [getInitialRoute]. An explicit [payload] overrides [route] when set.
  /// Never throws.
  Future<void> showSystem({
    required String title,
    required String body,
    String? route,
    String? payload,
    bool highPriority = true,
    int? id,
  }) async {
    await _ensureInitialized();
    final effective = (payload ?? route);
    final notificationId = id ?? (_clock().millisecondsSinceEpoch % 0x7fffffff);
    try {
      final android = AndroidNotificationDetails(
        highPriority ? highChannelId : runtimeChannelId,
        highPriority ? "Nova alerts" : "Runtime updates",
        channelDescription: highPriority
            ? "High-priority app alerts"
            : "Low-priority runtime progress",
        importance: highPriority ? Importance.max : Importance.low,
        priority: highPriority ? Priority.high : Priority.low,
        icon: androidIcon,
      );
      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: android),
        payload: (effective == null || effective.isEmpty) ? null : effective,
      );
    } catch (_) {}
    try {
      final prefs = await _prefsFactory();
      await prefs.setInt(lastShownKey, _clock().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
