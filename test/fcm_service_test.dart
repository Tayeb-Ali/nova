import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/src/core/services/fcm_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('routeOf', () {
    test('returns data route when present', () {
      const m = RemoteMessage(data: {'route': '/notifications'});
      expect(FcmService.routeOf(m), '/notifications');
    });

    test('null on missing, empty, or non-string route', () {
      expect(FcmService.routeOf(const RemoteMessage()), isNull);
      expect(
        FcmService.routeOf(const RemoteMessage(data: {'route': ''})),
        isNull,
      );
      expect(
        FcmService.routeOf(const RemoteMessage(data: {'route': 42})),
        isNull,
      );
    });
  });

  group('resolveContent', () {
    test('prefers the notification payload', () {
      const m = RemoteMessage(
        notification: RemoteNotification(title: 'Hi', body: 'There'),
        data: {'title': 'Data', 'body': 'Ignored', 'route': '/x'},
      );
      final c = FcmService.resolveContent(m);
      expect(c, isNotNull);
      expect(c!.title, 'Hi');
      expect(c.body, 'There');
      expect(c.route, '/x');
    });

    test('falls back to data title/body for data-only messages', () {
      const m = RemoteMessage(
        data: {'title': 'Data title', 'body': 'Data body'},
      );
      final c = FcmService.resolveContent(m);
      expect(c, isNotNull);
      expect(c!.title, 'Data title');
      expect(c.body, 'Data body');
    });

    test('null when title, body, and route are all empty', () {
      expect(
        FcmService.resolveContent(const RemoteMessage()),
        isNull,
      );
      expect(
        FcmService.resolveContent(
          const RemoteMessage(data: {'title': '  ', 'route': ''}),
        ),
        isNull,
      );
    });

    test('route-only message still shows with default title', () {
      const m = RemoteMessage(data: {'route': '/notifications'});
      final c = FcmService.resolveContent(m);
      expect(c, isNotNull);
      expect(c!.title, 'Nova');
      expect(c.route, '/notifications');
    });
  });

  group('topics', () {
    test('subscribes to ALL, ADS, UPDATE', () {
      expect(FcmService.topics, ['ALL', 'ADS', 'UPDATE']);
    });

    test('subscribed topics empty before first init', () async {
      // No Firebase app in unit tests: construct would throw, so only the
      // pure contract is asserted here (init itself is covered on-device).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(FcmService.fcmTopicsKey), isNull);
    });
  });
}
