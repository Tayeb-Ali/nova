import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nova/l10n/generated/app_localizations.dart';

import '../../core/bridge/events_bus.dart';
import '../../core/bridge/generated/ide_api.g.dart' as bridge;
import '../../core/models/runtime.dart';
import '../../core/services/runtime_service.dart';
import '../../core/services/setup_service.dart';

/// Runtime manager: bootstrap status + install/update/remove runtimes
/// (task.md §29).
class RuntimeScreen extends StatefulWidget {
  const RuntimeScreen({super.key});

  @override
  State<RuntimeScreen> createState() => _RuntimeScreenState();
}

class _RuntimeScreenState extends State<RuntimeScreen> {
  final _setupService = SetupService();
  final _runtimeService = RuntimeService();

  StreamSubscription<dynamic>? _events;

  bridge.SetupStatus? _setupStatus;
  bool _loadingSetup = true;
  bool _setupRunning = false;
  String? _setupPhase;
  double _setupFraction = 0;
  String? _setupError;

  List<RuntimeInfo> _runtimes = const [];
  bool _loadingRuntimes = true;
  String? _runtimesError;

  String? _activeId;
  final List<String> _progressLog = <String>[];
  String? _runtimeError;
  double? _runtimeFraction;
  String? _runtimeStatus;
  String? _downloadRate;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listenEvents();
    _loadSetupStatus();
    _refreshRuntimes();
  }

  @override
  void dispose() {
    _events?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _listenEvents() {
    _events = IdeEventBus.instance.stream.listen(
      _onEvent,
      onError: (Object _) {},
    );
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final String? event = raw['event'] as String?;
    switch (event) {
      case 'setupProgress':
        if (!mounted) return;
        setState(() {
          _setupRunning = true;
          _setupPhase = raw['phase'] as String?;
          final dynamic fraction = raw['fraction'];
          _setupFraction = fraction is num
              ? fraction.toDouble().clamp(0.0, 1.0)
              : 0.0;
        });
        break;
      case 'setupCompleted':
        if (!mounted) return;
        setState(() {
          _setupRunning = false;
          _setupPhase = null;
          _setupFraction = 1;
          _setupError = null;
        });
        _loadSetupStatus();
        break;
      case 'setupFailed':
        if (!mounted) return;
        setState(() {
          _setupRunning = false;
          _setupError =
              raw['error'] as String? ??
              AppLocalizations.of(context).runtimeSetupFailed;
        });
        break;
      case 'runtimeProgress':
        if (!mounted) return;
        setState(() {
          _activeId = raw['id'] as String?;
          final String? data = raw['data'] as String?;
          if (data != null && data.isNotEmpty) {
            final String trimmed = data.trim();
            if (trimmed.isNotEmpty) {
              _progressLog.add(trimmed);
              if (_progressLog.length > 300) {
                _progressLog.removeRange(0, _progressLog.length - 300);
              }
              _parseProgress(trimmed);
            }
          }
        });
        // Auto-scroll log to bottom after frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
        break;
      case 'runtimeCompleted':
        _finishRuntime(raw['id'] as String?, null);
        break;
      case 'runtimeFailed':
        _finishRuntime(raw['id'] as String?, raw['error'] as String?);
        break;
    }
  }

  void _parseProgress(String line) {
    // Parse apt output for percentage like "12%" or "[12%]" and download rate like "1.2 MB/s"
    final RegExp percentReg = RegExp(r'(\d{1,3})\s*%');
    final RegExp rateReg = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:B|kB|KB|MB|GB)/s)',
      caseSensitive: false,
    );
    final RegExp statusReg = RegExp(
      r'(Get:|Hit:|Ign|Reading|Building|Unpacking|Setting up|Preparing|Selecting|Fetched)',
      caseSensitive: false,
    );

    final Match? pctMatch = percentReg.firstMatch(line);
    if (pctMatch != null) {
      final int? pct = int.tryParse(pctMatch.group(1)!);
      if (pct != null) {
        _runtimeFraction = (pct.clamp(0, 100) / 100.0);
      }
    } else if (statusReg.hasMatch(line)) {
      // Keep indeterminate for status lines without percentage
      if (_runtimeFraction == null || _runtimeFraction == 1.0) {
        _runtimeFraction = null;
      }
      _runtimeStatus = line.length > 80 ? '${line.substring(0, 80)}…' : line;
    }

    final Match? rateMatch = rateReg.firstMatch(line);
    if (rateMatch != null) {
      _downloadRate = rateMatch.group(1);
    }

    // Heuristic: lines containing "apt update" or "apt install" set status
    final String lower = line.toLowerCase();
    if (lower.contains('apt update')) {
      _runtimeStatus = 'تحديث قوائم الحزم...';
      _runtimeFraction = 0.1;
    } else if (lower.contains('apt install')) {
      _runtimeStatus = 'بدء التثبيت...';
      _runtimeFraction ??= 0.2;
    } else if (lower.contains('reading package lists')) {
      _runtimeStatus = 'قراءة قوائم الحزم...';
    } else if (lower.contains('building dependency tree')) {
      _runtimeStatus = 'بناء شجرة الاعتماديات...';
    } else if (lower.contains('unpacking')) {
      _runtimeStatus = 'فك الحزم...';
      _runtimeFraction = 0.7;
    } else if (lower.contains('setting up')) {
      _runtimeStatus = 'إعداد الحزم...';
      _runtimeFraction = 0.9;
    } else if (lower.contains('fetched') || lower.contains('get:')) {
      _runtimeStatus = line.length > 60 ? line.substring(0, 60) : line;
    }
  }

  void _finishRuntime(String? id, String? error) {
    if (!mounted) return;
    final String displayName = id != null ? _nameForId(id) : _activeName;
    setState(() {
      _activeId = null;
      _runtimeError = error;
      if (error == null) {
        _runtimeFraction = 1.0;
        _runtimeStatus = 'اكتمل';
      }
    });
    _refreshRuntimes();
    // Notification + list refresh feedback
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم تثبيت $displayName بنجاح ✅'),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل تثبيت $displayName: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppLocalizations.of(context).actionRetry,
            onPressed: () => _install(id ?? ''),
          ),
        ),
      );
    }
    // Clear progress after a short delay so user sees completion
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_activeId == null) {
        setState(() {
          _runtimeFraction = null;
          _runtimeStatus = null;
          _downloadRate = null;
        });
      }
    });
  }

  String _nameForId(String id) {
    for (final RuntimeInfo r in _runtimes) {
      if (r.id == id) return r.displayName;
    }
    return id;
  }

  Future<void> _loadSetupStatus() async {
    try {
      final bridge.SetupStatus status = await _setupService.getStatus();
      if (!mounted) return;
      setState(() {
        _setupStatus = status;
        _loadingSetup = false;
        if (status.error != null && status.error!.isNotEmpty) {
          _setupError = status.error;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setupStatus = null;
        _loadingSetup = false;
      });
    }
  }

  Future<void> _refreshRuntimes() async {
    setState(() => _loadingRuntimes = true);
    try {
      final List<RuntimeInfo> list = await _runtimeService.getRuntimes();
      if (!mounted) return;
      setState(() {
        _runtimes = list;
        _loadingRuntimes = false;
        _runtimesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRuntimes = false;
        _runtimesError = e.toString();
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadSetupStatus(), _refreshRuntimes()]);
  }

  Future<void> _startSetup() async {
    setState(() {
      _setupRunning = true;
      _setupError = null;
      _setupPhase = null;
      _setupFraction = 0;
    });
    try {
      await _setupService.startSetup();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setupRunning = false;
        _setupError = e.toString();
      });
    }
  }

  Future<void> _install(String id) async {
    setState(() {
      _activeId = id;
      _progressLog.clear();
      _runtimeError = null;
      _runtimeFraction = 0.05;
      _runtimeStatus = 'بدء تثبيت ${_nameForId(id)}...';
      _downloadRate = null;
    });
    // Immediate feedback: SnackBar that work started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بدء تثبيت ${_nameForId(id)}...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await _runtimeService.install(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activeId = null;
        _runtimeError = e.toString();
        _runtimeFraction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل بدء التثبيت: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _update(String id) async {
    setState(() {
      _activeId = id;
      _progressLog.clear();
      _runtimeError = null;
      _runtimeFraction = 0.05;
      _runtimeStatus = 'بدء تحديث ${_nameForId(id)}...';
      _downloadRate = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بدء تحديث ${_nameForId(id)}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await _runtimeService.update(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activeId = null;
        _runtimeError = e.toString();
        _runtimeFraction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل بدء التحديث: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmUninstall(RuntimeInfo runtime) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(AppLocalizations.of(ctx).actionUninstall),
        content: Text(
          AppLocalizations.of(ctx).runtimeUninstallConfirm(runtime.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(AppLocalizations.of(ctx).actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(AppLocalizations.of(ctx).actionUninstall),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    setState(() {
      _activeId = runtime.id;
      _progressLog.clear();
      _runtimeError = null;
      _runtimeFraction = 0.1;
      _runtimeStatus = 'إزالة ${runtime.displayName}...';
      _downloadRate = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('إزالة ${runtime.displayName}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await _runtimeService.uninstall(runtime.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activeId = null;
        _runtimeError = e.toString();
        _runtimeFraction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الإزالة: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _busy => _activeId != null;

  String get _activeName {
    for (final RuntimeInfo r in _runtimes) {
      if (r.id == _activeId) return r.displayName;
    }
    return _activeId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).runtimeTitle)),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _buildSetupCard(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                AppLocalizations.of(context).runtimeTitle,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildRuntimes(),
            const SizedBox(height: 8),
            _buildProgressSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard() {
    final bool ready = _setupStatus?.ready ?? false;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).runtimeBootstrap,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (ready)
                  Chip(
                    avatar: Icon(Icons.check, size: 16, color: scheme.tertiary),
                    label: Text(AppLocalizations.of(context).runtimeReady),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: scheme.tertiaryContainer,
                    labelStyle: TextStyle(color: scheme.onTertiaryContainer),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingSetup)
              const LinearProgressIndicator()
            else if (ready)
              // Ready chip above says it all; keep one short line, no hash.
              Text(AppLocalizations.of(context).runtimeBootstrapReady)
            else if (_setupStatus == null)
              Text(AppLocalizations.of(context).runtimeBootstrapUnavailable)
            else
              Text(AppLocalizations.of(context).runtimeBootstrapNotInstalled),
            if (_setupRunning) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _setupFraction),
              if (_setupPhase != null) ...[
                const SizedBox(height: 6),
                Text(
                  '$_setupPhase  ${(_setupFraction * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            if (_setupError != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).commonError('$_setupError'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!ready && !_setupRunning) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _startSetup,
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
                icon: const Icon(Icons.build, size: 18),
                label: Text(AppLocalizations.of(context).runtimeStartSetup),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimes() {
    if (_loadingRuntimes) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_runtimesError != null) {
      return Text(
        AppLocalizations.of(context).commonError('$_runtimesError'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (_runtimes.isEmpty) {
      return Text(AppLocalizations.of(context).runtimeEmpty);
    }
    return Column(
      children: [for (final RuntimeInfo r in _runtimes) _buildRuntimeTile(r)],
    );
  }

  Widget _buildRuntimeTile(RuntimeInfo runtime) {
    final bool isActive = _activeId == runtime.id;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    runtime.displayName,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (runtime.installed)
                  Chip(
                    avatar: Icon(Icons.check, size: 16, color: scheme.tertiary),
                    label: Text(AppLocalizations.of(context).runtimeInstalled),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: scheme.tertiaryContainer,
                    labelStyle: TextStyle(color: scheme.onTertiaryContainer),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                  )
                else
                  Chip(
                    label: Text(AppLocalizations.of(context).runtimeAvailable),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: scheme.surfaceContainerHigh,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)
                  .runtimeVersion(runtime.version ?? '—'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _runtimeFraction),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _runtimeStatus ??
                          'جاري العمل على ${runtime.displayName}...',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_runtimeFraction != null)
                    Text(
                      '${(_runtimeFraction! * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  if (_downloadRate != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.download,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _downloadRate!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ] else
              Row(
                children: [
                  if (runtime.installed) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _update(runtime.id),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.update, size: 18),
                      label: Text(AppLocalizations.of(context).actionUpdate),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _confirmUninstall(runtime),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(AppLocalizations.of(context).actionUninstall),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _install(runtime.id),
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
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(AppLocalizations.of(context).actionInstall),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final bool hasActive = _activeId != null;
    final bool hasError = _runtimeError != null;
    final bool hasLog = _progressLog.isNotEmpty;
    if (!hasActive && !hasError && !hasLog) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasActive
                      ? Icons.downloading
                      : hasError
                      ? Icons.error_outline
                      : Icons.terminal,
                  size: 18,
                  color: hasError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasActive
                        ? 'جاري تنفيذ: $_activeName'
                        : hasError
                        ? 'آخر عملية: $_activeName'
                        : 'سجل العمليات',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasActive && _runtimeFraction != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(_runtimeFraction! * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (hasActive && _downloadRate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _downloadRate!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (hasActive) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _runtimeFraction),
              if (_runtimeStatus != null) ...[
                const SizedBox(height: 6),
                Text(
                  _runtimeStatus!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (hasError) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'خطأ: $_runtimeError',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (hasLog)
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Scrollbar(
                  controller: _logScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: _progressLog.length,
                    itemBuilder: (context, i) {
                      final String line = _progressLog[i];
                      final bool isError =
                          line.toLowerCase().contains('error') ||
                          line.toLowerCase().contains('failed');
                      final bool isSuccess =
                          line.toLowerCase().contains('setting up') ||
                          line.toLowerCase().contains('done');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(i + 1).toString().padLeft(3, '0')} ',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      color: isError
                                          ? Theme.of(context).colorScheme.error
                                          : isSuccess
                                          ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                          : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (hasLog) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${_progressLog.length} سطر',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _progressLog.clear()),
                    icon: const Icon(Icons.clear_all, size: 14),
                    label: const Text('مسح', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
}
