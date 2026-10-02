import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova/l10n/generated/app_localizations.dart';

import '../../core/bridge/generated/ide_api.g.dart' as bridge;
import '../../core/models/project.dart';
import '../../core/services/git_service.dart';
import '../../core/services/project_service.dart';
import '../../core/ui/text_prompt_dialog.dart';
import '../tour/tour.dart';
import 'branch_picker.dart';
import 'diff_view.dart';

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
  final _cloneUrlController = TextEditingController();
  final _cloneDirController = TextEditingController();

  List<ProjectInfo> _projects = const [];
  bridge.GitStatus? _status;
  List<String> _stashes = const [];
  bool _loading = false;
  String? _error;
  String? _diff;
  bool _remoteBusy = false;
  String? _sshKey;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // Best-effort and unawaited: the SSH key is independent of projects
    // and must never gate the screen.
    unawaited(_loadSshKey());
  }

  @override
  void dispose() {
    _pathController.dispose();
    _cloneUrlController.dispose();
    _cloneDirController.dispose();
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
      // Best-effort and unawaited: stash must never gate (or hang) status.
      // An unmocked/missing stash channel leaves its future pending, so
      // awaiting it here would pin the spinner and hang pumpAndSettle.
      unawaited(_loadStash(path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.commonError('$e');
      });
    }
  }

  /// Best-effort stash refresh; never throws and never blocks status.
  Future<void> _loadStash(String path) async {
    try {
      final List<String> stashes = await _git.stashList(path);
      if (!mounted) return;
      setState(() => _stashes = stashes);
    } catch (_) {
      // Stash unavailable (e.g. unmocked in tests): keep the old list.
    }
  }

  /// Best-effort SSH public key refresh; never throws.
  Future<void> _loadSshKey() async {
    try {
      final String key = await _git.getSshPublicKey();
      if (!mounted) return;
      setState(() => _sshKey = key);
    } catch (_) {
      // Native SSH unavailable (e.g. unmocked in tests): hide the section.
    }
  }

  Future<void> _runRemote(
    Future<void> Function() op,
    String okMessage,
  ) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _remoteBusy = true);
    try {
      await op();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMessage)));
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitRemoteFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  Future<void> _clone() async {
    final l10n = AppLocalizations.of(context);
    final String url = _cloneUrlController.text.trim();
    final String dir = _cloneDirController.text.trim();
    if (url.isEmpty || dir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitRemoteFailed('URL + directory?'))),
      );
      return;
    }
    await _runRemote(() => _git.clone(url, dir), l10n.gitCloned);
  }

  Future<void> _generateSshKey() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _remoteBusy = true);
    try {
      final String key = await _git.generateSshKey();
      if (!mounted) return;
      setState(() => _sshKey = key);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitSshCopied)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitRemoteFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  Future<void> _copySshKey() async {
    final l10n = AppLocalizations.of(context);
    final String? key = _sshKey;
    if (key == null || key.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.gitSshCopied)));
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

  Future<void> _stageFile(String file) async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    try {
      await _git.add(path, [file]);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitStagedFile(file))));
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitStageFailed('$e'))));
    }
  }

  Future<void> _openBranches() async {
    final String path = _path;
    if (path.isEmpty) return;
    await showBranchPicker(context, projectPath: path);
    if (!mounted) return;
    await _loadStatus();
  }

  Future<void> _stashSave() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    final String? message = await showTextPromptDialog(
      context: context,
      title: l10n.gitStashSave,
      labelText: l10n.gitStashMessage,
      confirmLabel: l10n.gitStashSave,
      cancelLabel: l10n.actionCancel,
    );
    final String msg = message?.trim() ?? '';
    if (msg.isEmpty) return;
    try {
      await _git.stashSave(path, msg);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gitStashed)));
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitStashActionFailed('$e'))),
      );
    }
  }

  Future<void> _stashPop(int index) async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    try {
      await _git.stashPop(path, index);
      if (!mounted) return;
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitStashActionFailed('$e'))),
      );
    }
  }

  Future<void> _stashDrop(int index) async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    try {
      await _git.stashDrop(path, index);
      if (!mounted) return;
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitStashActionFailed('$e'))),
      );
    }
  }

  Future<void> _commit() async {
    final l10n = AppLocalizations.of(context);
    final String path = _path;
    if (path.isEmpty) return;
    final String? message = await showTextPromptDialog(
      context: context,
      title: l10n.gitCommit,
      labelText: l10n.gitCommitMessage,
      confirmLabel: l10n.gitCommit,
      cancelLabel: l10n.actionCancel,
    );
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).gitTitle),
        actions: const [
          TourButton(tourId: 'git', buildTargets: buildGitTargets),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProjectSelector(),
          const SizedBox(height: 16),
          _buildActions(),
          const SizedBox(height: 16),
          _buildRemote(),
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
          key: TourKeys.gitStatusBtn,
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
          key: TourKeys.gitCommitBtn,
          onPressed: usable ? _commit : null,
          icon: const Icon(Icons.commit),
          label: Text(l10n.gitCommit),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _showDiff : null,
          icon: const Icon(Icons.difference),
          label: Text(l10n.gitDiff),
        ),
        OutlinedButton.icon(
          onPressed: usable ? _openBranches : null,
          icon: const Icon(Icons.account_tree),
          label: Text(l10n.gitBranches),
        ),
      ],
    );
  }

  Widget _buildRemote() {
    final l10n = AppLocalizations.of(context);
    final bool hasPath = _path.isNotEmpty;
    final bool usable = hasPath && _error == null && !_remoteBusy;
    final String? key = _sshKey;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.cloud_sync_outlined, size: 20),
        title: Text(
          l10n.gitRemote,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        trailing: _remoteBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: usable
                      ? () => _runRemote(
                            () => _git.fetch(_path),
                            l10n.gitFetched,
                          )
                      : null,
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(l10n.gitFetch),
                ),
                OutlinedButton.icon(
                  onPressed: usable
                      ? () => _runRemote(
                            () => _git.pull(_path),
                            l10n.gitPulled,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: Text(l10n.gitPull),
                ),
                OutlinedButton.icon(
                  onPressed: usable
                      ? () => _runRemote(
                            () => _git.push(_path),
                            l10n.gitPushed,
                          )
                      : null,
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: Text(l10n.gitPush),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cloneUrlController,
              decoration: InputDecoration(
                labelText: l10n.gitCloneUrl,
                hintText: 'git@github.com:user/repo.git',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cloneDirController,
                    decoration: InputDecoration(
                      labelText: l10n.gitCloneDir,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.folder_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _remoteBusy ? null : _clone,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(l10n.gitClone),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              l10n.gitSshKey,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: _remoteBusy ? null : _generateSshKey,
                  icon: const Icon(Icons.key_outlined, size: 18),
                  label: Text(l10n.gitSshGenerate),
                ),
                if (key != null && key.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _copySshKey,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: Text(l10n.gitSshCopy),
                  ),
              ],
            ),
            if (key == null || key.isEmpty)
              Text(
                l10n.gitSshNoKey,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  key,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
        ],
      ),
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
        _buildStash(),
      ],
    );
  }

  Widget _buildStash() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${l10n.gitStash} (${_stashes.length})',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed:
                    _path.isNotEmpty && _error == null ? _stashSave : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.gitStashSave),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_stashes.isEmpty)
            Text(
              l10n.gitStashEmpty,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (int i = 0; i < _stashes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${_stashes[i]}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _stashPop(i),
                      child: Text(l10n.gitStashPop),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.gitStashDrop,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _stashDrop(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> files,
    IconData icon,
    Color color,
  ) {
    if (files.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• $f',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: l10n.gitStage,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _stageFile(f),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Scrollable per-file diff viewer.
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
                child: DiffView(
                  content: content,
                  emptyLabel: AppLocalizations.of(context).gitEmptyDiff,
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
