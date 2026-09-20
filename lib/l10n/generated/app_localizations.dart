import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Bottom nav: projects tab
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// Bottom nav: editor tab
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get navEditor;

  /// Bottom nav: packages and SDK tab
  ///
  /// In en, this message translates to:
  /// **'SDK'**
  String get navPackagesSdk;

  /// Bottom nav: settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Common action: open
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// Common action: save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Common action: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Common action: delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Common action: create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Common action: retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Common action: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Common action: search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// Common action: import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// Common action: export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// Common action: copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Common action: share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Projects hub: workspace stats header
  ///
  /// In en, this message translates to:
  /// **'Workspace stats'**
  String get projectsWorkspaceStats;

  /// Projects hub: open folder action
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get projectsOpenFolder;

  /// Projects hub: open file action
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get projectsOpenFile;

  /// Projects hub: clone git action
  ///
  /// In en, this message translates to:
  /// **'Clone git repo'**
  String get projectsCloneGit;

  /// Projects hub: new project action
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectsNewProject;

  /// Projects hub: recent projects header
  ///
  /// In en, this message translates to:
  /// **'Recent projects'**
  String get projectsRecentProjects;

  /// Projects hub: recent files header
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get projectsRecentFiles;

  /// Projects hub: tips header
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get projectsTipsTitle;

  /// Projects hub: tip about organizing projects
  ///
  /// In en, this message translates to:
  /// **'Keep one folder per project to switch faster.'**
  String get projectsTipOrganize;

  /// Settings group: appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings group: theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Settings group: language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings group: editor
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsEditor;

  /// Settings group: font size
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settingsFontSize;

  /// Settings group: AI
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsAi;

  /// Settings group: timeout
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get settingsTimeout;

  /// Theme name: Nova dark
  ///
  /// In en, this message translates to:
  /// **'Nova dark'**
  String get themeNovaDark;

  /// Theme name: Nova light
  ///
  /// In en, this message translates to:
  /// **'Nova light'**
  String get themeNovaLight;

  /// Common action: run
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get actionRun;

  /// Common action: stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// Common action: refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// Common action: rename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// Common action: install
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get actionInstall;

  /// Common action: update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// Common action: uninstall
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get actionUninstall;

  /// Generic error with detail
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// Generic create failure
  ///
  /// In en, this message translates to:
  /// **'Create failed: {error}'**
  String commonCreateFailed(String error);

  /// Generic delete failure
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String commonDeleteFailed(String error);

  /// Generic rename failure
  ///
  /// In en, this message translates to:
  /// **'Rename failed: {error}'**
  String commonRenameFailed(String error);

  /// Projects hub: new project name hint
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectsProjectNameHint;

  /// Projects hub: delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get projectsDeleteTitle;

  /// Projects hub: delete dialog message
  ///
  /// In en, this message translates to:
  /// **'Delete \'{name}\' and all its files?'**
  String projectsDeleteMessage(String name);

  /// Projects hub: search hint
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get projectsSearchHint;

  /// Projects hub: status when setup state is unknown
  ///
  /// In en, this message translates to:
  /// **'Runtime status unavailable'**
  String get projectsStatusUnavailable;

  /// Projects hub: status when setup is not done
  ///
  /// In en, this message translates to:
  /// **'Runtime setup needed'**
  String get projectsSetupNeeded;

  /// Projects hub: status when runtime is ready
  ///
  /// In en, this message translates to:
  /// **'Runtime ready'**
  String get projectsRuntimeReady;

  /// Projects hub: open editor action
  ///
  /// In en, this message translates to:
  /// **'Open editor'**
  String get projectsOpenEditor;

  /// Projects hub: delete project action
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectsDeleteProject;

  /// Projects hub: empty state title
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmptyTitle;

  /// Projects hub: tips body
  ///
  /// In en, this message translates to:
  /// **'Tap a project to open it in the editor. Use the Packages tab to install runtimes before creating Node or Python projects.'**
  String get projectsTipsBody;

  /// Editor: empty state hint
  ///
  /// In en, this message translates to:
  /// **'Open a file from the explorer'**
  String get editorEmptyHint;

  /// Editor: save failure
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String editorSaveFailed(String error);

  /// Editor: saved confirmation
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String editorSaved(String name);

  /// Editor: open failure
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String editorOpenFailed(String error);

  /// Explorer: new file action
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get explorerNewFile;

  /// Explorer: rename hint
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get explorerNewNameHint;

  /// Explorer: delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get explorerDeleteTitle;

  /// Explorer: delete dialog message
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String explorerDeleteMessage(String name);

  /// Explorer: no project empty state
  ///
  /// In en, this message translates to:
  /// **'Select a project'**
  String get explorerSelectProject;

  /// Explorer: empty folder message
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get explorerEmptyFolder;

  /// Run panel: task start failure
  ///
  /// In en, this message translates to:
  /// **'Failed to start task: {error}'**
  String runStartFailed(String error);

  /// Run panel: no tasks hint
  ///
  /// In en, this message translates to:
  /// **'No tasks detected'**
  String get runNoTasks;

  /// Run panel: hide console tooltip
  ///
  /// In en, this message translates to:
  /// **'Hide console'**
  String get runHideConsole;

  /// Run panel: show console tooltip
  ///
  /// In en, this message translates to:
  /// **'Show console'**
  String get runShowConsole;

  /// Run panel: empty output hint
  ///
  /// In en, this message translates to:
  /// **'Press Run to execute the selected task. Output appears here.'**
  String get runEmptyHint;

  /// Git screen title
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get gitTitle;

  /// Git: commit action
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get gitCommit;

  /// Git: commit message label
  ///
  /// In en, this message translates to:
  /// **'Commit message'**
  String get gitCommitMessage;

  /// Git: committed confirmation
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get gitCommitted;

  /// Git: commit failure
  ///
  /// In en, this message translates to:
  /// **'Commit failed: {error}'**
  String gitCommitFailed(String error);

  /// Git: stage all action
  ///
  /// In en, this message translates to:
  /// **'Stage all'**
  String get gitStageAll;

  /// Git: staged confirmation
  ///
  /// In en, this message translates to:
  /// **'Staged all changes'**
  String get gitStagedAll;

  /// Git: stage failure
  ///
  /// In en, this message translates to:
  /// **'Stage failed: {error}'**
  String gitStageFailed(String error);

  /// Terminal screen title
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalTitle;

  /// Terminal: new session action
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get terminalNewSession;

  /// Terminal: session start failure
  ///
  /// In en, this message translates to:
  /// **'Failed to start terminal session'**
  String get terminalStartFailed;

  /// Process screen title
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get processTitle;

  /// Process: command input hint
  ///
  /// In en, this message translates to:
  /// **'Run command… e.g. npm run dev'**
  String get processRunHint;

  /// Process: empty state
  ///
  /// In en, this message translates to:
  /// **'No running processes.\nStart a task to see it here.'**
  String get processEmpty;

  /// Runtime screen title
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtimeTitle;

  /// Runtime: bootstrap header
  ///
  /// In en, this message translates to:
  /// **'Bootstrap'**
  String get runtimeBootstrap;

  /// Runtime: start setup action
  ///
  /// In en, this message translates to:
  /// **'Start setup'**
  String get runtimeStartSetup;

  /// Runtime: installed chip
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get runtimeInstalled;

  /// Runtime: available chip
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get runtimeAvailable;

  /// Runtime: uninstall confirmation
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String runtimeUninstallConfirm(String name);

  /// Runtime: empty state
  ///
  /// In en, this message translates to:
  /// **'No runtimes available.'**
  String get runtimeEmpty;

  /// Theme brightness tag: light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme brightness tag: dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme: reset brightness to system
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeFollowSystem;

  /// Workspace: expand tool drawer
  ///
  /// In en, this message translates to:
  /// **'Show tools'**
  String get toolsShow;

  /// Workspace: collapse tool drawer
  ///
  /// In en, this message translates to:
  /// **'Hide tools'**
  String get toolsHide;

  /// Workspace: expand app bar
  ///
  /// In en, this message translates to:
  /// **'Show toolbar'**
  String get toolbarShow;

  /// Workspace: collapse app bar
  ///
  /// In en, this message translates to:
  /// **'Hide toolbar'**
  String get toolbarHide;

  /// Workspace: show file explorer
  ///
  /// In en, this message translates to:
  /// **'Show explorer'**
  String get explorerShow;

  /// Workspace: hide file explorer
  ///
  /// In en, this message translates to:
  /// **'Hide explorer'**
  String get explorerHide;

  /// Workspace: new project
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNew;

  /// Workspace: new project name hint
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameHint;

  /// Workspace: delete project tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectDelete;

  /// Workspace: delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get projectDeleteTitle;

  /// Workspace: delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'Delete \'{name}\' and all its files?'**
  String projectDeleteBody(String name);

  /// Workspace: empty state
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get workspaceEmpty;

  /// Workspace: fallback title
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspaceTitle;

  /// Workspace: terminal tab
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get toolTerminal;

  /// Workspace: git tab
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get toolGit;

  /// Workspace: processes tab
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get toolProcesses;

  /// Workspace: project selector hint
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get projectSelect;

  /// Projects hub: new project tile hint
  ///
  /// In en, this message translates to:
  /// **'Start from a template'**
  String get projectsHintTemplate;

  /// Projects hub: open editor tile hint
  ///
  /// In en, this message translates to:
  /// **'Continue working'**
  String get projectsHintContinue;

  /// Projects hub: refresh tile hint
  ///
  /// In en, this message translates to:
  /// **'Reload project list'**
  String get projectsHintReload;

  /// Projects hub: delete tile hint
  ///
  /// In en, this message translates to:
  /// **'Remove active project'**
  String get projectsHintRemoveActive;

  /// Projects hub: show all filter chip
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String projectsFilterAll(int count);

  /// Projects hub: project count
  ///
  /// In en, this message translates to:
  /// **'{count} projects'**
  String projectsCount(int count);

  /// Editor: switch to edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorEdit;

  /// Editor: switch to preview mode
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// Editor: tab overflow menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Tab actions'**
  String get editorTabActions;

  /// Explorer: section header
  ///
  /// In en, this message translates to:
  /// **'EXPLORER'**
  String get explorerTitle;

  /// Explorer: go up tooltip
  ///
  /// In en, this message translates to:
  /// **'Go up'**
  String get explorerGoUp;

  /// Run panel: clear output tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear output'**
  String get runClearOutput;

  /// Run panel: starting hint
  ///
  /// In en, this message translates to:
  /// **'Starting process…'**
  String get runStartingProcess;

  /// Git: project section header
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get gitProject;

  /// Git: open project dropdown label
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get gitOpenProject;

  /// Git: project dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get gitSelectProject;

  /// Git: project path field label
  ///
  /// In en, this message translates to:
  /// **'Project path'**
  String get gitProjectPath;

  /// Git: status action
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get gitStatus;

  /// Git: diff action and dialog title
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get gitDiff;

  /// Git: unavailable error title
  ///
  /// In en, this message translates to:
  /// **'Git unavailable'**
  String get gitUnavailable;

  /// Git: current branch header
  ///
  /// In en, this message translates to:
  /// **'Branch: {branch}'**
  String gitBranch(String branch);

  /// Git: modified section header
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get gitModified;

  /// Git: added section header
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get gitAdded;

  /// Git: deleted section header
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get gitDeleted;

  /// Git: untracked section header
  ///
  /// In en, this message translates to:
  /// **'Untracked'**
  String get gitUntracked;

  /// Git: empty diff placeholder
  ///
  /// In en, this message translates to:
  /// **'(empty diff)'**
  String get gitEmptyDiff;

  /// Terminal: paste tooltip
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get terminalPaste;

  /// Terminal: session exited banner
  ///
  /// In en, this message translates to:
  /// **'Session exited (code {code})'**
  String terminalSessionExited(int code);

  /// Terminal: Tab accessory key label
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get terminalKeyTab;

  /// Terminal: Esc accessory key label
  ///
  /// In en, this message translates to:
  /// **'Esc'**
  String get terminalKeyEsc;

  /// Terminal: Up accessory key label
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get terminalKeyUp;

  /// Terminal: Down accessory key label
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get terminalKeyDown;

  /// Terminal: Left accessory key label
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get terminalKeyLeft;

  /// Terminal: Right accessory key label
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get terminalKeyRight;

  /// Process: started confirmation
  ///
  /// In en, this message translates to:
  /// **'Started {pid} · {command}'**
  String processStarted(String pid, String command);

  /// Process: fallback subtitle
  ///
  /// In en, this message translates to:
  /// **'Started by Nova'**
  String get processStartedByNova;

  /// Runtime: bootstrap ready chip
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get runtimeReady;

  /// Runtime: bootstrap ready detail
  ///
  /// In en, this message translates to:
  /// **'Bootstrap is ready. Runtimes can be installed below.'**
  String get runtimeBootstrapReady;

  /// Startup: bootstrap missing dialog title
  ///
  /// In en, this message translates to:
  /// **'Runtime required'**
  String get bootstrapRequired;

  /// Startup: bootstrap missing dialog body
  ///
  /// In en, this message translates to:
  /// **'The Linux runtime is not installed. Download it now to use the terminal and language runtimes?'**
  String get bootstrapRequiredBody;

  /// Generic: download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// Generic: dismiss for later
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get actionLater;

  /// Runtime: bootstrap unknown state
  ///
  /// In en, this message translates to:
  /// **'Bootstrap state unavailable.'**
  String get runtimeBootstrapUnavailable;

  /// Runtime: bootstrap missing state
  ///
  /// In en, this message translates to:
  /// **'Bootstrap is not installed yet.'**
  String get runtimeBootstrapNotInstalled;

  /// Runtime: version line
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String runtimeVersion(String version);

  /// Runtime: setup failure fallback
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get runtimeSetupFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
