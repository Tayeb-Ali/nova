import "package:flutter/material.dart";

/// Single-field text prompt dialog.
///
/// The [TextEditingController] is owned by [_TextPromptDialog]'s State, so it
/// is disposed together with the dialog subtree — after the route's exit
/// transition finishes. Never create the controller in the caller and dispose
/// it when the `showDialog` future completes: `pop()` completes the future
/// *before* the dialog stops rebuilding, so the still-animating [TextField]
/// re-attaches a listener to a disposed controller and throws
/// `A TextEditingController was used after being disposed.`.
///
/// Returns the trimmed text, or null when cancelled.
Future<String?> showTextPromptDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? hintText,
  String? labelText,
  String initialValue = "",
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4)),
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      hintText: hintText,
      labelText: labelText,
      initialValue: initialValue,
      borderRadius: borderRadius,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.hintText,
    this.labelText,
    this.initialValue = "",
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String? hintText;

  /// Floating label; mutually exclusive with [hintText] in practice, but
  /// `InputDecoration` renders both, so callers pick one.
  final String? labelText;
  final String initialValue;
  final BorderRadius borderRadius;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          border: OutlineInputBorder(borderRadius: widget.borderRadius),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          ),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
