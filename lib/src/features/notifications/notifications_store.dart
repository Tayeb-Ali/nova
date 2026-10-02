import "dart:async";
import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/legacy.dart";
import "package:shared_preferences/shared_preferences.dart";

import "notification_model.dart";

/// In-app notification center state: newest-first list persisted as JSON.
///
/// Storage key: `nova.notifications` (a JSON array of [AppNotification]).
/// The newest entries sort first; the list is capped at [maxStored] so a
/// noisy topic can never grow SharedPreferences without bound.
class NotificationsStore extends StateNotifier<List<AppNotification>> {
  static const String storageKey = "nova.notifications";
  static const int maxStored = 100;

  final DateTime Function() _clock;
  final SharedPreferences? _prefsOverride;

  NotificationsStore({DateTime Function()? clock, this._prefsOverride})
    : _clock = clock ?? DateTime.now,
       super(const <AppNotification>[]) {
    unawaited(_load());
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final items = <AppNotification>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final item = AppNotification.fromJson(entry);
          if (item.id.isNotEmpty) items.add(item);
        }
      }
      state = items;
    } catch (_) {
      // Corrupt cache: start empty rather than crashing the shell.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await _prefs();
      final raw = jsonEncode(
        state.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(storageKey, raw);
    } catch (_) {
      // Persistence is best-effort; the in-memory list stays authoritative.
    }
  }

  /// Inserts [item] at the front, replacing any same-id entry, then persists.
  Future<void> push(AppNotification item) async {
    final next = <AppNotification>[item];
    for (final existing in state) {
      if (existing.id != item.id) next.add(existing);
    }
    while (next.length > maxStored) {
      next.removeLast();
    }
    state = next;
    await _save();
  }

  /// Convenience constructor + [push]: mints id/createdAt from the clock.
  Future<AppNotification> pushNew({
    required String title,
    required String body,
    String type = "general",
    String? route,
  }) async {
    final now = _clock();
    final item = AppNotification(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      route: route,
      createdAt: now,
    );
    await push(item);
    return item;
  }

  /// Marks one entry read (no-op for unknown ids), then persists.
  Future<void> markRead(String id) async {
    var changed = false;
    state = state.map((item) {
      if (item.id == id && !item.read) {
        changed = true;
        return item.copyWith(read: true);
      }
      return item;
    }).toList();
    if (changed) await _save();
  }

  /// Marks every entry read, then persists.
  Future<void> markAllRead() async {
    if (state.every((item) => item.read)) return;
    state = state.map((item) => item.copyWith(read: true)).toList();
    await _save();
  }

  /// Drops one entry (no-op for unknown ids), then persists.
  Future<void> remove(String id) async {
    final next = state.where((item) => item.id != id).toList();
    if (next.length == state.length) return;
    state = next;
    await _save();
  }

  /// Drops every entry, then persists.
  Future<void> clear() async {
    if (state.isEmpty) return;
    state = const <AppNotification>[];
    await _save();
  }
}

final notificationsStoreProvider =
    StateNotifierProvider<NotificationsStore, List<AppNotification>>(
      (ref) => NotificationsStore(),
    );

/// Badge count for the shell bell: number of unread entries.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsStoreProvider).where((n) => !n.read).length;
});
