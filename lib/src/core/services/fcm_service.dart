import "dart:async";

import "package:firebase_messaging/firebase_messaging.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../features/notifications/notification_model.dart";
import "notification_service.dart";

/// Firebase Cloud Messaging wiring: permission, foreground display,
/// tap-to-route, token persistence, and the announcements topic.
///
/// Every platform call is wrapped in try/catch: FCM is best-effort and the
/// app must work fully offline / without Play services. Construct with fakes
/// ([messaging], [system], [prefsFactory]) in tests.
///
/// Wiring (owned by the integration agent):
/// ```dart
/// final fcm = FcmService();
/// await fcm.init(
///   onNotification: (item) =>
///     ref.read(notificationsStoreProvider.notifier).push(item),
/// );
/// final pending = await fcm.getInitialRoute(); // cold-start tap route
/// fcm.onRouteOpened.listen((route) => /* Navigator.pushNamed */);
/// ```
class FcmService {
  /// Where the latest FCM registration token is cached.
  static const String fcmTokenKey = "nova.fcmToken";

  /// Broadcast topic for Nova announcements.
  static const String announcementsTopic = "nova_announcements";

  final FirebaseMessaging _messaging;
  final NotificationService _system;
  final Future<SharedPreferences> Function() _prefsFactory;

  final StreamController<String> _routes = StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _refreshSub;
  bool _started = false;

  FcmService({
    FirebaseMessaging? messaging,
    NotificationService? system,
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _system = system ?? NotificationService.instance,
       _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  /// Extracts the in-app route from a message (`data["route"]`), if present.
  static String? routeOf(RemoteMessage message) {
    final route = message.data["route"];
    if (route is String && route.isNotEmpty) return route;
    return null;
  }

  /// Requests permission, subscribes to [announcementsTopic], caches the
  /// token, and routes foreground messages to a system notification PLUS the
  /// in-app center via [onNotification]. Never throws; safe to call once.
  Future<void> init({
    required Future<void> Function(AppNotification item) onNotification,
  }) async {
    if (_started) return;
    _started = true;
    try {
      await _messaging.requestPermission();
    } catch (_) {}
    try {
      await _messaging.subscribeToTopic(announcementsTopic);
    } catch (_) {}
    try {
      FirebaseMessaging.onMessage.listen((message) async {
        final item = _toAppNotification(message);
        try {
          await _system.showSystem(
            title: item.title,
            body: item.body,
            route: item.route,
          );
        } catch (_) {}
        try {
          await onNotification(item);
        } catch (_) {}
      });
    } catch (_) {}
    try {
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = routeOf(message);
        if (route != null) _routes.add(route);
      });
    } catch (_) {}
    try {
      _refreshSub = _messaging.onTokenRefresh.listen((token) {
        unawaited(_persistToken(token));
      });
    } catch (_) {}
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(token);
      }
    } catch (_) {}
  }

  /// Route from the notification tap that launched a terminated app, or null
  /// on a normal cold start. Consume once at startup and navigate to it.
  Future<String?> getInitialRoute() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) return null;
      return routeOf(message);
    } catch (_) {
      return null;
    }
  }

  /// Routes from taps while the app was backgrounded (not terminated).
  /// Merge with [NotificationService.onRouteTap] when handling tray taps.
  Stream<String> get onRouteOpened => _routes.stream;

  /// Current registration token, or null when FCM is unavailable.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Last token cached under [fcmTokenKey], without hitting the network.
  Future<String?> readCachedToken() async {
    try {
      final prefs = await _prefsFactory();
      return prefs.getString(fcmTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistToken(String token) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setString(fcmTokenKey, token);
    } catch (_) {}
  }

  AppNotification _toAppNotification(RemoteMessage message) {
    final notification = message.notification;
    return AppNotification(
      id:
          message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: notification?.title ?? "Nova",
      body: notification?.body ?? "",
      type: "fcm",
      route: routeOf(message),
      createdAt: DateTime.now(),
    );
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _refreshSub?.cancel();
    await _routes.close();
  }
}
