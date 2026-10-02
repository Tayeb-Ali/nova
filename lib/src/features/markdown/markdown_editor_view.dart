import "dart:async";

import "package:fleather/fleather.dart";
import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:parchment/codecs.dart";

import "../editor/editor_engine.dart";
import "markdown_toolbar.dart";

/// Rich Markdown tab: Fleather editing with toolbar, flutter_markdown preview.
///
/// The file on disk is always plain Markdown. The document is decoded once on
/// open; [onChanged] fires with the re-encoded Markdown on every document
/// change (same full-text convention as the code editor), and [bridge]
/// exposes the latest Markdown for Save without re-encoding.
class MarkdownEditorView extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  final TabContentBridge bridge;
  final bool preview;

  const MarkdownEditorView({
    super.key,
    required this.initialText,
    required this.onChanged,
    required this.bridge,
    this.preview = false,
  });

  @override
  State<MarkdownEditorView> createState() => _MarkdownEditorViewState();
}

class _MarkdownEditorViewState extends State<MarkdownEditorView> {
  late final FleatherController _controller;
  late final FocusNode _focusNode;
  late String _lastMarkdown;
  StreamSubscription<ParchmentChange>? _sub;

  @override
  void initState() {
    super.initState();
    ParchmentDocument document;
    try {
      document = parchmentMarkdown.decode(widget.initialText);
    } catch (_) {
      document = ParchmentDocument();
    }
    _controller = FleatherController(document: document);
    _focusNode = FocusNode();
    _lastMarkdown = widget.initialText;
    // Fresh encode at save time so Save never sees a stale stream event.
    widget.bridge.readContent = () => parchmentMarkdown.encode(_controller.document);
    _sub = document.changes.listen((_) {
      if (!mounted) return;
      _lastMarkdown = parchmentMarkdown.encode(_controller.document);
      widget.onChanged(_lastMarkdown);
    });
  }

  @override
  void didUpdateWidget(covariant MarkdownEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.bridge.readContent = () => parchmentMarkdown.encode(_controller.document);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preview) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: _lastMarkdown,
          selectable: true,
          styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            codeblockDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        MarkdownToolbar(controller: _controller, focusNode: _focusNode),
        const Divider(height: 1),
        Expanded(
          child: FleatherEditor(
            controller: _controller,
            focusNode: _focusNode,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
