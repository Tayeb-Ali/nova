import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/src/core/ui/empty_state.dart';

void main() {
  testWidgets('EmptyState shows icon, title and action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search,
            title: 'No matches',
            subtitle: 'Try again',
            actionLabel: 'Retry',
            onAction: () => pressed = true,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(pressed, isTrue);
  });

  testWidgets('EmptyState without action hides button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.folder_open_outlined, title: 'Empty'),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsNothing);
  });
}
