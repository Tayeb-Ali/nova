import "package:flutter/material.dart";
import "package:re_editor/re_editor.dart";

import "completion_ranker.dart";
import "language_snippets.dart";

/// Maximum height of the suggestion list.
const double _kMaxPopupHeight = 220.0;

/// Maximum width of the suggestion list.
const double _kPopupWidth = 300.0;

/// Height of a single suggestion row.
const double _kRowHeight = 34.0;

/// VSCode-like autocomplete popup for re_editor.
///
/// The signature matches [CodeAutocompleteWidgetBuilder] exactly, so this
/// function can be passed as `viewBuilder` to [CodeAutocomplete]:
/// ```dart
/// CodeAutocomplete(
///   viewBuilder: buildAutocompletePopup,
///   promptsBuilder: NovaPromptsBuilder(language: mode, languageId: "dart"),
///   child: CodeEditor(...),
/// )
/// ```
/// Tapping a row (or pressing enter, handled inside re_editor) completes via
/// [CodeAutocompleteEditingValue.autocomplete], which replaces the typed
/// input with the selected prompt's completion word.
PreferredSizeWidget buildAutocompletePopup(
  BuildContext context,
  ValueNotifier<CodeAutocompleteEditingValue> notifier,
  ValueChanged<CodeAutocompleteResult> onSelected,
) {
  if (notifier.value.prompts.isEmpty) {
    return const _EmptyAutocompletePopup();
  }
  return _AutocompletePopup(notifier: notifier, onSelected: onSelected);
}

/// Zero-size placeholder honoring the [PreferredSizeWidget] contract for the
/// empty-prompts case.
class _EmptyAutocompletePopup extends StatelessWidget
    implements PreferredSizeWidget {
  const _EmptyAutocompletePopup();

  @override
  Size get preferredSize => Size.zero;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AutocompletePopup extends StatelessWidget
    implements PreferredSizeWidget {
  const _AutocompletePopup({
    required this.notifier,
    required this.onSelected,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  @override
  Size get preferredSize {
    final int count = notifier.value.prompts.length;
    final double height =
        (count * _kRowHeight + 16).clamp(0.0, _kMaxPopupHeight);
    return Size(_kPopupWidth, height);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<CodeAutocompleteEditingValue>(
      valueListenable: notifier,
      builder: (BuildContext context, CodeAutocompleteEditingValue value, _) {
        if (value.prompts.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: EdgeInsets.zero,
          elevation: 6,
          color: colors.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _kPopupWidth,
              maxHeight: _kMaxPopupHeight,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: value.prompts.length,
              itemBuilder: (BuildContext context, int index) {
                final CodePrompt prompt = value.prompts[index];
                return _PromptRow(
                  prompt: prompt,
                  input: value.input,
                  selected: index == value.index,
                  onTap: () => onSelected(
                    value.copyWith(index: index).autocomplete,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.prompt,
    required this.input,
    required this.selected,
    required this.onTap,
  });

  final CodePrompt prompt;
  final String input;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? detail = _detailFor(prompt);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: _kRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(prompt),
              size: 16,
              color: selected
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: _wordSpan(
                  prompt.word,
                  input,
                  selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                  colors.primary,
                ),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  detail,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kind icon by prompt runtime type. Multi-word Material icon names use
/// snake_case ([Icons.data_object]); snippet-flagged fields use
/// [Icons.text_snippet].
IconData _iconFor(CodePrompt prompt) {
  if (prompt is CodeFunctionPrompt) {
    return Icons.functions;
  }
  if (prompt is CodeFieldPrompt) {
    return prompt.type == snippetPromptType
        ? Icons.text_snippet
        : Icons.data_object;
  }
  return Icons.key;
}

/// Optional detail text shown after the word.
String? _detailFor(CodePrompt prompt) {
  if (prompt is CodeFunctionPrompt) {
    final String params = prompt.parameters.entries
        .map((MapEntry<String, String> entry) =>
            "${entry.key}: ${entry.value}")
        .join(", ");
    return "($params) -> ${prompt.type}";
  }
  if (prompt is CodeFieldPrompt) {
    return prompt.type;
  }
  return "keyword";
}

/// Renders [word] with the typed [input] characters highlighted JetBrains-style.
/// Prefix hits bold the leading run; fuzzy hits (e.g. `prln` in `println`)
/// bold each matched character in order; falls back to plain text.
InlineSpan _wordSpan(
  String word,
  String input,
  Color baseColor,
  Color matchColor,
) {
  final TextStyle base = TextStyle(color: baseColor, fontSize: 13);
  final TextStyle match =
      TextStyle(color: matchColor, fontWeight: FontWeight.bold, fontSize: 13);
  if (input.isEmpty) return TextSpan(text: word, style: base);
  final List<int> hits = fuzzyMatchIndices(word, input);
  if (hits.isEmpty) return TextSpan(text: word, style: base);
  final Set<int> hitSet = hits.toSet();
  final List<InlineSpan> children = [];
  final StringBuffer run = StringBuffer();
  bool? inMatch;
  for (int i = 0; i < word.length; i++) {
    final bool isHit = hitSet.contains(i);
    if (inMatch == null || isHit != inMatch) {
      if (run.isNotEmpty) {
        children.add(
          TextSpan(
            text: run.toString(),
            style: inMatch == true ? match : base,
          ),
        );
        run.clear();
      }
      inMatch = isHit;
    }
    run.write(word[i]);
  }
  if (run.isNotEmpty) {
    children.add(
      TextSpan(text: run.toString(), style: inMatch == true ? match : base),
    );
  }
  return TextSpan(children: children);
}
