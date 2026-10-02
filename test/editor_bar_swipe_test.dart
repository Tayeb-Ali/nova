import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';
import 'package:nova/src/core/ui/nova_nav_bar.dart';
import 'package:nova/src/features/workspace/workspace_screen.dart';

/// Editor-tab immersion: the editor opens with NO bottom bar (full editor
/// UI, nothing blank — only the bar is hidden). A swipe up from the bottom
/// edge reveals it for a few seconds, then it hides again; any tab switch
/// resets the state. Other tabs always keep the full bar.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    await tester.pump();
  }

  // Swipe up starting at the bottom edge, like revealing an immersive bar.
  Future<void> swipeUpFromEdge(WidgetTester tester) async {
    await tester.flingFrom(
      const Offset(180, 790),
      const Offset(0, -80),
      400,
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('editor opens normally with the bar hidden', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    expect(find.byType(NovaNavBar), findsOneWidget);

    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();

    // The editor screen itself opens normally — only the chrome is hidden.
    expect(find.byType(WorkspaceScreen), findsOneWidget);
    expect(find.byType(NovaNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom-edge swipe reveals the bar, then it hides again', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NovaNavBar), findsNothing);

    // Swipe up from the bottom edge: full bar slides in, still on editor.
    await swipeUpFromEdge(tester);
    expect(find.byType(NovaNavBar), findsOneWidget);
    expect(
      tester.widget<NovaNavBar>(find.byType(NovaNavBar)).selectedIndex,
      1,
    );

    // Immersive auto-hide: gone again after a few seconds, editor intact.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byType(NovaNavBar), findsNothing);
    expect(find.byType(WorkspaceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a tab from the revealed bar navigates away', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    await swipeUpFromEdge(tester);
    expect(find.byType(NovaNavBar), findsOneWidget);

    await tester.tap(find.text('SDK'));
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<NovaNavBar>(find.byType(NovaNavBar)).selectedIndex,
      2,
    );

    // Other tabs keep the full bar: no swipe needed.
    expect(find.byType(NovaNavBar), findsOneWidget);

    // Back to the editor: hidden again until the next swipe.
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NovaNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard hides the revealed bar while typing', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump();
    await swipeUpFromEdge(tester);
    expect(find.byType(NovaNavBar), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pump();
    expect(find.byType(NovaNavBar), findsNothing);

    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump();
    // Still inside the 4s reveal window (test time barely moved): back.
    expect(find.byType(NovaNavBar), findsOneWidget);
    // Window elapsed: hidden again until the next swipe.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byType(NovaNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
