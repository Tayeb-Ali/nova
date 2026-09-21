import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";

import "../../core/models/task.dart";
import "../../core/services/process_service.dart";
import "workspace_providers.dart";

/// Run toolbar + live output stream from the active project (task.md §20–§21).
class RunPanel extends ConsumerStatefulWidget {
  const RunPanel({super.key});

  @override
  ConsumerState<RunPanel> createState() => _RunPanelState();
}

class _RunPanelState extends ConsumerState<RunPanel> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ProcessEvent>? _sub;
  bool _consoleVisible = true;

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _append(String chunk) {
    ref.read(runOutputProvider.notifier).append(chunk);
  }

  Future<void> _run(IdeTask task) async {
    final l10n = AppLocalizations.of(context);
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    // Re-show the console when the user runs a task even if it was collapsed.
    if (!_consoleVisible) {
      setState(() => _consoleVisible = true);
    }
    ref.read(runOutputProvider.notifier).clear();
    final script = 'cd "${project.path}" && ${task.command} ${task.args ?? ""}'
        .trim();
    String pid;
    try {
      final info = await ref
          .read(processServiceProvider)
          .start(command: "sh", args: ["-lc", script], cwd: project.path);
      pid = info.pid;
    } catch (e) {
      _append("${l10n.runStartFailed("$e")}\n");
      return;
    }
    _append("[$script]\n");
    ref.read(runningPidProvider.notifier).state = pid;
    _listen(pid);
  }

  void _listen(String pid) {
    _sub?.cancel();
    _sub = ref
        .read(processServiceProvider)
        .eventStream
        .listen(
          (event) {
            if (event.pid != pid) return;
            if (event.output.isNotEmpty) _append(event.output);
            if (event.exited) {
              _append("\n[Process exited (code ${event.exitCode})]\n");
              ref.read(runningPidProvider.notifier).state = null;
              _sub?.cancel();
              _sub = null;
            }
          },
          onError: (Object e) {
            _append("Task stream error: $e\n");
            ref.read(runningPidProvider.notifier).state = null;
            _sub?.cancel();
            _sub = null;
          },
        );
  }

  Future<void> _stop(String pid) async {
    _sub?.cancel();
    _sub = null;
    try {
      await ref.read(processServiceProvider).kill(pid);
    } catch (_) {
      // The process may have already exited.
    }
    _append("\n[Stopped]\n");
    ref.read(runningPidProvider.notifier).state = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(runTasksProvider);
    final selected = ref.watch(runTaskProvider);
    final safeSelected = tasks.isNotEmpty && tasks.contains(selected)
        ? selected
        : null;
    final pid = ref.watch(runningPidProvider);
    final output = ref.watch(runOutputProvider);
    final project = ref.watch(activeProjectProvider);
    final scheme = Theme.of(context).colorScheme;
    _scrollToBottom();
    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        height: _consoleVisible ? 220 : 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      pid == null ? Icons.play_arrow : Icons.stop,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        border: Border.all(color: scheme.outlineVariant),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<IdeTask>(
                        value: safeSelected,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          AppLocalizations.of(context).runNoTasks,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        selectedItemBuilder: (context) => [
                          for (final task in tasks)
                            Text(task.name, overflow: TextOverflow.ellipsis),
                        ],
                        items: [
                          for (final task in tasks)
                            DropdownMenuItem(
                              value: task,
                              child: Text(
                                task.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (task) {
                          if (task != null) {
                            ref.read(runTaskProvider.notifier).state = task;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (pid == null)
                    FilledButton.icon(
                      onPressed: (safeSelected == null || project == null)
                          ? null
                          : () => _run(safeSelected),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(AppLocalizations.of(context).actionRun),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _stop(pid),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.errorContainer,
                        foregroundColor: scheme.onErrorContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.stop, size: 18),
                      label: Text(AppLocalizations.of(context).actionStop),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () =>
                        ref.read(runOutputProvider.notifier).clear(),
                    tooltip: AppLocalizations.of(context).runClearOutput,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(
                      Icons.cleaning_services_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () =>
                        setState(() => _consoleVisible = !_consoleVisible),
                    tooltip: _consoleVisible
                        ? AppLocalizations.of(context).runHideConsole
                        : AppLocalizations.of(context).runShowConsole,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: Icon(
                      _consoleVisible
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (_consoleVisible) ...[
              Divider(height: 1, color: scheme.outlineVariant),
              Expanded(
                child: output.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          pid != null
                              ? AppLocalizations.of(context).runStartingProcess
                              : AppLocalizations.of(context).runEmptyHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          border: Border.all(color: scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          child: SelectableText(
                            output,
                            style: TextStyle(
                              fontFamily: "monospace",
                              fontSize: 11,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
