import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova/app.dart';

void main() {
  testWidgets('NovaApp boots with home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NovaApp()));
    await tester.pump();
    expect(find.text('Nova'), findsOneWidget);
  });
}
