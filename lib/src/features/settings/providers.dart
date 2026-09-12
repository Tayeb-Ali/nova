import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/settings_store.dart";

// Re-export of core settings provider for feature-local imports.
final settingsProvider = settingsStoreProvider;

// Exposes the notifier for writes from settings UI.
final settingsNotifierProvider = Provider<SettingsStore>(
  (ref) => ref.watch(settingsStoreProvider.notifier),
);
