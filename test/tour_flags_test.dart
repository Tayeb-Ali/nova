import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:nova/src/features/tour/tour_keys.dart';
import 'package:nova/src/features/tour/tour_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Backs SharedPreferences with an in-memory mock on the test messenger;
    // no device needed.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('TourKeys.all names are unique and keys are distinct objects', () {
    final entries = TourKeys.all;
    expect(entries, isNotEmpty);

    final names = entries.map((e) => e.$1).toList();
    expect(names.toSet(), hasLength(names.length));

    final keys = entries.map((e) => e.$2).toList();
    expect(keys.toSet(), hasLength(keys.length));
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        expect(identical(keys[i], keys[j]), isFalse);
      }
    }
  });

  test('isDone is false initially', () async {
    expect(await TourService.isDone('hub'), isFalse);
    expect(await TourService.isDone('editor'), isFalse);
  });

  test('resetAll clears done flags and the auto-start flag', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'nova.tourDone.hub': true,
      'nova.tourDone.editor': true,
      'nova.tourAutoStarted': true,
    });
    expect(await TourService.isDone('hub'), isTrue);
    expect(await TourService.isDone('editor'), isTrue);

    await TourService.resetAll();

    expect(await TourService.isDone('hub'), isFalse);
    expect(await TourService.isDone('editor'), isFalse);
    // Auto-start flag cleared too: a fresh prefs read shows it gone.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('nova.tourAutoStarted'), isNull);
  });

  testWidgets('contentAlignFor keeps low targets bubble-up', (
    WidgetTester tester,
  ) async {
    // Default test surface is 800x600: a target centered above 55% height
    // (330px) gets its bubble below; below it, above.
    final topKey = GlobalKey();
    final bottomKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 50),
              SizedBox(key: topKey, width: 100, height: 40),
              const Spacer(),
              SizedBox(key: bottomKey, width: 100, height: 40),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
    expect(TourService.contentAlignFor(topKey), ContentAlign.bottom);
    expect(TourService.contentAlignFor(bottomKey), ContentAlign.top);
    // Unmounted key falls back to bottom (never crashes the tour build).
    expect(TourService.contentAlignFor(GlobalKey()), ContentAlign.bottom);
  });
}
