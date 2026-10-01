import 'package:flutter/material.dart';
import 'package:nova/l10n/generated/app_localizations.dart';

import '../../core/services/git_service.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/text_prompt_dialog.dart';

/// Branch list dialog: checkout / create / delete via [GitService].
Future<void> showBranchPicker(
  BuildContext context, {
  required String projectPath,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BranchPickerDialog(projectPath: projectPath),
  );
}

class _BranchPickerDialog extends StatefulWidget {
  const _BranchPickerDialog({required this.projectPath});

  final String projectPath;

  @override
  State<_BranchPickerDialog> createState() => _BranchPickerDialogState();
}

class _BranchPickerDialogState extends State<_BranchPickerDialog> {
  final _git = GitService();

  List<String> _branches = const [];
  String _current = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<String> branches =
          await _git.listBranches(widget.projectPath);
      final String current =
          await _git.currentBranch(widget.projectPath);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _branches = branches;
        _current = current;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).gitBranchActionFailed('$e');
      });
    }
  }

  Future<void> _checkout(String branch) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _git.checkout(widget.projectPath, branch);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitBranchActionFailed('$e'))),
      );
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final String? name = await showTextPromptDialog(
      context: context,
      title: l10n.gitCreateBranch,
      labelText: l10n.gitBranchNameHint,
      confirmLabel: l10n.actionCreate,
      cancelLabel: l10n.actionCancel,
    );
    final String branch = name?.trim() ?? '';
    if (branch.isEmpty) return;
    try {
      await _git.createBranch(widget.projectPath, branch);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitBranchActionFailed('$e'))),
      );
    }
  }

  Future<void> _delete(String branch) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gitDeleteBranchConfirm(branch)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _git.deleteBranch(widget.projectPath, branch);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gitBranchActionFailed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    l10n.gitBranches,
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
                maxHeight: 380,
              ),
              child: SizedBox(
                width: double.maxFinite,
                child: _buildBody(l10n),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.gitCreateBranch),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    if (_branches.isEmpty) {
      return EmptyState(
        icon: Icons.account_tree_outlined,
        title: l10n.gitNoBranches,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _branches.length,
      itemBuilder: (context, i) {
        final String branch = _branches[i];
        final bool isCurrent = branch == _current;
        return ListTile(
          dense: true,
          leading: Icon(
            isCurrent ? Icons.check_circle : Icons.circle_outlined,
            color: isCurrent ? Colors.green : null,
          ),
          title: Text(
            branch,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCurrent)
                TextButton(
                  onPressed: () => _checkout(branch),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(l10n.gitCheckout),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.actionDelete,
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                onPressed: isCurrent ? null : () => _delete(branch),
              ),
            ],
          ),
          onTap: isCurrent ? null : () => _checkout(branch),
        );
      },
    );
  }
}
