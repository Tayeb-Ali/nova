import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/notifications/notification_model.dart';

void main() {
  group('AppNotification json', () {
    test('round-trip preserves every field', () {
      final original = AppNotification(
        id: 'msg-1',
        title: 'Hello',
        body: 'World',
        type: 'fcm',
        route: '/notifications',
        read: true,
        createdAt: DateTime.utc(2026, 5, 1, 12, 30),
      );
      final restored = AppNotification.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.type, original.type);
      expect(restored.route, original.route);
      expect(restored.read, original.read);
      expect(restored.createdAt, original.createdAt);
    });

    test('round-trip keeps a null route null', () {
      final original = AppNotification(
        id: 'msg-2',
        title: 't',
        body: 'b',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      final restored = AppNotification.fromJson(original.toJson());
      expect(restored.route, isNull);
      expect(restored.type, 'general');
      expect(restored.read, isFalse);
    });

    test('fromJson tolerates missing keys with safe defaults', () {
      final restored = AppNotification.fromJson(const <String, dynamic>{});
      expect(restored.id, isEmpty);
      expect(restored.title, isEmpty);
      expect(restored.body, isEmpty);
      expect(restored.type, 'general');
      expect(restored.route, isNull);
      expect(restored.read, isFalse);
      expect(
        restored.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });

  group('AppNotification value semantics', () {
    test('copyWith flips read without touching identity', () {
      final original = AppNotification(
        id: 'x',
        title: 't',
        body: 'b',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final read = original.copyWith(read: true);
      expect(read.read, isTrue);
      expect(read.id, 'x');
      expect(read, original);
    });

    test('equality is id-based', () {
      final a = AppNotification(
        id: 'same',
        title: 'one',
        body: 'b',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final b = AppNotification(
        id: 'same',
        title: 'two',
        body: 'other',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final c = AppNotification(
        id: 'other',
        title: 'one',
        body: 'b',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
