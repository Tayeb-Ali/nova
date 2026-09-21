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
  final nameController = TextEditingController();
  var selectedLanguage = "general";
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(l10n.projectNew),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.projectNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onSubmitted: (_) {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(context).pop((name, selectedLanguage));
                },
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: selectedLanguage,
                onChanged: (v) => setDialogState(
                    () => selectedLanguage = v ?? "general"),
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
                      secondary:
                          Icon(Icons.integration_instructions),
                      title: Text("Node.js"),
                      subtitle:
                          Text("JavaScript & TypeScript"),
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
                          "No runtime assumed — language auto-detected"),
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
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop((name, selectedLanguage));
            },
            child: Text(l10n.actionCreate),
          ),
        ],
      ),
    ),
  ).then((result) {
    nameController.dispose();
    return result;
  });
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
