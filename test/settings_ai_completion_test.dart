import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:nova/src/core/settings_store.dart";

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsStore> loadedStore() async {
    final store = SettingsStore();
    // Let the async load() in the constructor finish.
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return store;
  }

  group("aiCompletionEnabled", () {
    test("defaults to true (preserves current behavior)", () {
      expect(const Settings().aiCompletionEnabled, isTrue);
    });

    test("copyWith carries the flag", () {
      const base = Settings();
      expect(base.copyWith().aiCompletionEnabled, isTrue);
      expect(
        base.copyWith(aiCompletionEnabled: false).aiCompletionEnabled,
        isFalse,
      );
      expect(
        base
            .copyWith(aiCompletionEnabled: false)
            .copyWith()
            .aiCompletionEnabled,
        isFalse,
      );
    });

    test("toggle persists across reloads", () async {
      final store = await loadedStore();
      expect(store.state.aiCompletionEnabled, isTrue);
      await store.setAiCompletionEnabled(false);
      expect(store.state.aiCompletionEnabled, isFalse);

      final reloaded = await loadedStore();
      expect(reloaded.state.aiCompletionEnabled, isFalse);

      await reloaded.setAiCompletionEnabled(true);
      final reloadedAgain = await loadedStore();
      expect(reloadedAgain.state.aiCompletionEnabled, isTrue);
    });

    test("setAppLocale keeps the flag (no reset to default)", () async {
      final store = await loadedStore();
      await store.setAiCompletionEnabled(false);
      await store.setAppLocale("ar");
      expect(store.state.aiCompletionEnabled, isFalse);
      expect(store.state.appLocale, "ar");
    });
  });
}

