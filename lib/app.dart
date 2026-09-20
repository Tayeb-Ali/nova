import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "l10n/generated/app_localizations.dart";
import "src/core/settings_store.dart";
import "src/features/editor/theme/app_theme.dart";
import "src/features/editor/theme/theme_pack_store.dart";
import "src/features/runtime/runtime_screen.dart";
import "src/features/settings/settings_screen.dart";
import "src/features/workspace/projects_hub_screen.dart";
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
      locale: settings.appLocale == null
          ? null
          : Locale(settings.appLocale!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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

  void _selectNav(int nav) => setState(() => _index = nav);

  void _openEditor() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ProjectsHubScreen(onOpenEditor: _openEditor),
      const WorkspaceScreen(),
      const RuntimeScreen(),
      const SettingsScreen(),
    ];
    final body = SafeArea(child: IndexedStack(index: _index, children: screens));
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.folder_open),
        label: "Projects",
      ),
      NavigationDestination(
        icon: Icon(Icons.code),
        label: "Editor",
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2),
        label: "Packages",
      ),
      NavigationDestination(
        icon: Icon(Icons.tune),
        label: "Settings",
      ),
    ];
    // Wide screens (tablet/landscape/desktop): side rail instead of bottom bar.
    if (MediaQuery.sizeOf(context).width >= 700) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _selectNav,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_open),
                  label: Text("Projects"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.code),
                  label: Text("Editor"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2),
                  label: Text("Packages"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune),
                  label: Text("Settings"),
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
        selectedIndex: _index,
        onDestinationSelected: _selectNav,
        destinations: destinations,
      ),
    );
  }
}