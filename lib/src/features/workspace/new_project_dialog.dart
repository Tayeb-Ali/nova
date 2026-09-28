import "package:flutter/material.dart";

import "../../../l10n/generated/app_localizations.dart";

/// Shared new-project dialog: name field + runtime picker.
///
/// Returns `(name, language)` with language one of
/// `"php"`, `"node"`, `"python"`, `"general"`, or null on cancel.
/// Stored values are never remapped here; use [displayLanguage] at
/// render sites for user-facing labels.
Future<(String, String)?> showNewProjectDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => _NewProjectDialog(
      title: l10n.projectNew,
      nameHint: l10n.projectNameHint,
      cancelLabel: l10n.actionCancel,
      createLabel: l10n.actionCreate,
    ),
  );
}

/// Dialog body owning the name controller and the selected runtime.
///
/// The controller MUST live in this State, not in the caller: `showDialog`'s
/// future completes on `pop()`, while the route keeps rebuilding through its
/// exit transition. A caller-owned controller disposed at that point makes the
/// still-animating [TextField] re-attach a listener to a disposed controller.
class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog({
    required this.title,
    required this.nameHint,
    required this.cancelLabel,
    required this.createLabel,
  });

  final String title;
  final String nameHint;
  final String cancelLabel;
  final String createLabel;

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  late final TextEditingController _nameController;
  var _selectedLanguage = "general";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name, _selectedLanguage));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.nameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedLanguage,
              onChanged: (v) =>
                  setState(() => _selectedLanguage = v ?? "general"),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: "php",
                    secondary: Icon(Icons.language),
                    title: Text("PHP"),
                    subtitle: Text("Laravel, WordPress…"),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: "node",
                    secondary: Icon(Icons.integration_instructions),
                    title: Text("Node.js"),
                    subtitle: Text("JavaScript & TypeScript"),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: "python",
                    secondary: Icon(Icons.terminal),
                    title: Text("Python"),
                    subtitle: Text("Scripts & data"),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: "general",
                    secondary: Icon(Icons.folder_open),
                    title: Text("General"),
                    subtitle: Text(
                      "No runtime assumed — language auto-detected",
                    ),
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.createLabel)),
      ],
    );
  }
}

/// User-facing label for a stored project language.
///
/// Old projects store `"node"`; display it as `"Node.js"`.
/// Stored values are unchanged — display only.
String displayLanguage(String? language) {
  switch (language) {
    case "node":
      return "Node.js";
    case "php":
      return "PHP";
    case "python":
      return "Python";
    case "general":
      return "General";
    default:
      return language ?? "";
  }
}
