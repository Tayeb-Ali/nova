import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/editor/ai_insert.dart';

void main() {
  test('collapsed insert places text and cursor', () {
    final result = applyInsert(
      text: 'ab\ncd',
      baseLine: 0,
      baseColumn: 1,
      extentLine: 0,
      extentColumn: 1,
      insert: 'X',
    );
    expect(result.text, 'aXb\ncd');
    expect((result.cursorLine, result.cursorColumn), (0, 2));
  });

  test('range replace across lines', () {
    final result = applyInsert(
      text: 'ab\ncd\nef',
      baseLine: 0,
      baseColumn: 1,
      extentLine: 1,
      extentColumn: 1,
      insert: 'Z',
    );
    expect(result.text, 'aZd\nef');
    expect((result.cursorLine, result.cursorColumn), (0, 2));
  });

  test('reversed range is normalized', () {
    final result = applyInsert(
      text: 'hello',
      baseLine: 0,
      baseColumn: 5,
      extentLine: 0,
      extentColumn: 0,
      insert: 'x',
    );
    expect(result.text, 'x');
    expect((result.cursorLine, result.cursorColumn), (0, 1));
  });

  test('out-of-range positions are clamped', () {
    final result = applyInsert(
      text: 'ab',
      baseLine: 9,
      baseColumn: 99,
      extentLine: 9,
      extentColumn: 99,
      insert: '!',
    );
    expect(result.text, 'ab!');
    expect((result.cursorLine, result.cursorColumn), (0, 3));
  });

  test('multiline insert reports the right cursor line', () {
    final result = applyInsert(
      text: 'a',
      baseLine: 0,
      baseColumn: 1,
      extentLine: 0,
      extentColumn: 1,
      insert: 'x\ny\n',
    );
    expect(result.text, 'ax\ny\n');
    expect((result.cursorLine, result.cursorColumn), (2, 0));
  });
}
