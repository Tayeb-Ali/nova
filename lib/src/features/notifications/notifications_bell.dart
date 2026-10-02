import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";

import "notifications_screen.dart";
import "notifications_store.dart";

/// Bell with unread badge for the [IdeShell] chrome: top-end overlay in the
/// narrow layout, rail leading in the wide layout. Tapping pushes the
/// [NotificationsScreen]; existing navigation is untouched.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final l10n = AppLocalizations.of(context);
    final button = IconButton(
      tooltip: l10n.notifTitle,
      icon: Icon(
        unread > 0 ? Icons.notifications : Icons.notifications_outlined,
      ),
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      },
    );
    if (unread <= 0) return button;
    return Badge.count(count: unread, maxCount: 99, child: button);
  }
}
