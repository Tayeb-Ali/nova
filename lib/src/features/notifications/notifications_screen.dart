import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nova/l10n/generated/app_localizations.dart";

import "../../core/services/fcm_service.dart";
import "../../core/services/notification_service.dart";
import "../../core/ui/empty_state.dart";
import "../tour/tour.dart";
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
  // Push diagnostics (fix 6): loaded together with the token.
  bool? _permEnabled;
  List<String> _topics = const [];
  String? _lastTap;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    String? token;
    bool? perm;
    List<String> topics = const [];
    String? lastTap;
    try {
      final fcm = FcmService();
      token = await fcm.getToken() ?? await fcm.readCachedToken();
      topics = await fcm.readSubscribedTopics();
    } catch (_) {
      token = null;
    }
    try {
      perm = await NotificationService.instance.areNotificationsEnabled();
    } catch (_) {
      perm = null;
    }
    try {
      lastTap = await NotificationService.readLastRouteTap();
    } catch (_) {
      lastTap = null;
    }
    if (!mounted) return;
    setState(() {
      _token = token;
      _loadingToken = false;
      _permEnabled = perm;
      _topics = topics;
      _lastTap = lastTap;
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
              key: TourKeys.notifMarkRead,
              tooltip: l10n.notifMarkAllRead,
              icon: const Icon(Icons.done_all_outlined),
              onPressed: () => unawaited(
                ref.read(notificationsStoreProvider.notifier).markAllRead(),
              ),
            ),
          const TourButton(
            tourId: 'notif',
            buildTargets: buildNotifTargets,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loadingToken)
            _DiagnosticsCard(
              token: (_token != null && _token!.isNotEmpty) ? _token! : null,
              onCopyToken: () => _copyToken(l10n),
              permEnabled: _permEnabled,
              topics: _topics,
              lastTap: _lastTap,
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

/// Push-diagnostics card: token (copy), permission state, subscribed topics,
/// last tap route. Values are language-neutral (✓/✗, topic names, route),
/// only the row labels are localized.
class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.token,
    required this.onCopyToken,
    required this.permEnabled,
    required this.topics,
    required this.lastTap,
  });

  final String? token;
  final VoidCallback onCopyToken;
  final bool? permEnabled;
  final List<String> topics;
  final String? lastTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final perm = permEnabled;
    final tapRoute = (lastTap == null || lastTap!.isEmpty)
        ? "–"
        : lastTap!.split("|").first;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_outlined),
              title: Text(
                l10n.notifDiagTitle,
                style: textTheme.titleSmall,
              ),
            ),
            if (token != null)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key_outlined),
                title: Text(
                  token!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  tooltip: l10n.notifCopyToken,
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: onCopyToken,
                ),
              ),
            _diagRow(
              context,
              icon: Icons.notifications_active_outlined,
              label: l10n.notifDiagPermission,
              value: perm == null ? "?" : (perm ? "✓" : "✗"),
              valueColor: perm == null
                  ? scheme.onSurfaceVariant
                  : (perm ? Colors.green : scheme.error),
            ),
            _diagRow(
              context,
              icon: Icons.forum_outlined,
              label: l10n.notifDiagTopics,
              value: topics.isEmpty ? "–" : topics.join(", "),
              valueColor: scheme.onSurfaceVariant,
            ),
            _diagRow(
              context,
              icon: Icons.touch_app_outlined,
              label: l10n.notifDiagLastTap,
              value: tapRoute,
              valueColor: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: textTheme.bodyMedium),
      trailing: Text(
        value,
        style: textTheme.bodyMedium?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
