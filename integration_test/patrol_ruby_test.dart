// Patrol E2E: Ruby runtime install flow (SDK tab).
//
// Device preconditions: bootstrap READY, app installed.
// Flow: boot app -> SDK tab -> assert Bootstrap Ready + Ruby Available ->
// tap Ruby Install -> wait for Installed chip (<=10 min) ->
// assert Installed state + resolved version text.
//
// Run:
//   patrol test --target integration_test/patrol_ruby_test.dart
//     --flavor github -d emulator-5554
//
// Notes:
// - Uses English UI strings (device locale en-US).
// - A notification-permission system dialog is granted if it appears.
// - Running `ruby -v` via the terminal UI is intentionally NOT attempted:
//   asserting the Installed chip + resolved version text is the stable signal.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/app.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'ruby runtime installs from SDK tab',
    ($) async {
      await $.pumpWidgetAndSettle(const ProviderScope(child: NovaApp()));

      // System permission dialog (e.g. notifications for the foreground
      // service): grant it when present, otherwise carry on.
      if (await $.platformAutomator.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 5),
      )) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // SDK tab.
      await $('SDK').waitUntilVisible(timeout: const Duration(seconds: 60));
      await $('SDK').tap();
      await $.pumpAndSettle();

      // Bootstrap is ready on this device.
      await $('Bootstrap is ready. Runtimes can be installed below.')
          .waitUntilVisible(timeout: const Duration(seconds: 60));
      expect($('Ready'), findsOneWidget);

      // Narrow the list to the Ruby tile (no pack name contains 'ruby',
      // so exactly one tile remains).
      await $(TextField).tap();
      await $(TextField).enterText('ruby');
      await $.pumpAndSettle();
      await $('Ruby').waitUntilVisible(timeout: const Duration(seconds: 30));

      if ($('Installed').exists) {
        // Already installed (e.g. test re-run): assert state below.
        expect($('Installed'), findsWidgets);
      } else {
        // Fresh install path: key finder is unambiguous (no text matching).
        expect($('Available'), findsOneWidget);
        await $('Ruby').scrollTo();
        await $(find.byKey(const ValueKey('install-ruby'))).tap();
        await $('Installed').waitUntilVisible(
          timeout: const Duration(minutes: 10),
        );
      }

      // Installed state + resolved version text (not the placeholder).
      await $('Installed')
          .waitUntilVisible(timeout: const Duration(seconds: 30));
      expect($(RegExp(r'Version: ')), findsWidgets);
      expect($('Version: —'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
