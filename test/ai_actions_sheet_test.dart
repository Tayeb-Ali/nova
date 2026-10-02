import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/features/ai/ai_actions.dart';
import 'package:nova/src/features/ai/ai_client.dart';

class _FakeAi extends AiClient {
  _FakeAi() : super(dio: null);

  @override
  Future<String> call({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int? maxTokens,
  }) async =>
      'fixed-result';
}

void main() {
  testWidgets('Insert button delivers the result and closes', (
    WidgetTester tester,
  ) async {
    final inserted = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AiActionsSheet.show(
                  context,
                  selectedCode: 'x = 1',
                  clientOverride: _FakeAi(),
                  onInsert: inserted.add,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // No insert action before a result exists.
    expect(find.text('Insert into editor'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'k');
    await tester.tap(find.text('Complete code'));
    await tester.pumpAndSettle();

    expect(find.text('fixed-result'), findsOneWidget);
    await tester.tap(find.text('Insert into editor'));
    await tester.pumpAndSettle();

    expect(inserted, ['fixed-result']);
    // Sheet popped.
    expect(find.text('fixed-result'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
