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
    GitScreen(),
    RuntimeScreen(),
    ProcessScreen(),
    SettingsScreen(),
  ];

  /// Bottom bar / rail position for [_index]; tools live under More (3).
  int get _navIndex => _index <= 2 ? _index : 3;

  void _selectNav(int nav) {
    if (nav == 3) {
      _openMore();
      return;
    }
    setState(() => _index = nav);
  }

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text("Tools"),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: const Text("Runtime"),
              subtitle: const Text("Runtimes and packages"),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _index = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_component_outlined),
              title: const Text("Process"),
              subtitle: const Text("Running processes"),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _index = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              subtitle: const Text("Theme, editor, AI"),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _index = 5);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: IndexedStack(index: _index, children: _screens));
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.folder_open),
        label: "Workspace",
      ),
      NavigationDestination(
        icon: Icon(Icons.terminal),
        label: "Terminal",
      ),
      NavigationDestination(
        icon: Icon(Icons.account_tree),
        label: "Git",
      ),
      NavigationDestination(
        icon: Icon(Icons.more_horiz),
        label: "More",
      ),
    ];
    // Wide screens (tablet/landscape/desktop): side rail instead of bottom bar.
    if (MediaQuery.sizeOf(context).width >= 700) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _navIndex,
              onDestinationSelected: _selectNav,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_open),
                  label: Text("Workspace"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.terminal),
                  label: Text("Terminal"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_tree),
                  label: Text("Git"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.more_horiz),
                  label: Text("More"),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _selectNav,
        destinations: destinations,
      ),
    );
  }
}