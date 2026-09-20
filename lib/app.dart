import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "l10n/generated/app_localizations.dart";
import "src/core/services/setup_service.dart";
import "src/core/settings_store.dart";
import "src/features/editor/theme/app_theme.dart";
import "src/features/editor/theme/theme_pack_store.dart";
import "src/features/runtime/runtime_screen.dart";
import "src/features/settings/settings_screen.dart";
import "src/features/workspace/projects_hub_screen.dart";
import "src/features/workspace/workspace_screen.dart";

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStoreProvider);
    
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
  bool _bootstrapPromptShown = false;

  void _selectNav(int nav) => setState(() => _index = nav);

  void _openEditor() => setState(() => _index = 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBootstrap());
  }

  Future<void> _checkBootstrap() async {
    if (_bootstrapPromptShown) return;
    _bootstrapPromptShown = true;
    bool missing = false;
    try {
      final status = await SetupService().getStatus();
      missing = !status.ready;
    } catch (_) {
      return;
    }
    if (!missing || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final download = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.bootstrapRequired),
        content: Text(l10n.bootstrapRequiredBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDownload),
          ),
        ],
      ),
    );
    if (download != true || !mounted) return;
    _selectNav(2);
    try {
      await SetupService().startSetup();
    } catch (_) {
      //nothing to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ProjectsHubScreen(onOpenEditor: _openEditor),
      const WorkspaceScreen(),
      const RuntimeScreen(),
      const SettingsScreen(),
    ];
    final body = SafeArea(child: IndexedStack(index: _index, children: screens));
    // Nav labels only: localized via existing keys.
    final l10n = AppLocalizations.of(context);
    final destinations = [
      NavigationDestination(
        icon: Icon(Icons.folder_open),
        label: l10n.navProjects,
      ),
      NavigationDestination(
        icon: Icon(Icons.code),
        label: l10n.navEditor,
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2),
        label: l10n.navPackagesSdk,
      ),
      NavigationDestination(
        icon: Icon(Icons.tune),
        label: l10n.navSettings,
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
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_open),
                  label: Text(l10n.navProjects),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.code),
                  label: Text(l10n.navEditor),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2),
                  label: Text(l10n.navPackagesSdk),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune),
                  label: Text(l10n.navSettings),
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