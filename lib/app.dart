import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "src/core/settings_store.dart";
import "src/features/home/home_screen.dart";

// Root Nova application widget. ProviderScope must wrap this in main.
class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStoreProvider);
    return MaterialApp(
      title: "Nova",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
