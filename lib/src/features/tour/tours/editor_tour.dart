import "package:flutter/widgets.dart";
import "package:nova/l10n/generated/app_localizations.dart";
import "package:tutorial_coach_mark/tutorial_coach_mark.dart";

import "../tour_keys.dart";
import "../tour_service.dart";

// Editor tour content: full workspace coverage in 22 steps.
//
// Order rationale (all-real-press: a tap on the highlighted widget BOTH
// performs its real action AND advances after 600ms; TourService filters
// only at tour start, so a mid-tour press that unmounts later targets
// strands the tour — bodies on dangerous steps say "tap Next to stay"):
//   1-2.  wsProjectDropdown, wsPalette — AppBar anchors.
//          Dropdown/palette open menus (dismiss with Back, or Next).
//   4-6.  explorerEntry, explorerNewFile, explorerGoUp — BEFORE the pane
//          toggle. Entry first: tapping it opens a tab, guaranteeing the
//          tab strip is populated for steps 8+. NewFile opens a name
//          dialog (Cancel to continue). GoUp only changes the directory.
//   7.    wsExplorerToggle — AFTER all explorer steps; the pane hides at
//          the end (press again to restore). Nothing later needs it.
//   8-12. wsTabStrip, wsSave, wsReload, wsAi (sheet — close to continue),
//          wsPreview (markdown-only; filtered out on code files).
//   13-19. Tool drawer, harmless tab switches first: wsRunTab (selects the
//          Run drawer so the panel is visible), wsTaskDropdown (menu —
//          dismiss or Next), wsRunButton (REALLY starts a process;
//          stoppable from the same button), wsTerminalTab, wsGitTab,
//          wsProcessesTab (pure drawer switches), then wsToolsHide which
//          collapses the drawer — the next step (definition) lives in the
//          editor area and survives it.
//   20. wsDefinition — navigates, possibly to another file; every later
//        step is AppBar/strip level and survives a file switch.
//   20. wsTabClose — AFTER every tab-content step (a clean press closes
//        the tab; dirty asks first). Body warns single-tab users to use
//        Next instead.
//   21. wsToolbarHide — collapses the AppBar into the 28px strip. The next
//        (last) step lives in the tab strip and survives it; the body tells
//        how to restore via the strip button.
//   22. wsFocus — ABSOLUTE LAST: entering focus mode unmounts the normal
//        chrome (AppBar, strip, drawer), so nothing may follow it.
//
// Deliberately NOT stepped: paletteField (targets a dialog that opens above
// the overlay — unreachable Next), selection-toolbar items (long-press menu,
// no stable anchor), wsToolbarShow (appears only mid-tour; the hide-step
// body explains the restore button instead).
List<TargetFocus> buildEditorTargets(AppLocalizations l10n) {
  TargetFocus step({
    required GlobalKey keyTarget,
    required String title,
    required String body,
    bool showBack = true,
    bool isLast = false,
    // live:false blocks taps on the target (explain-only) for steps whose
    // real press would strand the tour (dialogs over the overlay, ...).
    bool live = true,
  }) {
    return TargetFocus(
      identify: title,
      keyTarget: keyTarget,
      enableTargetTab: live,
      contents: [
        TargetContent(
          // Auto side: low targets get the bubble above them so Next never
          // runs off-screen (see TourService.contentAlignFor).
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
      keyTarget: TourKeys.wsProjectDropdown,
      title: l10n.tourEdProjectTitle,
      body: l10n.tourEdProjectBody,
      showBack: false,
    ),
    step(
      keyTarget: TourKeys.wsPalette,
      title: l10n.tourEdPaletteTitle,
      body: l10n.tourEdPaletteBody,
    ),
    step(
      keyTarget: TourKeys.explorerEntry,
      title: l10n.tourEdEntryTitle,
      body: l10n.tourEdEntryBody,
    ),
    step(
      keyTarget: TourKeys.explorerNewFile,
      title: l10n.tourEdNewFileTitle,
      body: l10n.tourEdNewFileBody,
    ),
    step(
      keyTarget: TourKeys.explorerGoUp,
      title: l10n.tourEdGoUpTitle,
      body: l10n.tourEdGoUpBody,
    ),
    step(
      keyTarget: TourKeys.wsExplorerToggle,
      title: l10n.tourEdExplorerTitle,
      body: l10n.tourEdExplorerBody,
    ),
    step(
      keyTarget: TourKeys.wsTabStrip,
      title: l10n.tourEdTabsTitle,
      body: l10n.tourEdTabsBody,
    ),
    step(
      keyTarget: TourKeys.wsSave,
      title: l10n.tourEdSaveTitle,
      body: l10n.tourEdSaveBody,
    ),
    step(
      keyTarget: TourKeys.wsReload,
      title: l10n.tourEdReloadTitle,
      body: l10n.tourEdReloadBody,
    ),
    step(
      keyTarget: TourKeys.wsAi,
      title: l10n.tourEdAiTitle,
      body: l10n.tourEdAiBody,
    ),
    step(
      keyTarget: TourKeys.wsPreview,
      title: l10n.tourEdPreviewTitle,
      body: l10n.tourEdPreviewBody,
    ),
    step(
      keyTarget: TourKeys.wsRunTab,
      title: l10n.tourEdRunTabTitle,
      body: l10n.tourEdRunTabBody,
    ),
    step(
      keyTarget: TourKeys.wsTaskDropdown,
      title: l10n.tourEdTaskTitle,
      body: l10n.tourEdTaskBody,
    ),
    step(
      keyTarget: TourKeys.wsRunButton,
      title: l10n.tourEdRunTitle,
      body: l10n.tourEdRunBody,
    ),
    step(
      keyTarget: TourKeys.wsTerminalTab,
      title: l10n.tourEdTermTabTitle,
      body: l10n.tourEdTermTabBody,
    ),
    step(
      keyTarget: TourKeys.wsGitTab,
      title: l10n.tourEdGitTabTitle,
      body: l10n.tourEdGitTabBody,
    ),
    step(
      keyTarget: TourKeys.wsProcessesTab,
      title: l10n.tourEdProcTabTitle,
      body: l10n.tourEdProcTabBody,
    ),
    step(
      keyTarget: TourKeys.wsToolsHide,
      title: l10n.tourEdToolsTitle,
      body: l10n.tourEdToolsBody,
    ),
    step(
      keyTarget: TourKeys.wsDefinition,
      title: l10n.tourEdDefTitle,
      body: l10n.tourEdDefBody,
    ),
    step(
      keyTarget: TourKeys.wsTabClose,
      title: l10n.tourEdTabCloseTitle,
      body: l10n.tourEdTabCloseBody,
    ),
    step(
      keyTarget: TourKeys.wsToolbarHide,
      title: l10n.tourEdToolbarTitle,
      body: l10n.tourEdToolbarBody,
    ),
    step(
      keyTarget: TourKeys.wsFocus,
      title: l10n.tourEdFocusTitle,
      body: l10n.tourEdFocusBody,
      isLast: true,
    ),
  ];
}
