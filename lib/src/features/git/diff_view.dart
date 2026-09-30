import 'package:flutter/material.dart';

/// One per-file section of a merged `git diff` output.
@immutable
class DiffSection {
  const DiffSection({required this.header, required this.lines});

  /// The `diff --git a/... b/...` header line, or '' when the input had none.
  final String header;
  final List<String> lines;
}

/// Splits a merged (staged + unstaged) diff string into per-file sections on
/// `diff --git` headers. Inputs without any header yield a single section
/// with an empty header so plain messages/errors still render.
List<DiffSection> splitDiff(String content) {
  final List<DiffSection> sections = [];
  List<String>? current;
  String header = '';
  for (final String line in content.split('\n')) {
    if (line.startsWith('diff --git')) {
      if (current != null) {
        sections.add(DiffSection(header: header, lines: current));
      }
      header = line;
      current = <String>[];
    } else {
      (current ??= <String>[]).add(line);
    }
  }
  if (current != null) {
    sections.add(DiffSection(header: header, lines: current));
  }
  return sections;
}

/// Text color for a diff body line; null means "default body color".
Color? diffLineColor(String line) {
  if (line.startsWith('@@')) return const Color(0xFF1565C0);
  if (line.startsWith('+') && !line.startsWith('+++')) {
    return const Color(0xFF2E7D32);
  }
  if (line.startsWith('-') && !line.startsWith('---')) {
    return const Color(0xFFC62828);
  }
  return null;
}

/// Colored per-file diff viewer, reused by the Git diff dialog.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.content, required this.emptyLabel});

  final String content;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return SelectableText(
        emptyLabel,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }
    final List<DiffSection> sections = splitDiff(content);
    const TextStyle base = TextStyle(fontFamily: 'monospace', fontSize: 12);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final DiffSection section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.header.isNotEmpty)
                    SelectableText(
                      section.header,
                      style: base.copyWith(fontWeight: FontWeight.w700),
                    ),
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        for (final String line in section.lines)
                          TextSpan(
                            text: '$line\n',
                            style: base.copyWith(color: diffLineColor(line)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
