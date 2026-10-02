import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';

/// System back button must ask before exiting: first press shows the exit
/// confirm, Cancel stays in the app, Exit calls SystemNavigator.pop.
/// Pushed routes (e.g. dialogs) still pop normally underneath.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('back shows exit confirm; cancel stays, exit pops', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    expect(find.byType(IdeShell), findsOneWidget);

    // First back press: confirm dialog, app still there.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Exit Nova?'), findsOneWidget);
    expect(find.byType(IdeShell), findsOneWidget);

    // Cancel: dialog gone, still in the app.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Exit Nova?'), findsNothing);
    expect(find.byType(IdeShell), findsOneWidget);

    // Exit: SystemNavigator.pop is requested (mocked channel).
    final pops = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          pops.add(call);
          return null;
        });
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Exit Nova?'), findsOneWidget);
    await tester.tap(find.text('Exit'));
    await tester.pump();
    expect(
      pops.any((c) => c.method == 'SystemNavigator.pop'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
