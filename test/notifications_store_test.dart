import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/src/features/notifications/notification_model.dart';
import 'package:nova/src/features/notifications/notifications_store.dart';

AppNotification _item(String id, {bool read = false}) => AppNotification(
  id: id,
  title: 'title $id',
  body: 'body $id',
  createdAt: DateTime.utc(2026, 1, 1),
  read: read,
);

/// Lets the store's unawaited initial load finish before assertions.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Backs SharedPreferences with an in-memory mock on the test messenger;
    // no device needed.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('push inserts newest-first and replaces same-id entries', () async {
    final store = NotificationsStore();
    await _settle();
    await store.push(_item('a'));
    await store.push(_item('b'));
    expect(store.state.map((n) => n.id).toList(), <String>['b', 'a']);

    await store.push(_item('a'));
    expect(store.state.map((n) => n.id).toList(), <String>['a', 'b']);
  });

  test('markRead marks one entry; unknown ids are a no-op', () async {
    final store = NotificationsStore();
    await _settle();
    await store.push(_item('a'));
    await store.push(_item('b'));

    await store.markRead('missing');
    expect(store.state.every((n) => !n.read), isTrue);

    await store.markRead('a');
    expect(store.state.firstWhere((n) => n.id == 'a').read, isTrue);
    expect(store.state.firstWhere((n) => n.id == 'b').read, isFalse);
  });

  test('markAllRead marks everything read', () async {
    final store = NotificationsStore();
    await _settle();
    await store.push(_item('a'));
    await store.push(_item('b'));

    await store.markAllRead();
    expect(store.state.every((n) => n.read), isTrue);
  });

  test('remove drops one entry; unknown ids are a no-op', () async {
    final store = NotificationsStore();
    await _settle();
    await store.push(_item('a'));
    await store.push(_item('b'));

    await store.remove('missing');
    expect(store.state.length, 2);

    await store.remove('a');
    expect(store.state.map((n) => n.id).toList(), <String>['b']);
  });

  test('list is capped at maxStored, newest first', () async {
    final store = NotificationsStore();
    await _settle();
    for (var i = 0; i < NotificationsStore.maxStored + 5; i++) {
      await store.push(_item('id-$i'));
    }
    expect(store.state.length, NotificationsStore.maxStored);
    expect(store.state.first.id, 'id-${NotificationsStore.maxStored + 4}');
  });

  test('state persists across store instances', () async {
    final first = NotificationsStore();
    await _settle();
    await first.push(_item('kept'));
    expect(first.state.length, 1);

    final second = NotificationsStore();
    await _settle();
    expect(second.state.map((n) => n.id).toList(), <String>['kept']);
  });

  test('unreadCountProvider reflects unread entries', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = container.read(notificationsStoreProvider.notifier);
    await _settle();
    await store.push(_item('a'));
    await store.push(_item('b'));
    expect(container.read(unreadCountProvider), 2);

    await store.markRead('a');
    expect(container.read(unreadCountProvider), 1);

    await store.markAllRead();
    expect(container.read(unreadCountProvider), 0);
  });
}
