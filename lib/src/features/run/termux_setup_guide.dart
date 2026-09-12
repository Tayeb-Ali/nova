import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_providers.dart';

/// Shows the Termux setup checklist dialog.
Future<void> showTermuxSetupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const TermuxSetupDialog(),
  );
}

/// Checklist dialog for installing and configuring Termux execution support.
class TermuxSetupDialog extends ConsumerWidget {
  const TermuxSetupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Set up Termux execution'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _SetupStep(
                index: 1,
                title: 'Install Termux',
                body: 'Install Termux from GitHub releases or F-Droid. '
                    'The Play Store build is outdated and cannot run code.',
                command: null,
                hint: 'github.com/termux/termux-app/releases\n'
                    'f-droid.org/packages/com.termux',
              ),
              _SetupStep(
                index: 2,
                title: 'Allow external apps',
                body: 'Run this inside Termux, then restart Termux, so Nova '
                    'is allowed to send RUN_COMMAND intents.',
                command: 'mkdir -p ~/.termux && '
                    "printf 'allow-external-apps=true\n' >> "
                    '~/.termux/termux.properties && termux-reload-settings',
              ),
              _SetupStep(
                index: 3,
                title: 'Grant the RUN_COMMAND permission',
                body: 'Approve the permission prompt when Nova first runs '
                    'code. If you miss it, open Android Settings > Apps > '
                    'Nova and allow nearby/execution access, then try again.',
              ),
              _SetupStep(
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

class _SetupStep extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final String? command;
  final String? hint;

  const _SetupStep({
    required this.index,
    required this.title,
    required this.body,
    this.command,
    this.hint,
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
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
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
