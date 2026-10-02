import "package:flutter/widgets.dart";

// Stable [GlobalKey]s for the coach-mark tour infrastructure.
//
// Content agents attach these keys to widgets (e.g. `key: TourKeys.hubSearch`)
// and reference the SAME key in their `TargetFocus(keyTarget: ...)` builders.
// Keys are created once here so the tour targets and the widgets never drift.
//
// [all] backs the uniqueness test: every entry must be a distinct key
// instance under a distinct name.
abstract final class TourKeys {
  static final GlobalKey hubSearch = GlobalKey();
  static final GlobalKey hubNewProject = GlobalKey();
  static final GlobalKey hubOpenEditor = GlobalKey();
  static final GlobalKey hubRefresh = GlobalKey();
  static final GlobalKey hubProjectCard = GlobalKey();
  static final GlobalKey hubRecentFile = GlobalKey();
  static final GlobalKey shellNavProjects = GlobalKey();
  static final GlobalKey shellNavEditor = GlobalKey();
  static final GlobalKey shellNavRuntime = GlobalKey();
  static final GlobalKey shellNavSettings = GlobalKey();
  static final GlobalKey shellBell = GlobalKey();
  static final GlobalKey wsProjectDropdown = GlobalKey();
  static final GlobalKey wsToolbarHide = GlobalKey();
  static final GlobalKey wsToolbarShow = GlobalKey();
  static final GlobalKey wsPalette = GlobalKey();
  static final GlobalKey wsExplorerToggle = GlobalKey();
  static final GlobalKey wsTabStrip = GlobalKey();
  static final GlobalKey wsTabClose = GlobalKey();
  static final GlobalKey wsSave = GlobalKey();
  static final GlobalKey wsReload = GlobalKey();
  static final GlobalKey wsAi = GlobalKey();
  static final GlobalKey wsDefinition = GlobalKey();
  static final GlobalKey wsPreview = GlobalKey();
  static final GlobalKey wsFocus = GlobalKey();
  static final GlobalKey wsRunTab = GlobalKey();
  static final GlobalKey wsTerminalTab = GlobalKey();
  static final GlobalKey wsGitTab = GlobalKey();
  static final GlobalKey wsProcessesTab = GlobalKey();
  static final GlobalKey wsToolsHide = GlobalKey();
  static final GlobalKey wsRunButton = GlobalKey();
  static final GlobalKey wsTaskDropdown = GlobalKey();
  static final GlobalKey explorerNewFile = GlobalKey();
  static final GlobalKey explorerGoUp = GlobalKey();
  static final GlobalKey explorerEntry = GlobalKey();
  static final GlobalKey paletteField = GlobalKey();
  static final GlobalKey rtStartSetup = GlobalKey();
  static final GlobalKey rtInstallFirst = GlobalKey();
  static final GlobalKey rtSearch = GlobalKey();
  static final GlobalKey termNewTab = GlobalKey();
  static final GlobalKey termPaste = GlobalKey();
  static final GlobalKey termTabKey = GlobalKey();
  static final GlobalKey termCtrlC = GlobalKey();
  static final GlobalKey procCommandField = GlobalKey();
  static final GlobalKey procRun = GlobalKey();
  static final GlobalKey searchField = GlobalKey();
  static final GlobalKey searchButton = GlobalKey();
  static final GlobalKey settingsAccount = GlobalKey();
  static final GlobalKey settingsLanguage = GlobalKey();
  static final GlobalKey settingsAiKey = GlobalKey();
  static final GlobalKey settingsAiSave = GlobalKey();
  static final GlobalKey gitStatusBtn = GlobalKey();
  static final GlobalKey gitCommitBtn = GlobalKey();
  static final GlobalKey notifBell = GlobalKey();
  static final GlobalKey notifMarkRead = GlobalKey();

  /// (name, key) records for every tour key; used by the uniqueness test.
  static final List<(String, GlobalKey)> all = [
    ("hubSearch", hubSearch),
    ("hubNewProject", hubNewProject),
    ("hubOpenEditor", hubOpenEditor),
    ("hubRefresh", hubRefresh),
    ("hubProjectCard", hubProjectCard),
    ("hubRecentFile", hubRecentFile),
    ("shellNavProjects", shellNavProjects),
    ("shellNavEditor", shellNavEditor),
    ("shellNavRuntime", shellNavRuntime),
    ("shellNavSettings", shellNavSettings),
    ("shellBell", shellBell),
    ("wsProjectDropdown", wsProjectDropdown),
    ("wsToolbarHide", wsToolbarHide),
    ("wsToolbarShow", wsToolbarShow),
    ("wsPalette", wsPalette),
    ("wsExplorerToggle", wsExplorerToggle),
    ("wsTabStrip", wsTabStrip),
    ("wsTabClose", wsTabClose),
    ("wsSave", wsSave),
    ("wsReload", wsReload),
    ("wsAi", wsAi),
    ("wsDefinition", wsDefinition),
    ("wsPreview", wsPreview),
    ("wsFocus", wsFocus),
    ("wsRunTab", wsRunTab),
    ("wsTerminalTab", wsTerminalTab),
    ("wsGitTab", wsGitTab),
    ("wsProcessesTab", wsProcessesTab),
    ("wsToolsHide", wsToolsHide),
    ("wsRunButton", wsRunButton),
    ("wsTaskDropdown", wsTaskDropdown),
    ("explorerNewFile", explorerNewFile),
    ("explorerGoUp", explorerGoUp),
    ("explorerEntry", explorerEntry),
    ("paletteField", paletteField),
    ("rtStartSetup", rtStartSetup),
    ("rtInstallFirst", rtInstallFirst),
    ("rtSearch", rtSearch),
    ("termNewTab", termNewTab),
    ("termPaste", termPaste),
    ("termTabKey", termTabKey),
    ("termCtrlC", termCtrlC),
    ("procCommandField", procCommandField),
    ("procRun", procRun),
    ("searchField", searchField),
    ("searchButton", searchButton),
    ("settingsAccount", settingsAccount),
    ("settingsLanguage", settingsLanguage),
    ("settingsAiKey", settingsAiKey),
    ("settingsAiSave", settingsAiSave),
    ("gitStatusBtn", gitStatusBtn),
    ("gitCommitBtn", gitCommitBtn),
    ("notifBell", notifBell),
    ("notifMarkRead", notifMarkRead),
  ];
}
