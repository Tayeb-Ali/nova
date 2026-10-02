import "package:flutter/widgets.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:tutorial_coach_mark/tutorial_coach_mark.dart";

import "../tour_keys.dart";
import "../tour_service.dart";

// Secondary tour target builders (all-real-press: every TargetFocus sets
// `enableTargetTab: true`, overlay taps never advance — see [TourService]).
//
// Defensively ordered: harmless reads/filters first, anything that starts
// real work last with a warning in its body. Bubble side is automatic per
// target (see TourService.contentAlignFor) so low targets keep Next visible.
TargetFocus _step({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String body,
  bool showBack = true,
  bool isLast = false,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    enableTargetTab: true,
    contents: [
      TargetContent(
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

/// Runtime: search (filter only) → setup (real download) → install LAST
/// (real download + install, body warns).
List<TargetFocus> buildRuntimeTargets(AppLocalizations l10n) {
  return [
    _step(
      identify: "rtSearch",
      keyTarget: TourKeys.rtSearch,
      title: l10n.tourRtSearchTitle,
      body: l10n.tourRtSearchBody,
      showBack: false,
    ),
    _step(
      identify: "rtStartSetup",
      keyTarget: TourKeys.rtStartSetup,
      title: l10n.tourRtSetupTitle,
      body: l10n.tourRtSetupBody,
    ),
    _step(
      identify: "rtInstallFirst",
      keyTarget: TourKeys.rtInstallFirst,
      title: l10n.tourRtInstallTitle,
      body: l10n.tourRtInstallBody,
      isLast: true,
    ),
  ];
}

/// Terminal: paste → Tab → Ctrl+C → new tab LAST (adds a real tab,
/// harmless; Ctrl+C sits before it so the tab-strip change closes the tour).
List<TargetFocus> buildTerminalTargets(AppLocalizations l10n) {
  return [
    _step(
      identify: "termPaste",
      keyTarget: TourKeys.termPaste,
      title: l10n.tourTermPasteTitle,
      body: l10n.tourTermPasteBody,
      showBack: false,
    ),
    _step(
      identify: "termTabKey",
      keyTarget: TourKeys.termTabKey,
      title: l10n.tourTermTabTitle,
      body: l10n.tourTermTabBody,
    ),
    _step(
      identify: "termCtrlC",
      keyTarget: TourKeys.termCtrlC,
      title: l10n.tourTermCtrlCTitle,
      body: l10n.tourTermCtrlCBody,
    ),
    _step(
      identify: "termNewTab",
      keyTarget: TourKeys.termNewTab,
      title: l10n.tourTermNewTabTitle,
      body: l10n.tourTermNewTabBody,
      isLast: true,
    ),
  ];
}

/// Settings: account → language → AI key → save LAST (real persist,
/// harmless, body says so).
List<TargetFocus> buildSettingsTargets(AppLocalizations l10n) {
  return [
    _step(
      identify: "settingsAccount",
      keyTarget: TourKeys.settingsAccount,
      title: l10n.tourSetAccountTitle,
      body: l10n.tourSetAccountBody,
      showBack: false,
    ),
    _step(
      identify: "settingsLanguage",
      keyTarget: TourKeys.settingsLanguage,
      title: l10n.tourSetLangTitle,
      body: l10n.tourSetLangBody,
    ),
    _step(
      identify: "settingsAiKey",
      keyTarget: TourKeys.settingsAiKey,
      title: l10n.tourSetAiKeyTitle,
      body: l10n.tourSetAiKeyBody,
    ),
    _step(
      identify: "settingsAiSave",
      keyTarget: TourKeys.settingsAiSave,
      title: l10n.tourSetSaveTitle,
      body: l10n.tourSetSaveBody,
      isLast: true,
    ),
  ];
}

/// Git: status (real reload, harmless) → commit LAST (opens the message
/// prompt; the user can cancel, body says so).
List<TargetFocus> buildGitTargets(AppLocalizations l10n) {
  return [
    _step(
      identify: "gitStatusBtn",
      keyTarget: TourKeys.gitStatusBtn,
      title: l10n.tourGitStatusTitle,
      body: l10n.tourGitStatusBody,
      showBack: false,
    ),
    _step(
      identify: "gitCommitBtn",
      keyTarget: TourKeys.gitCommitBtn,
      title: l10n.tourGitCommitTitle,
      body: l10n.tourGitCommitBody,
      isLast: true,
    ),
  ];
}

/// Notifications: single step — mark-all-read (real but harmless; entries
/// stay, only unread dots clear). The floating bell is hidden while a tour
/// is active, so the in-screen AppBar action is the only target.
List<TargetFocus> buildNotifTargets(AppLocalizations l10n) {
  return [
    _step(
      identify: "notifMarkRead",
      keyTarget: TourKeys.notifMarkRead,
      title: l10n.tourNotifMarkReadTitle,
      body: l10n.tourNotifMarkReadBody,
      showBack: false,
      isLast: true,
    ),
  ];
}
