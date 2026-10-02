// Optional-login screen: guest-first, no route guards, no forced redirects.
//
// Segments [Login|Signup], email+password form with validation, social rows
// (Google / X / GitHub), error line, loading state, forgot-password dialog,
// and a verify-email banner when `user != null && !emailVerified`.
// RTL comes from the inherited [Directionality] (nothing here forces LTR).
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../l10n/generated/app_localizations.dart";
import "auth_providers.dart";
import "auth_service.dart";

/// Push with `Navigator.of(context).push(MaterialPageRoute(...))`.
/// Pops itself on success; nothing else in the app redirects because of auth.
///
/// Gate mode: pass [onExit] (used by the first-run flow where this screen is
/// root content, not pushed — there is nothing to pop). Then success and
/// "continue as guest" call [onExit] instead of popping, and the AppBar shows
/// no back button so the user picks one of the offered choices.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onExit});

  /// Called instead of [Navigator.pop] on success and on guest-continue.
  final VoidCallback? onExit;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = ref.read(authServiceProvider);
    final email = _emailCtrl.text;
    final password = _passwordCtrl.text;
    final isLogin = _isLogin;
    final navigator = Navigator.of(context);
    final result = isLogin
        ? await service.signInEmail(email, password)
        : await service.signUpEmail(email, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      navigator.pop();
    } else {
      setState(() => _error = result.message);
    }
  }

  Future<void> _social(Future<AuthResult> Function() call) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final result = await call();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      final exit = widget.onExit;
      if (exit != null) {
        exit();
      } else {
        navigator.pop();
      }
    } else {
      setState(() => _error = result.message);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final messenger = ScaffoldMessenger.of(context);
    final sent = l10n.authSent;
    try {
      final email = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(dialogContext).authForgotTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(dialogContext).authForgotHint),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(dialogContext).authEmail,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext).actionCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(emailCtrl.text.trim()),
              child: Text(AppLocalizations.of(dialogContext).authSend),
            ),
          ],
        ),
      );
      if (email == null || email.isEmpty || !mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });
      final result = await ref
          .read(authServiceProvider)
          .sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _loading = false);
      if (result.ok) {
        messenger.showSnackBar(SnackBar(content: Text(sent)));
      } else {
        setState(() => _error = result.message);
      }
    } finally {
      emailCtrl.dispose();
    }
  }

  Future<void> _resendVerification() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final resent = l10n.authResent;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(authServiceProvider).sendEmailVerification();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(resent)));
    } else {
      setState(() => _error = result.message);
    }
  }

  /// Guest entry: best-effort Firebase anonymous sign-in (the user then shows
  /// up in the owner's Firebase Console under Authentication > Users), then
  /// always proceeds — offline just means a fully local guest.
  Future<void> _continueAsGuest() async {
    final navigator = Navigator.of(context);
    final exit = widget.onExit;
    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (_) {
      // Best-effort only; guest mode never depends on the network.
    }
    if (!mounted) return;
    if (exit != null) {
      exit();
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    // Anonymous guests have no email: no verify banner for them.
    final showVerifyBanner =
        user != null && user.email != null && !user.emailVerified;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Gate mode is root content: no back button, the user picks a choice.
      appBar: AppBar(
        title: Text(l10n.authTitle),
        automaticallyImplyLeading: widget.onExit == null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.authLogin)),
                  ButtonSegment(value: false, label: Text(l10n.authSignup)),
                ],
                selected: {_isLogin},
                onSelectionChanged: _loading
                    ? null
                    : (selected) => setState(() {
                        _isLogin = selected.first;
                        _error = null;
                      }),
              ),
              const SizedBox(height: 16),
              if (showVerifyBanner)
                Card(
                  color: scheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.authVerifyBanner)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _loading ? null : _resendVerification,
                          child: Text(l10n.authResend),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showVerifyBanner) const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.authEmail),
                      validator: (v) {
                        final value = (v ?? "").trim();
                        if (value.isEmpty ||
                            !value.contains("@") ||
                            !value.contains(".")) {
                          return l10n.authInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.authPassword,
                        suffixIcon: IconButton(
                          tooltip: l10n.authPassword,
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? "").length < 6) {
                          return l10n.authPasswordTooShort;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? l10n.authLogin : l10n.authSignup,
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: Text(l10n.authForgot),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _SocialRow(
                enabled: !_loading,
                avatarText: "G",
                label: l10n.authGoogle,
                onPressed: () => _social(
                  () => ref.read(authServiceProvider).signInGoogle(),
                ),
              ),
              const SizedBox(height: 8),
              _SocialRow(
                enabled: !_loading,
                avatarText: "X",
                label: l10n.authX,
                onPressed: () => _social(
                  () => ref.read(authServiceProvider).signInX(),
                ),
              ),
              const SizedBox(height: 8),
              _SocialRow(
                enabled: !_loading,
                avatarText: "</>",
                label: l10n.authGithub,
                onPressed: () => _social(
                  () => ref.read(authServiceProvider).signInGitHub(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.authGuestNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _loading ? null : () => _continueAsGuest(),
                  child: Text(l10n.authContinueAsGuest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined button with an icon-ish avatar + label row.
class _SocialRow extends StatelessWidget {
  final bool enabled;
  final String avatarText;
  final String label;
  final VoidCallback onPressed;

  const _SocialRow({
    required this.enabled,
    required this.avatarText,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              child: Text(avatarText, style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
