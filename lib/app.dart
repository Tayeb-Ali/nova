import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "l10n/generated/app_localizations.dart";
import "src/core/services/setup_service.dart";
import "src/core/ui/keyboard_visibility.dart";
import "src/core/ui/nova_nav_bar.dart";
import "src/features/workspace/workspace_providers.dart";
import "src/features/setup/setup_wizard_dialog.dart";
import "src/core/settings_store.dart";
import "src/features/editor/autocomplete/language_members.dart";
import "src/features/editor/theme/app_theme.dart";
import "src/features/editor/theme/theme_pack_store.dart";
import "src/features/runtime/runtime_screen.dart";
import "src/features/settings/settings_screen.dart";
import "src/features/splash/splash_screen.dart";
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
      // Branded splash first: holds a loader until the engine is warm, then
      // fades into the shell. Kills the white first-frame flash.
      home: const SplashGate(child: IdeShell()),
    );
  }
}

/// Bottom navigation shell over the IDE workspaces.
class IdeShell extends ConsumerStatefulWidget {
  const IdeShell({super.key});

  @override
  ConsumerState<IdeShell> createState() => _IdeShellState();
}

class _IdeShellState extends ConsumerState<IdeShell> {
  int _index = 0;
  bool _bootstrapPromptShown = false;
  // Editor-tab immersion: the editor opens with NO bottom bar so code keeps
  // maximum space. A swipe up from the bottom edge reveals the full bar for
  // a few seconds (then it hides again); any tab switch resets the state.
  // Keyboard/focus hiding still wins over both states.
  bool _editorBarVisible = false;
  Timer? _editorBarTimer;
  Offset? _edgeSwipeStart;

  void _selectNav(int nav) {
    _editorBarTimer?.cancel();
    _editorBarTimer = null;
    setState(() {
      _index = nav;
      _editorBarVisible = false;
    });
  }

  void _openEditor() => _selectNav(1);

  void _revealEditorBar() {
    if (_index != 1 || _editorBarVisible) return;
    _editorBarTimer?.cancel();
    setState(() => _editorBarVisible = true);
    // Immersive-style auto-hide: the bar goes away on its own; selecting a
    // tab hides it immediately via [_selectNav].
    _editorBarTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _editorBarVisible = false);
    });
  }

  // Bottom-edge swipe-up detector (passive [Listener]: never competes with
  // editor scrolling). Only the editor tab uses it; everywhere else the
  // full bar is always visible.
  void _onPointerDown(PointerDownEvent event) {
    _edgeSwipeStart = event.position;
  }

  void _onPointerMove(PointerEvent event) {
    final start = _edgeSwipeStart;
    if (start == null || _index != 1 || _editorBarVisible) return;
    final height = MediaQuery.sizeOf(context).height;
    if (start.dy >= height - _edgeSwipeZone &&
        start.dy - event.position.dy >= _edgeSwipeDistance) {
      _edgeSwipeStart = null;
      _revealEditorBar();
    }
  }

  void _onPointerEnd(PointerEvent event) {
    _edgeSwipeStart = null;
  }

  static const double _edgeSwipeZone = 48;
  static const double _edgeSwipeDistance = 48;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBootstrap());
    MemberRegistry.ensureLoaded();
  }

  Future<void> _checkBootstrap() async {
    if (_bootstrapPromptShown) return;
    _bootstrapPromptShown = true;
    // Reuse the splash gate's probe when available (no second bridge call).
    final cached = SplashBootstrap.probed ? SplashBootstrap.lastStatus : null;
    bool missing = false;
    if (cached != null) {
      missing = !cached.ready;
    } else {
      try {
        final status = await SetupService().getStatus();
        missing = !status.ready;
      } catch (_) {
        return;
      }
    }
    if (!missing || !mounted) return;
    // Setup wizard (NEXT_PLAN 3.2): slim/full choice + progress + retry.
    // It drives SetupService itself; a completed wizard lands on Runtimes.
    final done = await showSetupWizard(context);
    if (!mounted) return;
    if (done == true) _selectNav(2);
  }

  @override
  void dispose() {
    _editorBarTimer?.cancel();
    super.dispose();
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
    // Captured ABOVE this Scaffold: Scaffold strips the bottom inset from
    // the MediaQuery it gives its body, so descendants must read the
    // value through KeyboardVisibility instead.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visibleBody = KeyboardVisibility(
      visible: keyboardVisible,
      child: body,
    );
    // Nav labels only: localized via existing keys.
    final l10n = AppLocalizations.of(context);
    final navItems = [
      NovaNavItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        label: l10n.navProjects,
      ),
      NovaNavItem(
        icon: Icons.code_outlined,
        selectedIcon: Icons.code,
        label: l10n.navEditor,
      ),
      NovaNavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: l10n.navPackagesSdk,
      ),
      NovaNavItem(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
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
            Expanded(child: visibleBody),
          ],
        ),
      );
    }
    return Scaffold(
      // Editor immersion: no bottom bar in the editor tab — a swipe up
      // from the bottom edge reveals it for a few seconds (see the
      // edge-swipe detector below). The Listener ALWAYS wraps the body
      // (never swapped conditionally): changing the widget type here would
      // remount the whole shell on every tab switch and wipe screen state.
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: visibleBody,
      ),
      // Distraction-free typing: while the keyboard is up the bottom bar
      // is pure chrome. Hide it so the editor keeps maximum height; it
      // slides back up the moment the keyboard closes. Focus mode hides
      // it too (same chrome argument, no keyboard required). Removal is
      // instant (space reclaimed now); appearance animates via
      // [NovaNavBarEntrance].
      bottomNavigationBar:
          (keyboardVisible ||
              ref.watch(focusModeProvider) ||
              (_index == 1 && !_editorBarVisible))
          ? null
          : NovaNavBarEntrance(
              child: NovaNavBar(
                selectedIndex: _index,
                onSelect: _selectNav,
                items: navItems,
              ),
            ),
    );
  }
}