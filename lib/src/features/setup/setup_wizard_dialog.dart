import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nova/l10n/generated/app_localizations.dart';

import '../../core/app_config.dart';
import '../../core/bridge/events_bus.dart';
import '../../core/services/setup_service.dart';

/// First-run setup wizard (NEXT_PLAN 3.2): slim/full choice + progress +
/// retry/resume after failure.
///
/// Reuses [SetupService] (variant persisted under
/// [AppConfig.bootstrapVariantKey] for the Kotlin installer) and the shared
/// [IdeEventBus] stream (`setupProgress` / `setupCompleted` / `setupFailed`).
/// Resume semantics come from the native installer: a fully downloaded zip
/// whose SHA-256 matches is reused, so retrying after a failure does not
/// re-download (`BootstrapInstaller.install`).
Future<bool?> showSetupWizard(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SetupWizardDialog(),
  );
}

/// Wizard dialog: 0 choose variant → 1 download/install → 2 done.
///
/// [events] overrides the [IdeEventBus] stream (tests feed a
/// `StreamController` instead of touching the native event channel).
/// [setupService] is injectable for the same reason.
class SetupWizardDialog extends StatefulWidget {
  const SetupWizardDialog({super.key, this.events, this.setupService});

  final Stream<dynamic>? events;
  final SetupService? setupService;

  @override
  State<SetupWizardDialog> createState() => _SetupWizardDialogState();
}

class _SetupWizardDialogState extends State<SetupWizardDialog> {
  SetupService get _service => widget.setupService ?? SetupService();

  StreamSubscription<dynamic>? _events;
  String _variant = AppConfig.bootstrapVariantSlim;
  bool _started = false;
  bool _running = false;
  bool _done = false;
  String? _phase;
  double _fraction = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _events = (widget.events ?? IdeEventBus.instance.stream).listen(
      _onEvent,
      onError: (Object _) {},
    );
    _loadVariant();
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _loadVariant() async {
    try {
      final stored = await _service.getBootstrapVariant();
      if (!mounted) return;
      setState(() => _variant = stored);
    } catch (_) {
      // Keep default (slim).
    }
  }

  Future<void> _selectVariant(String? value) async {
    if (value == null || _running) return;
    setState(() {
      _variant = value;
      // Switching variant after a failure clears the old error so the
      // user gets a clean retry for the newly chosen download.
      if (_error != null && !_started) _error = null;
    });
    try {
      await _service.setBootstrapVariant(value);
    } catch (_) {
      // Persist failure is non-fatal; Kotlin defaults to slim.
    }
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _running = true;
      _done = false;
      _error = null;
      _phase = null;
      _fraction = 0;
    });
    try {
      await _service.setBootstrapVariant(_variant);
      await _service.startSetup();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = e.toString();
      });
    }
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map || !mounted) return;
    switch (raw['event'] as String?) {
      case 'setupProgress':
        setState(() {
          _started = true;
          _running = true;
          _phase = raw['phase'] as String?;
          final dynamic fraction = raw['fraction'];
          _fraction = fraction is num
              ? fraction.toDouble().clamp(0.0, 1.0)
              : 0.0;
        });
        break;
      case 'setupCompleted':
        setState(() {
          _running = false;
          _done = true;
          _error = null;
          _phase = null;
          _fraction = 1;
        });
        break;
      case 'setupFailed':
        setState(() {
          _running = false;
          _error =
              raw['error'] as String? ??
              AppLocalizations.of(context).runtimeSetupFailed;
        });
        break;
    }
  }

  int get _step => _done ? 2 : (_started ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.bootstrapRequired),
      content: SizedBox(
        width: double.maxFinite,
        child: Stepper(
          currentStep: _step,
          controlsBuilder: (_, _) => const SizedBox.shrink(),
          steps: [
            Step(
              title: Text(l10n.runtimeBootstrap),
              isActive: _step >= 0,
              state: _step > 0 ? StepState.complete : StepState.indexed,
              content: _buildChooseStep(),
            ),
            Step(
              title: Text(l10n.runtimeStartSetup),
              isActive: _step >= 1,
              state: _done
                  ? StepState.complete
                  : (_error != null ? StepState.error : StepState.indexed),
              content: _buildProgressStep(l10n),
            ),
            Step(
              title: Text(l10n.runtimeReady),
              isActive: _done,
              state: _done ? StepState.complete : StepState.indexed,
              content: _buildDoneStep(l10n),
            ),
          ],
        ),
      ),
      actions: _buildActions(l10n),
    );
  }

  Widget _buildChooseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).bootstrapRequiredBody),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _variant,
          onChanged: _selectVariant,
          child: Column(
            children: [
              RadioListTile<String>(
                value: AppConfig.bootstrapVariantSlim,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Slim ~80MB (default)'),
                subtitle: const Text(
                  'Core + apt — languages install on demand',
                ),
              ),
              RadioListTile<String>(
                value: AppConfig.bootstrapVariantFull,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Full ~283MB (offline)'),
                subtitle: const Text(
                  'Node, Python, PHP and Git preinstalled',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(AppLocalizations l10n) {
    if (_done) return Text(l10n.runtimeBootstrapReady);
    if (_running || _started) {
      final pct = (_fraction * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: _fraction),
          const SizedBox(height: 6),
          if (_phase != null)
            Text(
              '$_phase  $pct%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.commonError('$_error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 4),
            const Text(
              'Retry reuses the verified download (resume).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      );
    }
    return Text(l10n.runtimeBootstrapNotInstalled);
  }

  Widget _buildDoneStep(AppLocalizations l10n) {
    if (!_done) return Text(l10n.runtimeBootstrapNotInstalled);
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(l10n.runtimeBootstrapReady)),
      ],
    );
  }

  List<Widget> _buildActions(AppLocalizations l10n) {
    if (_done) {
      return [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionClose),
        ),
      ];
    }
    if (_running) {
      // Native install has no cancel; closing only dismisses the dialog
      // while setup continues in the background.
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionClose),
        ),
      ];
    }
    if (_error != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionClose),
        ),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.actionRetry),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(l10n.actionLater),
      ),
      FilledButton.icon(
        onPressed: _start,
        icon: const Icon(Icons.download, size: 18),
        label: Text(l10n.actionDownload),
      ),
    ];
  }
}
