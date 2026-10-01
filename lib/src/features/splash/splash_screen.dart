import "dart:async";
import "dart:io" show Platform;

import "package:flutter/material.dart";

import "../../core/bridge/generated/ide_api.g.dart";
import "../../core/services/app_info_service.dart";
import "../../core/services/setup_service.dart";
import "../../../l10n/generated/app_localizations.dart";
import "../editor/autocomplete/language_members.dart";

/// Brand background for the splash. MUST stay in sync with
/// `android/.../res/values/colors.xml` (`splash_background`) so the
/// native -> Flutter handoff is invisible (no white flash).
abstract final class SplashColors {
  static const Color background = Color(0xFF13151B);
  static const Color primary = Color(0xFF4CC2FF);
  static const Color success = Color(0xFF34D399);
  static const Color foreground = Color(0xFFE8ECF3);
  static const Color muted = Color(0xFF8A919D);
  static const Color card = Color(0xFF1B1F29);
  static const Color track = Color(0xFF2A3040);
}

/// Last bootstrap probe result, shared with [IdeShell] so the shell does not
/// pay for a second platform-channel round trip on every cold start.
abstract final class SplashBootstrap {
  static SetupStatus? lastStatus;
  static bool probed = false;
}

/// True while running under `flutter test` (FLUTTER_TEST=true on the VM).
/// The gate skips its minimum display delay there so the existing widget
/// tests keep seeing [IdeShell] immediately.
bool get _isFlutterTest {
  try {
    return Platform.environment["FLUTTER_TEST"] == "true";
  } catch (_) {
    return false;
  }
}

/// Holds the splash on screen until the app is actually usable:
/// autocomplete tables warmed, setup status probed, and a minimum display
/// delay elapsed (premium feel). Never traps the user: any failure or the
/// [initTimeout] falls through to [child] with whatever state we have.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.minimumDuration = const Duration(milliseconds: 1600),
    this.initTimeout = const Duration(seconds: 8),
  });

  final Widget child;
  final Duration minimumDuration;
  final Duration initTimeout;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (_isFlutterTest) {
      // Widget tests run on a fake async clock where unhandled platform
      // channels stall (getStatus only resolves via its multi-second
      // timeout): flip on the next microtask and warm tables lazily.
      // IdeShell still probes setup itself through its original path.
      unawaited(_precacheLogo());
      unawaited(_warmTables());
      await Future.microtask(() {});
      if (mounted) setState(() => _ready = true);
      return;
    }
    final minDelay = widget.minimumDuration;
    // Fire-and-forget: image decoding can stall under flutter_test's fake
    // async clock, and a missing/slow logo must never block startup.
    unawaited(_precacheLogo());
    try {
      await Future.wait([
        Future<void>.delayed(minDelay),
        _warmup().timeout(
          widget.initTimeout,
          onTimeout: () {},
        ),
      ]);
    } catch (_) {
      // Fail open: the IDE shell shows its own retry UI.
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _precacheLogo() async {
    try {
      if (!mounted) return;
      await precacheImage(
        const AssetImage("assets/icon/logo.png"),
        context,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Missing/slow asset must not block startup.
    }
  }

  Future<void> _warmTables() async {
    try {
      await MemberRegistry.ensureLoaded();
    } catch (_) {
      // Autocomplete is optional for first paint.
    }
  }

  Future<void> _warmup() async {
    await _warmTables();
    // Refresh version/build from the platform package (already loaded in
    // main; best-effort here).
    await AppInfo.load();
    try {
      final status = await SetupService()
          .getStatus()
          .timeout(const Duration(seconds: 5));
      SplashBootstrap.lastStatus = status;
    } catch (_) {
      SplashBootstrap.lastStatus = null;
    } finally {
      SplashBootstrap.probed = true;
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isFlutterTest) return widget.child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: _ready
          ? KeyedSubtree(key: const ValueKey("app"), child: widget.child)
          : const KeyedSubtree(key: ValueKey("splash"), child: SplashScreen()),
    );
  }
}

/// Professional splash: staged logo entrance, terminal-style loader, and an
/// indeterminate progress bar. Pure Flutter (no extra packages): one entrance
/// controller plus lightweight timers for the breathing glow, status rotation,
/// and typing effect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _typedCommand = "> nova --init";

  /// Number of rotating loader statuses (matches [_statusesOf]).
  static const _statusCount = 4;

  /// Loader statuses, always from the translation files (ar/en).
  static List<String> _statusesOf(AppLocalizations l10n) => [
        l10n.splashStatusEngine,
        l10n.splashStatusSettings,
        l10n.splashStatusRuntime,
        l10n.splashStatusWorkspace,
      ];

  late final AnimationController _entrance;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _loaderFade;

  double _breath = 0.0;
  Timer? _breathTimer;
  Timer? _statusTimer;
  Timer? _typingTimer;
  int _statusIndex = 0;
  int _typedLength = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    // Timers start after the first frame so MediaQuery is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startEffects());
  }

  void _startEffects() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion || _isFlutterTest) {
      _entrance.value = 1.0;
      setState(() => _typedLength = _typedCommand.length);
      return;
    }
    _entrance.forward();
    // Gentle "breathing" glow on the logo (cheap: 50ms sine, no shader).
    var tick = 0;
    _breathTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      tick++;
      setState(() => _breath = (tick % 40) / 40.0);
    });
    // Rotating localized status line while the gate holds the splash.
    _statusTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) return;
      setState(() => _statusIndex = (_statusIndex + 1) % _statusCount);
    });
    // Terminal typing effect for "> nova --init".
    _typingTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _typedCommand.length) {
        timer.cancel();
        return;
      }
      setState(() => _typedLength++);
    });
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _statusTimer?.cancel();
    _typingTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Every human-readable string comes from the translation files (ar/en).
    // (The "> nova --init" line is a terminal command, not prose — it is
    // never translated. The version footer below IS translated; its numbers
    // come from the platform package via AppInfo.)
    final l10n = AppLocalizations.of(context);
    final statuses = _statusesOf(l10n);
    return Scaffold(
      backgroundColor: SplashColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _LogoMark(breath: _breath),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      children: [
                        const Text(
                          "Nova",
                          style: TextStyle(
                            color: SplashColors.foreground,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.splashTagline,
                          style: const TextStyle(
                            color: SplashColors.muted,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _loaderFade,
                  child: Column(
                    children: [
                      _TerminalLine(
                        typed: _typedCommand.substring(0, _typedLength),
                      ),
                      const SizedBox(height: 16),
                      const _LoadingBar(),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          statuses[_statusIndex],
                          key: ValueKey(_statusIndex),
                          style: const TextStyle(
                            color: SplashColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Version footer from the platform package (see AppInfo).
                // Hidden until loaded so a blank "v (build )" never flashes.
                if (AppInfo.isLoaded)
                  Text(
                    l10n.splashVersionFooter(
                      AppInfo.version,
                      AppInfo.buildNumber,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF4A5160),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo in a rounded tile with a soft brand glow behind it.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.breath});

  final double breath;

  @override
  Widget build(BuildContext context) {
    final glow = 0.35 + 0.25 * (1 - (breath * 2 - 1).abs());
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: SplashColors.primary.withValues(alpha: glow * 0.45),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          "assets/icon/logo.png",
          width: 128,
          height: 128,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: SplashColors.card,
            alignment: Alignment.center,
            child: const Text(
              ">_",
              style: TextStyle(
                color: SplashColors.primary,
                fontSize: 44,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mono terminal line with a blinking cursor.
class _TerminalLine extends StatefulWidget {
  const _TerminalLine({required this.typed});

  final String typed;

  @override
  State<_TerminalLine> createState() => _TerminalLineState();
}

class _TerminalLineState extends State<_TerminalLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    if (!_isFlutterTest) _blink.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SplashColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SplashColors.track),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.typed,
              style: const TextStyle(
                color: SplashColors.success,
                fontFamily: "monospace",
                fontFamilyFallback: ["Courier"],
                fontSize: 13,
              ),
            ),
          ),
          FadeTransition(
            opacity: _blink.drive(
              Tween<double>(begin: 1, end: 0.15),
            ),
            child: Container(
              width: 8,
              height: 15,
              margin: const EdgeInsetsDirectional.only(start: 2),
              color: SplashColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded indeterminate bar in brand colors.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: const LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: SplashColors.track,
          valueColor: AlwaysStoppedAnimation<Color>(SplashColors.primary),
        ),
      ),
    );
  }
}
