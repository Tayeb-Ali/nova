// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchEmpty => 'No matches';

  @override
  String get searchPrompt => 'Search the active project above';

  @override
  String get commandPaletteEmpty => 'No matches';

  @override
  String get navProjects => 'Projects';

  @override
  String get navEditor => 'Editor';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionImport => 'Import';

  @override
  String get actionExport => 'Export';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionShare => 'Share';

  @override
  String get projectsWorkspaceStats => 'Workspace stats';

  @override
  String get projectsOpenFolder => 'Open folder';

  @override
  String get projectsOpenFile => 'Open file';

  @override
  String get projectsCloneGit => 'Clone git repo';

  @override
  String get projectsNewProject => 'New project';

  @override
  String get projectsRecentProjects => 'Recent projects';

  @override
  String get projectsRecentFiles => 'Recent files';

  @override
  String get projectsTipsTitle => 'Tips';

  @override
  String get projectsTipOrganize =>
      'Keep one folder per project to switch faster.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsEditor => 'Editor';

  @override
  String settingsFontSize(String size) {
    return 'Font size: $size';
  }

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsTimeout => 'Timeout';

  @override
  String get themeNovaDark => 'Nova dark';

  @override
  String get themeNovaLight => 'Nova light';

  @override
  String get actionRun => 'Run';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionInstall => 'Install';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionUninstall => 'Uninstall';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String commonCreateFailed(String error) {
    return 'Create failed: $error';
  }

  @override
  String commonDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String commonRenameFailed(String error) {
    return 'Rename failed: $error';
  }

  @override
  String get projectsProjectNameHint => 'Project name';

  @override
  String get projectsDeleteTitle => 'Delete project?';

  @override
  String projectsDeleteMessage(String name) {
    return 'Delete \'$name\' and all its files?';
  }

  @override
  String get projectsSearchHint => 'Search projects...';

  @override
  String get projectsStatusUnavailable => 'Runtime status unavailable';

  @override
  String get projectsSetupNeeded => 'Runtime setup needed';

  @override
  String get projectsRuntimeReady => 'Runtime ready';

  @override
  String get projectsOpenEditor => 'Open editor';

  @override
  String get projectsDeleteProject => 'Delete project';

  @override
  String get projectsEmptyTitle => 'No projects yet';

  @override
  String get projectsTipsBody =>
      'Tap a project to open it in the editor. Use the Packages tab to install runtimes before creating Node or Python projects.';

  @override
  String get editorEmptyHint => 'Open a file from the explorer';

  @override
  String editorSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String editorSaved(String name) {
    return 'Saved $name';
  }

  @override
  String editorOpenFailed(String error) {
    return 'Could not open file: $error';
  }

  @override
  String get explorerNewFile => 'New file';

  @override
  String get explorerNewNameHint => 'New name';

  @override
  String get explorerDeleteTitle => 'Delete?';

  @override
  String explorerDeleteMessage(String name) {
    return 'Delete $name?';
  }

  @override
  String get explorerSelectProject => 'Select a project';

  @override
  String get explorerEmptyFolder => 'Empty folder';

  @override
  String runStartFailed(String error) {
    return 'Failed to start task: $error';
  }

  @override
  String get runNoTasks => 'No tasks detected';

  @override
  String get runHideConsole => 'Hide console';

  @override
  String get runShowConsole => 'Show console';

  @override
  String get runEmptyHint =>
      'Press Run to execute the selected task. Output appears here.';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitCommitMessage => 'Commit message';

  @override
  String get gitCommitted => 'Committed';

  @override
  String gitCommitFailed(String error) {
    return 'Commit failed: $error';
  }

  @override
  String get gitStageAll => 'Stage all';

  @override
  String get gitStagedAll => 'Staged all changes';

  @override
  String gitStageFailed(String error) {
    return 'Stage failed: $error';
  }

  @override
  String get gitStage => 'Stage';

  @override
  String gitStagedFile(String file) {
    return 'Staged $file';
  }

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitCheckout => 'Checkout';

  @override
  String get gitCreateBranch => 'New branch';

  @override
  String get gitBranchNameHint => 'Branch name';

  @override
  String gitDeleteBranchConfirm(String name) {
    return 'Delete branch \'$name\'?';
  }

  @override
  String gitBranchActionFailed(String error) {
    return 'Branch action failed: $error';
  }

  @override
  String get gitNoBranches => '(no branches)';

  @override
  String get gitStash => 'Stash';

  @override
  String get gitStashSave => 'Stash changes';

  @override
  String get gitStashMessage => 'Stash message';

  @override
  String get gitStashed => 'Stashed changes';

  @override
  String gitStashActionFailed(String error) {
    return 'Stash action failed: $error';
  }

  @override
  String get gitStashEmpty => '(no stashed changes)';

  @override
  String get gitStashPop => 'Pop';

  @override
  String get gitStashDrop => 'Drop';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalNewSession => 'New session';

  @override
  String get terminalStartFailed => 'Failed to start terminal session';

  @override
  String get processTitle => 'Processes';

  @override
  String get processRunHint => 'Run command… e.g. npm run dev';

  @override
  String get processEmpty =>
      'No running processes.\nStart a task to see it here.';

  @override
  String get runtimeTitle => 'Runtime';

  @override
  String get runtimeBootstrap => 'Bootstrap';

  @override
  String get runtimeStartSetup => 'Start setup';

  @override
  String get runtimeInstalled => 'Installed';

  @override
  String get runtimeAvailable => 'Available';

  @override
  String runtimeUninstallConfirm(String name) {
    return 'Uninstall $name?';
  }

  @override
  String get runtimeEmpty => 'No runtimes available.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeFollowSystem => 'Follow system';

  @override
  String get toolsShow => 'Show tools';

  @override
  String get toolsHide => 'Hide tools';

  @override
  String get toolbarShow => 'Show toolbar';

  @override
  String get toolbarHide => 'Hide toolbar';

  @override
  String get explorerShow => 'Show explorer';

  @override
  String get explorerHide => 'Hide explorer';

  @override
  String get projectNew => 'New project';

  @override
  String get projectNameHint => 'Project name';

  @override
  String get projectDelete => 'Delete project';

  @override
  String get projectDeleteTitle => 'Delete project?';

  @override
  String projectDeleteBody(String name) {
    return 'Delete \'$name\' and all its files?';
  }

  @override
  String get workspaceEmpty => 'No projects yet';

  @override
  String get workspaceTitle => 'Workspace';

  @override
  String get toolTerminal => 'Terminal';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => 'Processes';

  @override
  String get projectSelect => 'Select project';

  @override
  String get projectsHintTemplate => 'Start from a template';

  @override
  String get projectsHintContinue => 'Continue working';

  @override
  String get projectsHintReload => 'Reload project list';

  @override
  String get projectsHintRemoveActive => 'Remove active project';

  @override
  String projectsFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String projectsCount(int count) {
    return '$count projects';
  }

  @override
  String get editorEdit => 'Edit';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorTabActions => 'Tab actions';

  @override
  String get editorReloadConfirmTitle => 'Reload file?';

  @override
  String get editorReloadConfirmBody =>
      'Discard unsaved changes and reload from disk?';

  @override
  String editorReloaded(String name) {
    return 'Reloaded $name';
  }

  @override
  String get editorRecoverTitle => 'Unsaved changes found';

  @override
  String editorRecoverBody(String name) {
    return 'Restore unsaved changes for $name?';
  }

  @override
  String get editorCloseDirtyTitle => 'Close without saving?';

  @override
  String editorCloseDirtyBody(String name) {
    return 'Discard unsaved changes to $name?';
  }

  @override
  String get editorFocusEnter => 'Focus mode';

  @override
  String get editorFocusExit => 'Exit focus mode';

  @override
  String get explorerTitle => 'EXPLORER';

  @override
  String get explorerGoUp => 'Go up';

  @override
  String get runClearOutput => 'Clear output';

  @override
  String get runStartingProcess => 'Starting process…';

  @override
  String get gitProject => 'Project';

  @override
  String get gitOpenProject => 'Open project';

  @override
  String get gitSelectProject => 'Select project';

  @override
  String get gitProjectPath => 'Project path';

  @override
  String get gitStatus => 'Status';

  @override
  String get gitDiff => 'Diff';

  @override
  String get gitUnavailable => 'Git unavailable';

  @override
  String gitBranch(String branch) {
    return 'Branch: $branch';
  }

  @override
  String get gitModified => 'Modified';

  @override
  String get gitAdded => 'Added';

  @override
  String get gitDeleted => 'Deleted';

  @override
  String get gitUntracked => 'Untracked';

  @override
  String get gitEmptyDiff => '(empty diff)';

  @override
  String get terminalPaste => 'Paste';

  @override
  String terminalSessionExited(int code) {
    return 'Session exited (code $code)';
  }

  @override
  String get terminalKeyTab => 'Tab';

  @override
  String get terminalKeyEsc => 'Esc';

  @override
  String get terminalKeyUp => 'Up';

  @override
  String get terminalKeyDown => 'Down';

  @override
  String get terminalKeyLeft => 'Left';

  @override
  String get terminalKeyRight => 'Right';

  @override
  String processStarted(String pid, String command) {
    return 'Started $pid · $command';
  }

  @override
  String get processStartedByNova => 'Started by Nova';

  @override
  String get runtimeReady => 'Ready';

  @override
  String get runtimeBootstrapReady =>
      'Bootstrap is ready. Runtimes can be installed below.';

  @override
  String get bootstrapRequired => 'Runtime required';

  @override
  String get bootstrapRequiredBody =>
      'The Linux runtime is not installed. Download it now to use the terminal and language runtimes?';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionLater => 'Later';

  @override
  String get runtimeBootstrapUnavailable => 'Bootstrap state unavailable.';

  @override
  String get runtimeBootstrapNotInstalled => 'Bootstrap is not installed yet.';

  @override
  String runtimeVersion(String version) {
    return 'Version: $version';
  }

  @override
  String get runtimeSetupFailed => 'Setup failed';

  @override
  String get aiTitle => 'AI actions';

  @override
  String get aiKeySaved => 'Key saved';

  @override
  String get aiEnterKeyFirst => 'Enter an API key first';

  @override
  String get aiNoCode => 'No code selected';

  @override
  String get aiExplainCode => 'Explain code';

  @override
  String get aiFixError => 'Fix error';

  @override
  String get aiCompleteCode => 'Complete code';

  @override
  String aiPromptExplain(String code) {
    return 'Explain the following code:\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return 'Fix the error in the following code:\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return 'Complete the following code:\n$code';
  }

  @override
  String get settingsSystem => 'System';

  @override
  String settingsRunTimeout(int ms) {
    return 'Run timeout: $ms ms';
  }

  @override
  String get settingsTimeoutLabel => 'Timeout (ms, 1000-120000)';

  @override
  String get settingsAutocomplete => 'Autocomplete';

  @override
  String get settingsAutocompleteSub =>
      'Keyword, snippet and word suggestions while typing';

  @override
  String get settingsMatchTheme => 'Match app to editor theme';

  @override
  String get settingsMatchThemeSub =>
      'Whole app follows the editor theme colors';

  @override
  String get settingsWordWrap => 'Word wrap';

  @override
  String get settingsWordWrapSub =>
      'Wrap long lines instead of scrolling sideways';

  @override
  String get settingsAutoSave => 'Auto save';

  @override
  String get settingsAutoSaveSub => 'Save 1.5s after you stop typing';

  @override
  String get settingsEditorFont => 'Editor font';

  @override
  String get settingsFontInstalled => 'Font installed';

  @override
  String get settingsFontUpdated => 'Editor font updated';

  @override
  String get settingsDownloadFailed => 'Download failed: check connection';

  @override
  String get settingsLivePreview => 'Live preview';

  @override
  String get settingsProvider => 'Provider';

  @override
  String get settingsCustomProvider => 'Custom (OpenAI compatible)';

  @override
  String get settingsBaseUrl => 'Base URL (OpenAI compatible)';

  @override
  String get settingsModel => 'Model';

  @override
  String get settingsApiKey => 'API key';

  @override
  String get settingsApiKeySaved => 'Saved in secure storage';

  @override
  String get settingsApiKeyHint => 'Paste your key';

  @override
  String get settingsKeySecureNote =>
      'The key is stored in encrypted secure storage, never in plain settings.';

  @override
  String get settingsTestConnection => 'Test connection';

  @override
  String get settingsTesting => 'Testing…';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String settingsConnected(String reply) {
    return 'Connected: $reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String settingsThemeImported(String name) {
    return 'Theme \"$name\" imported';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String settingsThemeCopied(String name) {
    return 'Theme \"$name\" JSON copied';
  }

  @override
  String settingsThemeExported(String name) {
    return 'Theme \"$name\" exported to clipboard';
  }

  @override
  String get settingsImportTheme => 'Import theme JSON';

  @override
  String get settingsCopyTheme => 'Copy theme JSON';

  @override
  String get settingsExportTheme => 'Export theme';

  @override
  String get settingsDeleteTheme => 'Delete theme';

  @override
  String get searchTitle => 'Search in project';

  @override
  String get searchHint => 'Search text or pattern…';

  @override
  String get searchReplaceHint => 'Replace with…';

  @override
  String get searchMatchCase => 'Match case';

  @override
  String get searchUseRegex => 'Use regular expression';

  @override
  String get searchButton => 'Search';

  @override
  String searchButtonCount(int hits) {
    return 'Search ($hits)';
  }

  @override
  String get searchReplaceAll => 'Replace all';

  @override
  String get searchNoProject => 'No project open';

  @override
  String get searchTypeSomething => 'Type something to search for';

  @override
  String get searchInvalidRegex => 'Invalid regular expression';

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get searchEmptyHint => 'Search the active project above';

  @override
  String get searchNoMatches => 'No matches';

  @override
  String get searchTruncated =>
      'Showing the first matches only (limits reached)';

  @override
  String searchReplaceCount(int count) {
    return 'Replace ($count)';
  }

  @override
  String get searchUnsavedTitle => 'Unsaved changes';

  @override
  String searchUnsavedBody(String names) {
    return 'These open tabs have unsaved edits that replace would overwrite: $names. Replace anyway?';
  }

  @override
  String get searchReplaceAnyway => 'Replace anyway';

  @override
  String get searchNoMatchesReplace => 'No matches to replace';

  @override
  String searchReplaced(int total, int files) {
    return 'Replaced $total in $files files. Reopen affected tabs to reload.';
  }

  @override
  String searchReplaceFailed(String error) {
    return 'Replace failed: $error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return 'No matches in $name';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return 'Replaced $count in $name. Reopen the tab to reload.';
  }

  @override
  String get editorFindInFile => 'Find in file';

  @override
  String get editorFindHint => 'Find';

  @override
  String get editorPrevMatch => 'Previous match';

  @override
  String get editorNextMatch => 'Next match';

  @override
  String get editorMatchCase => 'Match case';

  @override
  String get editorUseRegex => 'Use regular expression';

  @override
  String get editorCloseFind => 'Close find bar';

  @override
  String explorerStorageError(String error) {
    return 'Storage not writable here: $error';
  }

  @override
  String get explorerNewFileHint => 'e.g. main.py';

  @override
  String get explorerNoFolder => 'No folder selected';

  @override
  String get mdUndo => 'Undo';

  @override
  String get mdRedo => 'Redo';

  @override
  String get mdBold => 'Bold';

  @override
  String get mdItalic => 'Italic';

  @override
  String get mdUnderline => 'Underline';

  @override
  String get mdStrike => 'Strikethrough';

  @override
  String get mdInlineCode => 'Inline code';

  @override
  String get mdH1 => 'Heading 1';

  @override
  String get mdH2 => 'Heading 2';

  @override
  String get mdH3 => 'Heading 3';

  @override
  String get mdBulleted => 'Bulleted list';

  @override
  String get mdNumbered => 'Numbered list';

  @override
  String get mdQuote => 'Quote';

  @override
  String get mdCodeBlock => 'Code block';

  @override
  String get terminalMaxTabs => 'Maximum of 5 terminal tabs reached';

  @override
  String get paletteHint => 'Type a command or file name…';

  @override
  String get paletteNoMatches => 'No matches';

  @override
  String get paletteToggleRun => 'Toggle Run panel';

  @override
  String get paletteToggleTerminal => 'Toggle Terminal';

  @override
  String get paletteToggleGit => 'Toggle Git panel';

  @override
  String get paletteToggleProcesses => 'Toggle Processes panel';

  @override
  String get paletteSwitchTheme => 'Switch editor theme';

  @override
  String get paletteSearchInProject => 'Search in project';

  @override
  String get paletteOpenSettings => 'Open settings';

  @override
  String get paletteTitle => 'Command palette';

  @override
  String get projectGeneral => 'General';

  @override
  String get projectGeneralSub => 'No runtime assumed — language auto-detected';

  @override
  String runtimeInstalledOk(String name) {
    return 'Installed $name successfully';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return 'Failed to install $name: $error';
  }

  @override
  String runtimeStartInstall(String name) {
    return 'Starting install of $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return 'Failed to start install: $error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return 'Starting update of $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return 'Failed to start update: $error';
  }

  @override
  String runtimeRemoving(String name) {
    return 'Removing $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return 'Removal failed: $error';
  }

  @override
  String get runtimeChooseVariant =>
      'Choose a Linux system image (downloaded once from the internet):';

  @override
  String get runtimeVariantSlim => 'Slim ~70MB (recommended)';

  @override
  String get runtimeVariantSlimSub =>
      'Core + apt — languages install on demand';

  @override
  String get runtimeVariantFull => 'Full ~283MB';

  @override
  String get runtimeVariantFullSub =>
      'Node, Python, PHP and Git preinstalled — works offline';

  @override
  String get runtimeNoResults => 'No matching results';

  @override
  String get runtimeSearchHint => 'Search for a language or tool…';

  @override
  String get runtimeClear => 'Clear';

  @override
  String get runtimeUnsupported => 'Not supported on this device';

  @override
  String runtimeInstalledSection(int count) {
    return 'Installed ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return 'Ready packs ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return 'Languages ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return 'Tools ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return 'Running: $name';
  }

  @override
  String runtimeLastOp(String name) {
    return 'Last operation: $name';
  }

  @override
  String get runtimeLogTitle => 'Operation log';

  @override
  String runtimeLines(int count) {
    return '$count lines';
  }

  @override
  String get runtimeDone => 'Done';

  @override
  String get runtimeStatusUpdating => 'Updating package lists…';

  @override
  String get runtimeStatusInstalling => 'Starting install…';

  @override
  String get runtimeStatusReading => 'Reading package lists…';

  @override
  String get runtimeStatusDeps => 'Building dependency tree…';

  @override
  String get runtimeStatusUnpacking => 'Unpacking packages…';

  @override
  String get runtimeStatusSettingUp => 'Setting up packages…';

  @override
  String runtimeWorkingOn(String name) {
    return 'Working on $name…';
  }

  @override
  String get setupSlimTitle => 'Slim ~80MB (default)';

  @override
  String get setupSlimSub => 'Core + apt — languages install on demand';

  @override
  String get setupFullTitle => 'Full ~283MB (offline)';

  @override
  String get setupFullSub => 'Node, Python, PHP and Git preinstalled';

  @override
  String get setupResumeNote => 'Retry reuses the verified download (resume).';

  @override
  String get webPreviewTitle => 'Web Preview';

  @override
  String get runtimeDescPhp => 'Web language — Laravel and WordPress';

  @override
  String get runtimeDescNode => 'JavaScript and TypeScript — npm included';

  @override
  String get runtimeDescPython => 'Scripts and data — pip included';

  @override
  String get runtimeDescGo => 'Compiled Go — fast and light';

  @override
  String get runtimeDescRust => 'Rust — memory safety and performance';

  @override
  String get runtimeDescRuby => 'Ruby for scripts and web';

  @override
  String get runtimeDescJava => 'Java 25 — full JVM platform';

  @override
  String get runtimeDescKotlin => 'Kotlin — runs on JVM (needs Java)';

  @override
  String get runtimeDescDart => 'Dart — apps and CLI tools';

  @override
  String get runtimeDescC => 'C and C++ — fast Clang compiler';

  @override
  String get runtimeDescGit => 'Version control and repos';

  @override
  String get runtimeDescComposer => 'PHP package manager';

  @override
  String get runtimeDescNovaWeb =>
      'PHP + Composer + Ruby + Node.js — web development';

  @override
  String get runtimeDescNovaSystems =>
      'Rust + Go + make + cmake — systems languages';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin — JVM platform';

  @override
  String get runtimeDescNovaPython => 'Python + pip — scripts and data';

  @override
  String get runtimeDescNovaDart => 'Dart — CLI tools';

  @override
  String get splashTagline => 'Your dev environment in your pocket';

  @override
  String get splashStatusEngine => 'Initializing engine…';

  @override
  String get splashStatusSettings => 'Loading settings…';

  @override
  String get splashStatusRuntime => 'Checking runtime…';

  @override
  String get splashStatusWorkspace => 'Preparing workspace…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • v$version (build $build)';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String appVersionBuild(String version, String build) {
    return 'v$version (build $build)';
  }
}
