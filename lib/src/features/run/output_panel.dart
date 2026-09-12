import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_providers.dart';

/// Bottom-panel widget that shows the latest run stdout/stderr/exit code.
///
/// No fixed height: the parent decides how much space the panel gets.
/// [onRun] is invoked by the Run button (the editor wires the current tab);
/// when null, the button still renders but is disabled.
class OutputPanel extends ConsumerWidget {
  final VoidCallback? onRun;
  final VoidCallback? onClear;

  const OutputPanel({super.key, this.onRun, this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RunState runState = ref.watch(runStateProvider);
    final RunController controller = ref.read(runStateProvider.notifier);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBar(
          runState: runState,
          onRun: onRun,
          onClear: onClear ?? controller.clear,
        ),
        const Divider(height: 1),
        Expanded(child: _OutputBody(runState: runState, theme: theme)),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final RunState runState;
  final VoidCallback? onRun;
  final VoidCallback onClear;

  const _StatusBar({
    required this.runState,
    required this.onRun,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _StatusChip(status: runState.status),
          const SizedBox(width: 8),
          if (runState.exitCode != null)
            Text(
              'exit ${runState.exitCode}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (runState.message.isNotEmpty &&
              runState.status != RunStatus.idle) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                runState.message,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          TextButton.icon(
            onPressed: runState.status == RunStatus.running ? null : onRun,
            icon: runState.status == RunStatus.running
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, size: 16),
            label: const Text('Run'),
          ),
          TextButton.icon(
            onPressed: runState.status == RunStatus.running ? null : onClear,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RunStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (String label, Color color) = switch (status) {
      RunStatus.idle => ('idle', theme.colorScheme.onSurfaceVariant),
      RunStatus.running => ('running', theme.colorScheme.primary),
      RunStatus.success => ('success', Colors.green),
      RunStatus.error => ('error', theme.colorScheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _OutputBody extends StatelessWidget {
  final RunState runState;
  final ThemeData theme;

  const _OutputBody({required this.runState, required this.theme});

  static const TextStyle _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    if (runState.status == RunStatus.idle) {
      return Center(
        child: Text(
          'Press Run to execute the current file with Termux.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (runState.stdout.isNotEmpty)
            SelectableText(runState.stdout, style: _mono),
          if (runState.stderr.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              runState.stderr,
              style: _mono.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (runState.stdout.isEmpty && runState.stderr.isEmpty)
            Text(
              runState.status == RunStatus.running
                  ? 'Waiting for output...'
                  : '(no output)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
