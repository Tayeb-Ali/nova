import "package:flutter/widgets.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:tutorial_coach_mark/tutorial_coach_mark.dart";

import "../tour_keys.dart";
import "../tour_service.dart";

// Hub tour content: 7 steps in exact screen order (top to bottom).
//
// Order rationale — mirrors the visual layout: action tiles first (New,
// Open, Refresh), then search, then the project cards, then recent files,
// ending with the navigation note:
//   1. hubNewProject (live) — opens the create dialog; body says Cancel/Next.
//   2. hubOpenEditor (EXPLAIN-ONLY) — a real press would jump to the editor
//      tab, unmounting every later target and stranding the tour, so taps
//      are blocked and the body invites trying it after the tour.
//   3. hubRefresh (live) — reloads the list; purely a refresh, always safe.
//   4. hubSearch (live) — typing only filters; harmless.
//   5. hubProjectCard (live) — selects the project; required so the editor
//      (step 2) is meaningful. First card only.
//   6. hubRecentFile (EXPLAIN-ONLY) — same stranding hazard as step 2:
//      opening a file leaves the hub, so taps are blocked.
//   7. Shell-nav note (isLast) — the bottom nav bar is HIDDEN while touring
//      (tourActiveProvider), so no shellNav* key may be targeted. The note
//      reuses the hubOpenEditor tile as its anchor and names the
//      destinations in text.
//
// Targets unmounted at tour start are filtered by TourService.startTour.
List<TargetFocus> buildHubTargets(AppLocalizations l10n) {
  TargetFocus step({
    required GlobalKey keyTarget,
    required String title,
    required String body,
    bool showBack = true,
    bool isLast = false,
    // live:false blocks taps (explain-only) for steps whose real press
    // would navigate away and strand the tour.
    bool live = true,
  }) {
    return TargetFocus(
      identify: title,
      keyTarget: keyTarget,
      enableTargetTab: live,
      contents: [
        TargetContent(
          // Auto side so low targets (e.g. recent files at the bottom)
          // keep their Next button on-screen (see contentAlignFor).
          align: TourService.contentAlignFor(keyTarget),
          builder: (context, controller) => TourService.bubble(
            context: context,
            controller: controller,
            title: title,
            body: body,
            showBack: showBack,
            isLast: isLast,
          ),
        ),
      ],
    );
  }

  return [
    step(
      keyTarget: TourKeys.hubNewProject,
      title: l10n.tourHubNewTitle,
      body: l10n.tourHubNewBody,
      showBack: false,
    ),
    step(
      keyTarget: TourKeys.hubOpenEditor,
      title: l10n.tourHubOpenTitle,
      body: l10n.tourHubOpenBody,
      live: false,
    ),
    step(
      keyTarget: TourKeys.hubRefresh,
      title: l10n.tourHubRefreshTitle,
      body: l10n.tourHubRefreshBody,
    ),
    step(
      keyTarget: TourKeys.hubSearch,
      title: l10n.tourHubSearchTitle,
      body: l10n.tourHubSearchBody,
    ),
    step(
      keyTarget: TourKeys.hubProjectCard,
      title: l10n.tourHubCardTitle,
      body: l10n.tourHubCardBody,
    ),
    step(
      keyTarget: TourKeys.hubRecentFile,
      title: l10n.tourHubRecentTitle,
      body: l10n.tourHubRecentBody,
      live: false,
    ),
    step(
      keyTarget: TourKeys.hubOpenEditor,
      title: l10n.tourHubNavTitle,
      body: l10n.tourHubNavBody,
      isLast: true,
    ),
  ];
}

/// Wires the hub builder into [TourService] for the first-run auto-start.
/// The integration agent calls this once at startup (see register_tours.dart).
void registerHubTour() {
  TourService.hubTargetsBuilder = buildHubTargets;
}
