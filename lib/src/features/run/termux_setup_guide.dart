import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_providers.dart';
import 'termux_installer.dart';

/// Shows the Termux setup checklist dialog.
Future<void> showTermuxSetupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const TermuxSetupDialog(),
  );
}

/// Checklist dialog for installing and configuring Termux execution support.
class TermuxSetupDialog extends ConsumerStatefulWidget {
  const TermuxSetupDialog({super.key});

  @override
  ConsumerState<TermuxSetupDialog> createState() =>
      _TermuxSetupDialogState();
}

enum _DlState { idle, downloading, downloaded, failed }

class _TermuxSetupDialogState extends ConsumerState<TermuxSetupDialog> {
  _DlState _dl = _DlState.idle;
  double _progress = 0;
  String? _apkPath;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _dl = _DlState.downloading;
      _progress = 0;
      _error = null;
    });
    try {
      final path = await TermuxInstaller().downloadApk(
        onProgress: (rx, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = rx / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _dl = _DlState.downloaded;
        _apkPath = path;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dl = _DlState.failed;
        _error = '$e';
      });
    }
  }

  Future<void> _install() async {
    if (_apkPath == null) return;
    final installer = TermuxInstaller();
    final messenger = ScaffoldMessenger.of(context);
    if (!await installer.canRequestInstalls()) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Allow "Install unknown apps" for Nova first. Opening settings...',
          ),
        ),
      );
      await installer.openInstallPermissionSettings();
      return;
    }
    try {
      await installer.installApk(_apkPath!);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Installer failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set up Termux execution'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TermuxDownloadCard(
                state: _dl,
                progress: _progress,
                error: _error,
                onDownload: _download,
                onInstall: _install,
              ),
              const _SetupStep(
                index: 2,
                title: 'Allow external apps',
                body: 'Run this inside Termux, then restart Termux, so Nova '
                    'is allowed to send RUN_COMMAND intents.',
                command: 'mkdir -p ~/.termux && '
                    "printf 'allow-external-apps=true\n' >> "
                    '~/.termux/termux.properties && termux-reload-settings',
              ),
              const _SetupStep(
                index: 3,
                title: 'Grant the RUN_COMMAND permission',
                body: 'Approve the permission prompt when Nova first runs '
                    'code. If you miss it, open Android Settings > Apps > '
                    'Nova and allow nearby/execution access, then try again.',
              ),
              const _SetupStep(
                index: 4,
                title: 'Install interpreters',
                body: 'Run this inside Termux to install the runtimes Nova '
                    'uses for Python, JavaScript and PHP.',
                command: 'pkg update && pkg install -y python nodejs php',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => _checkAgain(context, ref),
          child: const Text('Check again'),
        ),
      ],
    );
  }

  Future<void> _checkAgain(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final bool installed =
        await ref.read(termuxBridgeProvider).isTermuxInstalled();
    if (!context.mounted) return;
    if (installed) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Termux detected. You can now run code.')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Termux still not detected. Finish the steps above.'),
        ),
      );
    }
  }
}

/// Step 1 card: one-tap official APK download + install, with manual links.
class _TermuxDownloadCard extends StatelessWidget {
  final _DlState state;
  final double progress;
  final String? error;
  final Future<void> Function() onDownload;
  final Future<void> Function() onInstall;

  const _TermuxDownloadCard({
    required this.state,
    required this.progress,
    required this.error,
    required this.onDownload,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final installer = TermuxInstaller();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 12, child: Text('1')),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Install Termux', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Official F-Droid build (~109 MB). '
                  'The Play Store build is outdated and cannot run code.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (state == _DlState.downloading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text(
                        'Downloading ${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  )
                else if (state == _DlState.downloaded)
                  FilledButton.icon(
                    onPressed: onInstall,
                    icon: const Icon(Icons.install_mobile),
                    label: const Text('Install Termux now'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Termux'),
                  ),
                if (state == _DlState.failed && error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Download failed: $error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          installer.openUrl(TermuxSources.fdroidPage),
                      child: const Text('F-Droid page'),
                    ),
                    TextButton(
                      onPressed: () =>
                          installer.openUrl(TermuxSources.githubReleases),
                      child: const Text('GitHub releases'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final String? command;

  const _SetupStep({
    required this.index,
    required this.title,
    required this.body,
    this.command,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
                if (command != null) ...[
                  const SizedBox(height: 4),
                  _CommandBlock(command: command!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  final String command;

  const _CommandBlock({required this.command});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: command));
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }
}
