import 'package:flutter/material.dart';
import 'package:nova/l10n/generated/app_localizations.dart';

import '../../core/bridge/generated/ide_api.g.dart' as bridge;
import '../../core/models/project.dart';
import '../../core/services/git_service.dart';
import '../../core/services/project_service.dart';

/// Git panel: status/diff/commit (task.md §24).
class GitScreen extends StatefulWidget {
  const GitScreen({super.key});

  @override
  State<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends State<GitScreen> {
  final _git = GitService();
  final _projectService = ProjectService();
  final _pathController = TextEditingController();

  List<ProjectInfo> _projects = const [];
  bridge.GitStatus? _status;
  bool _loading = false;
  String? _error;
  String? _diff;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final List<ProjectInfo> list = await _projectService.listProjects();
      if (!mounted) return;
      setState(() {
        _projects = list;
        if (_pathController.text.isEmpty && list.isNotEmpty) {
          _pathController.text = list.first.path;
        }
      });
      if (_pathController.text.trim().isNotEmpty) {
        await _loadStatus();
      }
    } catch (_) {
      // Native project list unavailable yet; the user can type a path.
    }
  }

  String get _path => _pathController.text.trim();

  Future<void> _loadStatus() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bridge.GitStatus status = await _git.status(path);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = status;
        _error = (status.error != null && status.error!.isNotEmpty)
            ? status.error
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.commonError('$e');
      });
    }
  }

  Future<void> _stageAll() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    try {
      await _git.add(path, const ['.']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitStagedAll)));
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitStageFailed('$e'))));
    }
  }

  Future<void> _commit() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    final controller = TextEditingController();
    final String? message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).gitCommit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(ctx).gitCommitMessage,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).gitCommit),
          ),
        ],
      ),
    );
    controller.dispose();
    final String msg = message?.trim() ?? '';
    if (msg.isEmpty) return;
    try {
      await _git.commit(path, msg);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitCommitted)));
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitCommitFailed('$e'))));
    }
  }

  Future<void> _showDiff() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    setState(() => _diff = null);
    try {
      final String diff = await _git.diff(path);
      if (!mounted) return;
      setState(() => _diff = diff);
    } catch (e) {
      if (!mounted) return;
      setState(() => _diff = l10n.commonError('$e'));
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _DiffDialog(content: _diff ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).gitTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProjectSelector(),
          const SizedBox(height: 16),
          _buildActions(),
          const SizedBox(height: 16),
          _buildStatus(),
        ],
      ),
    );
  }

  Widget _buildProjectSelector() {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    final bool hasProject = _projects.any((p) => p.path == path);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gitProject,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_projects.isNotEmpty) ...[
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.gitOpenProject,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: hasProject ? path : null,
                    isExpanded: true,
                    hint: Text(l10n.gitSelectProject),
                    items: [
                      for (final ProjectInfo p in _projects)
                        DropdownMenuItem(
                          value: p.path,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _pathController.text = v;
                      _loadStatus();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _pathController,
              decoration: InputDecoration(
                labelText: l10n.gitProjectPath,
                hintText: '/data/user/0/sd.adaa.codeide/files/projects/my-app',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.folder),
              ),
              onSubmitted: (_) => _loadStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);
    final bool hasPath = _path.isNotEmpty;
    final bool usable = hasPath && _error == null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: hasPath ? _loadStatus : null,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.gitStatus),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _stageAll : null,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(l10n.gitStageAll),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _commit : null,
          icon: const Icon(Icons.commit),
          label: Text(l10n.gitCommit),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _showDiff : null,
          icon: const Icon(Icons.difference),
          label: Text(l10n.gitDiff),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.gitUnavailable),
          subtitle: Text(_error!),
        ),
      );
    }
    final bridge.GitStatus? status = _status;
    if (status == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gitBranch(status.branch),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildSection(
          l10n.gitModified,
          status.modified,
          Icons.edit,
          Colors.orange,
        ),
        _buildSection(
          l10n.gitAdded,
          status.added,
          Icons.add_circle,
          Colors.green,
        ),
        _buildSection(
          l10n.gitDeleted,
          status.deleted,
          Icons.delete,
          Colors.red,
        ),
        _buildSection(
          l10n.gitUntracked,
          status.untracked,
          Icons.help_outline,
          Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<String> files,
    IconData icon,
    Color color,
  ) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                '$title (${files.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final String f in files)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $f',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Scrollable monospace diff viewer.
class _DiffDialog extends StatelessWidget {
  final String content;

  const _DiffDialog({required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).gitDiff,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 280,
                maxWidth: 460,
                maxHeight: 420,
              ),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content.isEmpty
                        ? AppLocalizations.of(context).gitEmptyDiff
                        : content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).actionClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
