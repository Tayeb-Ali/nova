// Intro slides shown once after the language picker on a fresh install.
//
// Four pages (editor / terminal / AI / projects), PageView with animated
// dots, per-page icon + text entrance, Skip / Next / Get started actions.
// Pure Flutter animations (no extra packages); honors disableAnimations.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/settings_store.dart";
import "../splash/splash_screen.dart" show SplashColors;

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
}

List<_Slide> _slidesOf(AppLocalizations l10n) => [
  _Slide(Icons.code_rounded, (t) => t.onboard1Title, (t) => t.onboard1Body),
  _Slide(
    Icons.terminal_rounded,
    (t) => t.onboard2Title,
    (t) => t.onboard2Body,
  ),
  _Slide(
    Icons.auto_awesome_rounded,
    (t) => t.onboard3Title,
    (t) => t.onboard3Body,
  ),
  _Slide(
    Icons.source_rounded,
    (t) => t.onboard4Title,
    (t) => t.onboard4Body,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref.read(settingsStoreProvider.notifier).completeOnboarding();
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _next(int count) {
    if (_index + 1 >= count) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = _slidesOf(l10n);
    final scheme = Theme.of(context).colorScheme;
    final last = _index == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlidePage(
                  key: ValueKey(i),
                  slide: slides[i],
                  l10n: l10n,
                ),
              ),
            ),
            // Animated dots.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _finishing ? null : () => _next(slides.length),
                child: _finishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(last ? l10n.onboardStart : l10n.onboardNext),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// One slide: glowing icon tile + title + body, all entering with a
/// staggered slide-up + fade (replayed on every page visit via the page key).
class _SlidePage extends StatelessWidget {
  const _SlidePage({super.key, required this.slide, required this.l10n});

  final _Slide slide;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconTile(icon: slide.icon),
          const SizedBox(height: 32),
          Text(
            slide.title(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
    if (reduceMotion) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 32 * (1 - t)),
          child: child,
        ),
      ),
      child: content,
    );
  }
}

/// Brand icon tile with a soft glow (same palette as the splash).
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: SplashColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SplashColors.track),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 56, color: SplashColors.primary),
    );
  }
}
