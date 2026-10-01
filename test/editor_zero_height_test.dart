import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/src/features/editor/re_editor_adapter.dart';

/// Regression test for the keyboard flap: when the workspace is squeezed to
/// zero height (open keyboard + tall tool drawer), the CodeEditor element
/// must STAY mounted (laid out at 1px) so re_editor's `maxHeight > 0`
/// assert holds and focus survives. Unmounting used to drop focus, hide
/// the keyboard, regrow the pane, remount with autofocus=true, and
/// oscillate the keyboard forever.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('squeezed editor stays mounted and keeps focus', (
    WidgetTester tester,
  ) async {
    double height = 400;
    late StateSetter setHeight;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setHeight = setState;
          return ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: height,
                  child: ReEditorAdapter(
                    initialText: 'void main() {}',
                    language: 'dart',
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CodeEditor), findsOneWidget);
    // The editor fills its pane (the 1px floor must not shrink normals).
    expect(tester.getSize(find.byType(CodeEditor)).height, 400);
    // autofocus=true mounts focused.
    expect(FocusManager.instance.primaryFocus, isNotNull);

    // Squeeze to zero: no crash, editor still mounted, focus retained.
    setHeight(() => height = 0);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(CodeEditor), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNotNull);

    // Space returns: full editor back, still focused, no crash.
    setHeight(() => height = 400);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(CodeEditor), findsOneWidget);
    expect(tester.getSize(find.byType(CodeEditor)).height, 400);
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });
}
