// Self-contained account card for embedding in SettingsScreen.
//
// Signed out: avatar placeholder + [authSignedOut] subtitle + Sign-in button
// that pushes [LoginScreen]. Signed in: avatar initial + displayName/email +
// provider badges, verify-email banner, Sign-out + Delete-account (confirm
// dialog). The INTEGRATION agent places this in Settings — this file only
// exports the widget. Guest-first: nothing here gates any route.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../l10n/generated/app_localizations.dart";
import "auth_providers.dart";
import "login_screen.dart";

/// Drop-in `const AccountCard()` anywhere in Settings.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.authAccount.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            if (user == null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(l10n.authAccount.characters.first),
                ),
                title: Text(l10n.authSignedOut),
                subtitle: Text(l10n.authGuestNote),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(l10n.authTitle),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(_initialFor(user.displayName ?? user.email ?? "")),
                ),
                title: Text(
                  user.displayName ?? user.email ?? l10n.authAccount,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: user.displayName != null
                    ? Text(user.email ?? "", overflow: TextOverflow.ellipsis)
                    : null,
              ),
              if (user.providerData.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final info in user.providerData)
                      Chip(
                        label: Text(
                          info.providerId,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              if (!user.emailVerified) ...[
                const SizedBox(height: 8),
                _VerifyBanner(onResend: () => _resend(context, ref)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _signOut(context, ref),
                      child: Text(l10n.authLogout),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      onPressed: () => _confirmDelete(context, ref),
                      child: Text(l10n.authDelete),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initialFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "?";
    return trimmed.characters.first.toUpperCase();
  }

  Future<void> _resend(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final resent = l10n.authResent;
    final result = await ref.read(authServiceProvider).sendEmailVerification();
    if (!context.mounted) return;
    if (result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(resent)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    if (!result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              AppLocalizations.of(dialogContext).authDeleteTitle,
            ),
            content: Text(AppLocalizations.of(dialogContext).authDeleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  AppLocalizations.of(dialogContext).actionCancel,
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppLocalizations.of(dialogContext).authDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final result = await ref.read(authServiceProvider).deleteAccount();
    if (!context.mounted) return;
    if (!result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

/// Verify-email banner shown when `user != null && !emailVerified`.
class _VerifyBanner extends StatelessWidget {
  final VoidCallback onResend;

  const _VerifyBanner({required this.onResend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(l10n.authVerifyBanner)),
          const SizedBox(width: 8),
          TextButton(onPressed: onResend, child: Text(l10n.authResend)),
        ],
      ),
    );
  }
}
