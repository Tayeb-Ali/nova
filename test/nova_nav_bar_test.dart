import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/ui/nova_nav_bar.dart';

const _items = [
  NovaNavItem(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: 'Projects',
  ),
  NovaNavItem(
    icon: Icons.code_outlined,
    selectedIcon: Icons.code,
    label: 'Editor',
  ),
  NovaNavItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'SDK',
  ),
  NovaNavItem(
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune,
    label: 'Settings',
  ),
];

Widget _harness({required int selected, ValueChanged<int>? onSelect}) =>
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: NovaNavBar(
          selectedIndex: selected,
          onSelect: onSelect ?? (_) {},
          items: _items,
        ),
      ),
    );

void main() {
  testWidgets('tap selects the destination and reports its index', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _harness(selected: selected, onSelect: (i) => selected = i),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bar is compact and keeps every label mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(selected: 1));
    await tester.pump();
    // Let the selection tween finish so sizes are final.
    await tester.pump(const Duration(milliseconds: 300));

    // Pill (64) + margins: under the ~80px Material bar.
    expect(
      tester.getSize(find.byType(NovaNavBar)).height,
      lessThanOrEqualTo(78),
    );
    // Selected label unfolded; collapsed ones still in the tree.
    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance wrapper settles with the child visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NovaNavBarEntrance(
            child: Text('nav'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('nav'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
