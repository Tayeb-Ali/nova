/// Cursor-aware text insertion for AI results (pure, unit-testable).
///
/// The editor model is line/column based (`re_editor` `CodeLineSelection`
/// with line indices + char offsets) while its `text` is `\n`-joined, so
/// flat offsets are derived from the split lines. Out-of-range positions
/// are clamped; a reversed range is normalized.
class AiInsertResult {
  const AiInsertResult({
    required this.text,
    required this.cursorLine,
    required this.cursorColumn,
  });

  /// Full replacement document text.
  final String text;

  /// 0-based cursor line after the insert.
  final int cursorLine;

  /// 0-based cursor column after the insert.
  final int cursorColumn;
}

int _flatOffset(List<String> lines, int line, int column) {
  final int clampedLine = line.clamp(0, lines.length - 1);
  var offset = 0;
  for (var i = 0; i < clampedLine; i++) {
    // +1 for the '\n' joining the lines.
    offset += lines[i].length + 1;
  }
  return offset + column.clamp(0, lines[clampedLine].length);
}

(int line, int column) _lineColumnOf(List<String> lines, int offset) {
  var rest = offset.clamp(0, _totalLength(lines));
  for (var i = 0; i < lines.length; i++) {
    if (rest <= lines[i].length) return (i, rest);
    rest -= lines[i].length + 1;
  }
  final last = lines.length - 1;
  return (last, lines[last].length);
}

int _totalLength(List<String> lines) {
  var total = 0;
  for (var i = 0; i < lines.length; i++) {
    total += lines[i].length;
    if (i < lines.length - 1) total += 1;
  }
  return total;
}

/// Replaces the range
/// (`baseLine`,`baseColumn`)→(`extentLine`,`extentColumn`) in [text] with
/// [insert] and reports the new cursor position (end of the insert).
AiInsertResult applyInsert({
  required String text,
  required int baseLine,
  required int baseColumn,
  required int extentLine,
  required int extentColumn,
  required String insert,
}) {
  final List<String> lines = text.split('\n');
  var start = _flatOffset(lines, baseLine, baseColumn);
  var end = _flatOffset(lines, extentLine, extentColumn);
  if (start > end) {
    final int tmp = start;
    start = end;
    end = tmp;
  }
  final String next = text.replaceRange(start, end, insert);
  final (int cursorLine, int cursorColumn) = _lineColumnOf(
    next.split('\n'),
    start + insert.length,
  );
  return AiInsertResult(
    text: next,
    cursorLine: cursorLine,
    cursorColumn: cursorColumn,
  );
}
