import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/features/workspace/workspace_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('debug insets propagation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    await tester.pump();

    // ignore: avoid_print
    print('Editor texts: ${find.text('Editor').evaluate().length}');
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    // ignore: avoid_print
    print('AppBars after tap: ${find.byType(AppBar).evaluate().length}');

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pump();
    // ignore: avoid_print
    print('AppBars with keyboard: ${find.byType(AppBar).evaluate().length}');
    // ignore: avoid_print
    print('NavBars with keyboard: ${find.byType(NavigationBar).evaluate().length}');
    for (final e in find.byType(AppBar).evaluate()) {
      final w = e.widget as AppBar;
      // ignore: avoid_print
      print('AppBar title runtime: ${w.title.runtimeType}');
    }
    // ignore: avoid_print
    print('toolbarHide tooltips: ${find.byTooltip('Hide toolbar').evaluate().length}');
    // ignore: avoid_print
    print('toolbarShow tooltips: ${find.byTooltip('Show toolbar').evaluate().length}');
    // ignore: avoid_print
    print('slim strip Text Workspace: ${find.text('Workspace').evaluate().length}');
    final ideShellEl = tester.element(find.byType(IdeShell));
    // ignore: avoid_print
    print('IdeShell insets: ${MediaQuery.viewInsetsOf(ideShellEl)}');
    final wsScreenEl = tester.element(find.byType(WorkspaceScreen));
    // ignore: avoid_print
    print('WorkspaceScreen insets: ${MediaQuery.viewInsetsOf(wsScreenEl)}');
  });
}
