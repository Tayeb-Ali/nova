import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "l10n/generated/app_localizations.dart";
import "src/core/services/fcm_service.dart";
import "src/core/services/notification_service.dart";
import "src/core/services/setup_service.dart";
import "src/core/ui/keyboard_visibility.dart";
import "src/core/ui/nova_nav_bar.dart";
import "src/features/workspace/workspace_providers.dart";
import "src/features/onboarding/first_run_flow.dart";
import "src/features/setup/setup_wizard_dialog.dart";
import "src/core/settings_store.dart";
import "src/features/editor/autocomplete/language_members.dart";
import "src/features/editor/theme/app_theme.dart";
import "src/features/editor/theme/theme_pack_store.dart";
import "src/features/notifications/notifications_bell.dart";
import "src/features/notifications/notifications_screen.dart";
import "src/features/notifications/notifications_store.dart";
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
      // Before the first-launch language choice the UI is English
      // (the requirement default); afterwards the saved locale — or the
      // system locale when the user picked "System".
      locale: !settings.languageChosen
          ? const Locale("en")
          : (settings.appLocale == null
                ? null
                : Locale(settings.appLocale!)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Branded splash first: holds a loader until the engine is warm, then
      // fades into the shell. Kills the white first-frame flash.
      // FirstRunFlow inserts the language picker + intro slides on a fresh
      // install (skipped for returning users and in widget tests).
      home: const SplashGate(child: FirstRunFlow(child: IdeShell())),
      // Deep-link targets for notification taps (FCM data["route"] and the
      // system-tray payload). Pushes are best-effort and never guarded.
      routes: {
        NotificationsScreen.routeName: (_) => const NotificationsScreen(),
      },
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
  // Exit confirmation: guards against accidental back-press exits.
  bool _exitDialogOpen = false;
  // FCM foreground wiring (guest-first, best-effort): foreground messages land
  // in the in-app center via the store, and tap routes deep-link via
  // pushNamed. The native event channel is untouched (IdeEventBus still owns
  // its single listener); FCM/NotificationService use their own channels.
  //
  // Created lazily inside [_initFcm]: the constructor touches
  // `FirebaseMessaging.instance`, which throws with no Firebase app (widget
  // tests, offline first-run), so it must never run during State creation.
  StreamSubscription<String>? _fcmRouteSub;
  StreamSubscription<String>? _trayRouteSub;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBootstrap();
      _initFcm();
    });
    MemberRegistry.ensureLoaded();
  }

  /// Starts FCM (permission, topic, token, foreground display) and wires tap
  /// routes. Never throws; SplashGate/bootstrap logic is untouched.
  Future<void> _initFcm() async {
    if (!mounted) return;
    // Capture the notifier once: the onNotification callback stays safe even
    // if this State is disposed before a message arrives.
    final store = ref.read(notificationsStoreProvider.notifier);
    late final FcmService fcm;
    try {
      fcm = FcmService();
    } catch (_) {
      // No Firebase app (widget tests, offline first-run): nothing to wire.
      return;
    }
    try {
      await fcm.init(onNotification: store.push);
    } catch (_) {
      // FCM unavailable (offline / no Play services): guest mode continues.
    }
    // Cold-start tap: terminated-app FCM tap first, then the system-tray tap.
    try {
      final pending =
          await fcm.getInitialRoute() ??
          await NotificationService.instance.getInitialRoute();
      if (pending != null && pending.isNotEmpty) _openRoute(pending);
    } catch (_) {}
    // Background taps while alive: FCM + tray streams merged to one handler.
    try {
      _fcmRouteSub = fcm.onRouteOpened.listen(_openRoute);
      _trayRouteSub = NotificationService.instance.onRouteTap.listen(
        _openRoute,
      );
    } catch (_) {}
  }

  /// Best-effort deep-link: unknown routes are ignored, never crash.
  void _openRoute(String route) {
    if (!mounted || route.isEmpty) return;
    try {
      Navigator.of(context).pushNamed(route);
    } catch (_) {
      // Route not registered: the notification itself already landed.
    }
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

  // System back button must not kill the app silently: ask first. Pushed
  // routes (dialogs, About screen) pop normally above this scope — this
  // only fires at the root, where a pop would mean exiting.
  Future<void> _confirmExit() async {
    if (_exitDialogOpen || !mounted) return;
    _exitDialogOpen = true;
    final l10n = AppLocalizations.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appExitTitle),
        content: Text(l10n.appExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionExit),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (exit == true && mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _editorBarTimer?.cancel();
    _fcmRouteSub?.cancel();
    _trayRouteSub?.cancel();
    super.dispose();
  }

  /// Wraps a shell body with the notification bell: a compact floating
  /// circle just below the screen AppBar (top-end, RTL-aware) with the
  /// unread badge. Overlay-only — screens, nav, and Scaffold structure
  /// are untouched; the bell pushes the notifications screen.
  ///
  /// The Stack itself is ALWAYS built (swapping it conditionally would
  /// remount the whole shell on every tab switch and wipe screen state —
  /// same rule as the editor edge-swipe Listener below); only the badge
  /// overlay is skipped on the editor tab ([_index] == 1), where the
  /// floating circle would sit exactly on the tab strip's trailing actions
  /// (overflow menu) on phone widths and swallow their taps. The bell stays
  /// one tap away on every other tab, and tray deep-links still work.
  Widget _withBell(Widget child) {
    return Stack(
      children: [
        child,
        if (_index != 1)
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            end: 12,
            child: Material(
              type: MaterialType.circle,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
              elevation: 3,
              child: const NotificationsBell(),
            ),
          ),
      ],
    );
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
    // Both layouts share one PopScope exit guard at the end, so the shell
    // is built into a local first.
    final Widget scaffold;
    if (MediaQuery.sizeOf(context).width >= 700) {
      scaffold = Scaffold(
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
            Expanded(child: _withBell(visibleBody)),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
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
        child: _withBell(visibleBody),
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
    // Back button guard (both layouts): exiting asks first, never silently.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: scaffold,
    );
  }
}