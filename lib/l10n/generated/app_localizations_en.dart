// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get settingsFontSize => 'Font size';

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
}
