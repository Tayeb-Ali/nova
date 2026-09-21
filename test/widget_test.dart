import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova/app.dart';

void main() {
  setUp(() {
    // SettingsScreen loads settings through SharedPreferences; provide an
    // in-memory store so the channel never touches the platform.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NovaApp boots into the IDE shell', (WidgetTester tester) async {
    // Phone-sized viewport: bottom navigation. (Wide viewports render a
    // NavigationRail instead; covered by layout logic, not here.)
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    // Let the first frame and any post-frame providers settle.
    await tester.pump();
    await tester.pump();
    expect(find.byType(IdeShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
