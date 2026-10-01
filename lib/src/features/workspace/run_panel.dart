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
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final running = pid != null;
    final canRun = safeSelected != null && project != null && !running;
    _scrollToBottom();
    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        height: _consoleVisible ? 248 : 60,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Toolbar: [primary Run/Stop] [task selector] [clear] [collapse]
            // زر تشغيل واحد فقط — لا أيقونة حالة مكررة.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  // Primary action — the ONLY run/stop affordance.
                  SizedBox(
                    height: 44,
                    child: running
                        ? FilledButton.icon(
                            onPressed: () => _stop(pid),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.errorContainer,
                              foregroundColor: scheme.onErrorContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: Text(l10n.actionStop),
                          )
                        : FilledButton.icon(
                            onPressed: canRun
                                ? () => _run(safeSelected)
                                : null,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: Text(l10n.actionRun),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Task selector — fixed height, text always clipped INSIDE.
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        border: Border.all(color: scheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IdeTask>(
                          value: safeSelected,
                          isExpanded: true,
                          isDense: true,
                          borderRadius: BorderRadius.circular(12),
                          icon: Padding(
                            padding: const EdgeInsets.only(right: 8, left: 4),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.runNoTasks,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          selectedItemBuilder: (context) => [
                            for (final task in tasks)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  // Filenames are LTR even in an RTL UI —
                                  // keeps "index.php" inside the box.
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      task.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          items: [
                            for (final task in tasks)
                              DropdownMenuItem(
                                value: task,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          // Lock the selector while a process runs so the
                          // label can't drift mid-execution.
                          onChanged: running
                              ? null
                              : (task) {
                                  if (task != null) {
                                    ref
                                        .read(runTaskProvider.notifier)
                                        .state = task;
                                  }
                                },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ToolIconButton(
                    tooltip: l10n.runClearOutput,
                    icon: Icons.cleaning_services_outlined,
                    onPressed: output.isEmpty
                        ? null
                        : () => ref.read(runOutputProvider.notifier).clear(),
                  ),
                  const SizedBox(width: 8),
                  _ToolIconButton(
                    tooltip: _consoleVisible
                        ? l10n.runHideConsole
                        : l10n.runShowConsole,
                    icon: _consoleVisible
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    onPressed: () =>
                        setState(() => _consoleVisible = !_consoleVisible),
                  ),
                ],
              ),
            ),
            // Thin progress line while a process runs — no extra buttons.
            if (running)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: scheme.primary,
                ),
              )
            else
              Divider(height: 1, color: scheme.outlineVariant),
            if (_consoleVisible) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: output.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    running
                                        ? Icons.hourglass_top_rounded
                                        : Icons.terminal_rounded,
                                    size: 28,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    running
                                        ? l10n.runStartingProcess
                                        : l10n.runEmptyHint,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              output,
                              style: TextStyle(
                                fontFamily: "monospace",
                                fontSize: 12,
                                height: 1.5,
                                color: scheme.onSurface,
                              ),
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

/// Small 44×44 tonal icon button used for secondary toolbar actions.
class _ToolIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ToolIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.onSurfaceVariant,
          disabledBackgroundColor: scheme.surfaceContainerHigh.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
