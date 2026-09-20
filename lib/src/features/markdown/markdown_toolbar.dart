import "package:fleather/fleather.dart";
import "package:flutter/material.dart";

/// Compact mobile-first Markdown toolbar with fully explicit colors.
///
/// Fleather's bundled toolbar resolves its button fills through inherited
/// theme lookups that misbehave on some configurations; this bar paints
/// everything from the ambient [ColorScheme] directly, so it always matches
/// the app in light and dark mode.
class MarkdownToolbar extends StatelessWidget {
  final FleatherController controller;
  final FocusNode focusNode;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  void _apply(ParchmentAttribute attribute) {
    final style = controller.getSelectionStyle();
    if (style.containsSame(attribute)) {
      controller.formatSelection(attribute.unset);
    } else {
      controller.formatSelection(attribute);
    }
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final style = controller.getSelectionStyle();
            bool on(ParchmentAttribute attr) => style.containsSame(attr);
            return Row(
              children: [
                _ToolButton(
                  tooltip: "Undo",
                  icon: Icons.undo,
                  onPressed: () {
                    controller.undo();
                    focusNode.requestFocus();
                  },
                ),
                _ToolButton(
                  tooltip: "Redo",
                  icon: Icons.redo,
                  onPressed: () {
                    controller.redo();
                    focusNode.requestFocus();
                  },
                ),
                const _ToolDivider(),
                _ToolButton(
                  tooltip: "Bold",
                  icon: Icons.format_bold,
                  toggled: on(ParchmentAttribute.bold),
                  onPressed: () => _apply(ParchmentAttribute.bold),
                ),
                _ToolButton(
                  tooltip: "Italic",
                  icon: Icons.format_italic,
                  toggled: on(ParchmentAttribute.italic),
                  onPressed: () => _apply(ParchmentAttribute.italic),
                ),
                _ToolButton(
                  tooltip: "Underline",
                  icon: Icons.format_underline,
                  toggled: on(ParchmentAttribute.underline),
                  onPressed: () => _apply(ParchmentAttribute.underline),
                ),
                _ToolButton(
                  tooltip: "Strikethrough",
                  icon: Icons.format_strikethrough,
                  toggled: on(ParchmentAttribute.strikethrough),
                  onPressed: () =>
                      _apply(ParchmentAttribute.strikethrough),
                ),
                _ToolButton(
                  tooltip: "Inline code",
                  icon: Icons.code,
                  toggled: on(ParchmentAttribute.inlineCode),
                  onPressed: () => _apply(ParchmentAttribute.inlineCode),
                ),
                const _ToolDivider(),
                _ToolButton(
                  tooltip: "Heading 1",
                  label: "H1",
                  toggled: on(ParchmentAttribute.h1),
                  onPressed: () => _apply(ParchmentAttribute.h1),
                ),
                _ToolButton(
                  tooltip: "Heading 2",
                  label: "H2",
                  toggled: on(ParchmentAttribute.h2),
                  onPressed: () => _apply(ParchmentAttribute.h2),
                ),
                _ToolButton(
                  tooltip: "Heading 3",
                  label: "H3",
                  toggled: on(ParchmentAttribute.h3),
                  onPressed: () => _apply(ParchmentAttribute.h3),
                ),
                const _ToolDivider(),
                _ToolButton(
                  tooltip: "Bulleted list",
                  icon: Icons.format_list_bulleted,
                  toggled:
                      on(ParchmentAttribute.block.bulletList),
                  onPressed: () =>
                      _apply(ParchmentAttribute.block.bulletList),
                ),
                _ToolButton(
                  tooltip: "Numbered list",
                  icon: Icons.format_list_numbered,
                  toggled:
                      on(ParchmentAttribute.block.numberList),
                  onPressed: () =>
                      _apply(ParchmentAttribute.block.numberList),
                ),
                _ToolButton(
                  tooltip: "Quote",
                  icon: Icons.format_quote,
                  toggled: on(ParchmentAttribute.block.quote),
                  onPressed: () =>
                      _apply(ParchmentAttribute.block.quote),
                ),
                _ToolButton(
                  tooltip: "Code block",
                  icon: Icons.code_off,
                  toggled: on(ParchmentAttribute.block.code),
                  onPressed: () =>
                      _apply(ParchmentAttribute.block.code),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final String? label;
  final bool toggled;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.tooltip,
    this.icon,
    this.label,
    this.toggled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill =
        toggled ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = toggled ? scheme.onPrimaryContainer : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 36,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : Icon(icon, size: 19, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
