import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "src/core/settings_store.dart";
import "src/features/editor/theme/app_theme.dart";
import "src/features/editor/theme/theme_pack_store.dart";
import "src/features/git/git_screen.dart";
import "src/features/process/process_screen.dart";
import "src/features/runtime/runtime_screen.dart";
import "src/features/settings/settings_screen.dart";
import "src/features/terminal/terminal_screen.dart";
import "src/features/workspace/workspace_screen.dart";

/// Nova IDE root widget (task.md §1 §35).
class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStoreProvider);
    // Rebuild app themes when packs change; the whole app follows the
    // editor colors while follow-mode is on.
    ref.watch(editorThemeStoreProvider);
    final themeStore = ref.read(editorThemeStoreProvider.notifier);
    final follow = settings.followEditorTheme;
    return MaterialApp(
      title: "Nova",
      debugShowCheckedModeBanner: false,
      theme: follow
          ? AppTheme.fromPack(themeStore.packFor(Brightness.light))
          : AppTheme.fallback(Brightness.light),
      darkTheme: follow
          ? AppTheme.fromPack(themeStore.packFor(Brightness.dark))
          : AppTheme.fallback(Brightness.dark),
      themeMode: settings.themeMode,
      home: const IdeShell(),
    );
  }
}

/// Bottom navigation shell over the IDE workspaces.
class IdeShell extends StatefulWidget {
  const IdeShell({super.key});

  @override
  State<IdeShell> createState() => _IdeShellState();
}

class _IdeShellState extends State<IdeShell> {
  int _index = 0;

  static const _screens = <Widget>[
    WorkspaceScreen(),
    TerminalScreen(),
    RuntimeScreen(),
    ProcessScreen(),
    GitScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_open),
            label: "Workspace",
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            label: "Terminal",
          ),
          NavigationDestination(
            icon: Icon(Icons.memory),
            label: "Runtime",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_input_component),
            label: "Process",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree),
            label: "Git",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}