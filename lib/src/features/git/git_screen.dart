import 'package:flutter/material.dart';

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
        _error = 'Failed to load git status: $e';
      });
    }
  }

  Future<void> _stageAll() async {
    final String path = _path;
    if (path.isEmpty) return;
    try {
      await _git.add(path, const ['.']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staged all changes')),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stage failed: $e')));
    }
  }

  Future<void> _commit() async {
    final String path = _path;
    if (path.isEmpty) return;
    final controller = TextEditingController();
    final String? message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Commit message',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Commit'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Committed')),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Commit failed: $e')));
    }
  }

  Future<void> _showDiff() async {
    final String path = _path;
    if (path.isEmpty) return;
    setState(() => _diff = null);
    try {
      final String diff = await _git.diff(path);
      if (!mounted) return;
      setState(() => _diff = diff);
    } catch (e) {
      if (!mounted) return;
      setState(() => _diff = 'Failed to load diff:\n$e');
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
      appBar: AppBar(title: const Text('Git')),
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
    final String path = _path;
    final bool hasProject = _projects.any((p) => p.path == path);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_projects.isNotEmpty) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Open project',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: hasProject ? path : null,
                    isExpanded: true,
                    hint: const Text('Select project'),
                    items: [
                      for (final ProjectInfo p in _projects)
                        DropdownMenuItem(
                          value: p.path,
                          child: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
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
              decoration: const InputDecoration(
                labelText: 'Project path',
                hintText: '/data/user/0/sd.adaa.nova/files/projects/my-app',
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
    final bool hasPath = _path.isNotEmpty;
    final bool usable = hasPath && _error == null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: hasPath ? _loadStatus : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Status'),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _stageAll : null,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Stage all'),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _commit : null,
          icon: const Icon(Icons.commit),
          label: const Text('Commit'),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _showDiff : null,
          icon: const Icon(Icons.difference),
          label: const Text('Diff'),
        ),
      ],
    );
  }

  Widget _buildStatus() {
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
          title: const Text('Git unavailable'),
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
          'Branch: ${status.branch}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildSection('Modified', status.modified, Icons.edit, Colors.orange),
        _buildSection('Added', status.added, Icons.add_circle, Colors.green),
        _buildSection('Deleted', status.deleted, Icons.delete, Colors.red),
        _buildSection(
          'Untracked',
          status.untracked,
          Icons.help_outline,
          Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> files, IconData icon, Color color) {
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
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
                  child: Text('Diff', style: Theme.of(context).textTheme.titleMedium),
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
                    content.isEmpty ? '(empty diff)' : content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}