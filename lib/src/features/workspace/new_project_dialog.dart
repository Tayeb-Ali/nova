import "package:flutter/material.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/models/runtime.dart";
import "../../core/services/runtime_service.dart";

/// Shared new-project dialog: name field + runtime picker.
///
/// The runtime list is built from **installed** runtimes (plus General):
/// installing a language in the SDK tab makes it appear here. Returns
/// `(name, languageId)` with languageId being a runtime id ("php", "go",
/// …) or `"general"`, or null on cancel.
/// Stored values are never remapped here; use [displayLanguage] at
/// render sites for user-facing labels.
Future<(String, String)?> showNewProjectDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final nameController = TextEditingController();
  var selectedLanguage = "general";
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => _NewProjectDialogBody(
      l10n: l10n,
      nameController: nameController,
      initialLanguage: selectedLanguage,
      onPicked: (v) => selectedLanguage = v,
    ),
  ).then((result) {
    nameController.dispose();
    return result == null ? null : (result.$1, selectedLanguage);
  });
}

class _NewProjectDialogBody extends StatefulWidget {
  const _NewProjectDialogBody({
    required this.l10n,
    required this.nameController,
    required this.initialLanguage,
    required this.onPicked,
  });

  final AppLocalizations l10n;
  final TextEditingController nameController;
  final String initialLanguage;
  final ValueChanged<String> onPicked;

  @override
  State<_NewProjectDialogBody> createState() => _NewProjectDialogBodyState();
}

class _NewProjectDialogBodyState extends State<_NewProjectDialogBody> {
  late String _selected = widget.initialLanguage;
  List<RuntimeInfo> _installed = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalled();
  }

  Future<void> _loadInstalled() async {
    try {
      final all = await RuntimeService().getRuntimes();
      if (!mounted) return;
      setState(() {
        _installed =
            all.where((r) => r.installed && r.type.isLanguage).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _pick(String value) {
    setState(() => _selected = value);
    widget.onPicked(value);
  }

  void _submit() {
    final name = widget.nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name, _selected));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(widget.l10n.projectNew),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.l10n.projectNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) {
                  if (v != null) _pick(v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in _installed)
                      RadioListTile<String>(
                        value: r.id,
                        secondary: Icon(r.type.icon),
                        title: Text(r.displayName),
                        subtitle:
                            r.version != null && r.version!.isNotEmpty
                                ? Text(
                                    r.version!,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                        dense: true,
                      ),
                    const RadioListTile<String>(
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
          child: Text(widget.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.l10n.actionCreate),
        ),
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
    case "go":
      return "Go";
    case "rust":
      return "Rust";
    case "ruby":
      return "Ruby";
    case "java":
      return "Java";
    case "kotlin":
      return "Kotlin";
    case "dart":
      return "Dart";
    case "general":
      return "General";
    default:
      return language ?? "";
  }
}
