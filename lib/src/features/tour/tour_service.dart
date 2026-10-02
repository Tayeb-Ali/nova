import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tutorial_coach_mark/tutorial_coach_mark.dart";

import "tour_state.dart";

// Coach-mark tour runner (tutorial_coach_mark) + completion persistence.
//
// Per-tour content lives in `tours/*_tour.dart` (owned by content agents):
// each file exposes a `List<TargetFocus> Function(AppLocalizations)`
// builder that this service runs. This file owns ONLY the runner, the
// standard bubble, the active flag, and the SharedPreferences flags.
//
// All-real-press contract (content agents must follow it per target):
//   - set `enableTargetTab: true` on every TargetFocus so tapping the REAL
//     widget advances the tour (via [onClickTarget] below);
//   - leave `enableOverlayTab` at its default (false) so overlay taps do NOT
//     advance — the user presses real UI, never empty space.
class TourService {
  static const _donePrefix = "nova.tourDone.";
  static const _autoStartedKey = "nova.tourAutoStarted";

  /// Observability hook: invoked with the tapped target on every real
  /// target press, before the 600ms settle delay + `next()`.
  static void Function(TargetFocus)? onTargetTap;

  /// Assigned once by the hub content agent at startup
  /// (`hub_tour.dart`: `TourService.hubTargetsBuilder = buildHubTargets;`).
  /// Null until then, in which case [autoStartHubIfNeeded] only marks the
  /// auto-start flag and returns — standalone-safe, no import needed here.
  static List<TargetFocus> Function(AppLocalizations)? hubTargetsBuilder;

  static String _doneKey(String id) => "$_donePrefix$id";

  /// Runs the tour [id] built by [buildTargets].
  ///
  /// Targets whose `keyTarget?.currentContext == null` (widget off-screen,
  /// hidden chrome, unattached key) are filtered out so the coach never
  /// points at nothing; an empty survivor list is a silent no-op.
  /// [tourActiveProvider] is true while the overlay is up (try/finally, so a
  /// throwing builder still clears it). Finish AND skip persist
  /// `nova.tourDone.<id>`.
  static Future<void> startTour(
    BuildContext context,
    WidgetRef ref,
    String id,
    List<TargetFocus> Function(AppLocalizations) buildTargets,
  ) async {
    AppLocalizations l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      return;
    }
    List<TargetFocus> targets;
    try {
      targets = buildTargets(
        l10n,
      ).where((t) => t.keyTarget?.currentContext != null).toList();
    } catch (_) {
      return;
    }
    if (targets.isEmpty || !context.mounted) return;

    ref.read(tourActiveProvider.notifier).state = true;
    try {
      late final TutorialCoachMark coach;
      Future<void> markDone() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_doneKey(id), true);
        } catch (_) {
          // Completion persistence is best-effort; the tour UX already ran.
        }
      }

      coach = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black87,
        pulseEnable: true,
        focusAnimationDuration: const Duration(milliseconds: 500),
        // All-real-press: a tap on the highlighted widget notifies the hook,
        // waits 600ms for the pressed UI to settle, then advances.
        onClickTarget: (target) async {
          onTargetTap?.call(target);
          await Future<void>.delayed(const Duration(milliseconds: 600));
          coach.next();
        },
        onFinish: () {
          ref.read(tourActiveProvider.notifier).state = false;
          markDone();
        },
        onSkip: () {
          ref.read(tourActiveProvider.notifier).state = false;
          markDone();
          return true;
        },
        skipWidget: Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () => coach.skip(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(l10n.onboardSkip),
          ),
        ),
      );
      coach.show(context: context);
    } catch (_) {
      ref.read(tourActiveProvider.notifier).state = false;
    }
  }

  /// Picks the bubble side from the target's live position: targets in the
  /// lower part of the screen get their bubble ABOVE them (otherwise the
  /// bubble runs off-screen and its Next button becomes unreachable — only
  /// Skip stays visible). Needs no BuildContext: uses the engine view size.
  /// Falls back to bottom when the target is unmounted or has no size.
  static ContentAlign contentAlignFor(GlobalKey key) {
    try {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return ContentAlign.bottom;
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return ContentAlign.bottom;
      final view = views.first;
      final height = view.physicalSize.height / view.devicePixelRatio;
      if (height <= 0) return ContentAlign.bottom;
      final centerDy =
          box.localToGlobal(Offset.zero).dy + box.size.height / 2;
      return centerDy > height * 0.55 ? ContentAlign.top : ContentAlign.bottom;
    } catch (_) {
      return ContentAlign.bottom;
    }
  }

  /// Standard content bubble for tour files: title + body with Back / Skip /
  /// Next wired to [controller]. Back uses the localized `tourBack`;
  /// Next/Skip use the localized `onboardNext`/`onboardSkip`. On the last
  /// step Next finishes the tour (`next()` past the final target completes).
  static Widget bubble({
    required BuildContext context,
    required TutorialCoachMarkController controller,
    required String title,
    required String body,
    bool showBack = true,
    bool isLast = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final backLabel = l10n.tourBack;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    // Theme-aware bubble: elevated container tones + explicit on-colors so
    // the text stays readable in light AND dark mode alike.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBack)
                TextButton(
                  onPressed: controller.previous,
                  child: Text(backLabel),
                ),
              TextButton(
                onPressed: controller.skip,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                child: Text(l10n.onboardSkip),
              ),
              FilledButton(
                onPressed: controller.next,
                child: Text(isLast ? l10n.onboardSkip : l10n.onboardNext),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Whether tour [id] was finished or skipped before.
  static Future<bool> isDone(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_doneKey(id)) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clears every `nova.tourDone.*` flag plus the auto-start flag, so all
  /// tours (including the first-run hub auto-start) run again.
  static Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where(
        (k) => k.startsWith(_donePrefix) || k == _autoStartedKey,
      )) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  /// First-shell-entry hub auto-start. Marks `nova.tourAutoStarted` on the
  /// very first call no matter what; if the hub tour is still undone and
  /// [hubTargetsBuilder] is assigned (hub content agent wired), waits 1s for
  /// the hub to settle, then starts the "hub" tour. Safe to call before any
  /// content file exists.
  static Future<void> autoStartHubIfNeeded(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_autoStartedKey) == true) return;
      await prefs.setBool(_autoStartedKey, true);
      final builder = hubTargetsBuilder;
      if (builder == null || await isDone("hub")) return;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      await startTour(context, ref, "hub", builder);
    } catch (_) {
      // Auto-start never breaks shell entry.
    }
  }
}
