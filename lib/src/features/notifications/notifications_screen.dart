import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nova/l10n/generated/app_localizations.dart";

import "../../core/services/fcm_service.dart";
import "../../core/ui/empty_state.dart";
import "notification_model.dart";
import "notifications_store.dart";

/// Notification center: list, empty state, tap-to-open + tap-to-route,
/// per-row delete, and a mark-all-read AppBar action.
///
/// Also surfaces the FCM registration token (copy button) so testers can
/// target this install from the Firebase console.
class NotificationsScreen extends ConsumerStatefulWidget {
  static const String routeName = "/notifications";

  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Created lazily in [_loadToken]: the constructor touches
  // `FirebaseMessaging.instance`, which throws with no Firebase app (widget
  // tests, offline first-run), so it must never run during State creation.
  String? _token;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    String? token;
    try {
      final fcm = FcmService();
      token = await fcm.getToken() ?? await fcm.readCachedToken();
    } catch (_) {
      token = null;
    }
    if (!mounted) return;
    setState(() {
      _token = token;
      _loadingToken = false;
    });
  }

  Future<void> _copyToken(AppLocalizations l10n) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: token));
    } catch (_) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.notifTokenCopied)));
  }

  void _open(AppNotification item) {
    unawaited(ref.read(notificationsStoreProvider.notifier).markRead(item.id));
    final route = item.route;
    if (route == null || route.isEmpty) return;
    try {
      unawaited(Navigator.of(context).pushNamed(route));
    } catch (_) {
      // Route not registered (integration agent owns the route table):
      // the tap still marked the entry read.
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case "fcm":
        return Icons.cloud_outlined;
      case "runtime":
        return Icons.memory_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _format(AppLocalizations l10n, DateTime when) {
    try {
      return DateFormat.yMMMd(
        l10n.localeName,
      ).add_Hm().format(when.toLocal());
    } catch (_) {
      return when.toLocal().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(notificationsStoreProvider);
    final unread = ref.watch(unreadCountProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifTitle),
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: l10n.notifMarkAllRead,
              icon: const Icon(Icons.done_all_outlined),
              onPressed: () => unawaited(
                ref.read(notificationsStoreProvider.notifier).markAllRead(),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_loadingToken && _token != null && _token!.isNotEmpty)
            ListTile(
              dense: true,
              leading: const Icon(Icons.key_outlined),
              title: Text(
                _token!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                tooltip: l10n.notifCopyToken,
                icon: const Icon(Icons.copy_outlined),
                onPressed: () => _copyToken(l10n),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: l10n.notifEmpty,
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _iconFor(item.type),
                              color: item.read
                                  ? scheme.onSurfaceVariant
                                  : scheme.primary,
                            ),
                            if (!item.read)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: item.read
                              ? null
                              : const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.body.isNotEmpty)
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              _format(l10n, item.createdAt),
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: item.body.isNotEmpty,
                        onTap: () => _open(item),
                        trailing: IconButton(
                          tooltip: l10n.notifDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => unawaited(
                            ref
                                .read(notificationsStoreProvider.notifier)
                                .remove(item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
