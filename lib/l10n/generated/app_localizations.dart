import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

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
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// Search: no results placeholder
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchEmpty;

  /// Search: initial hint
  ///
  /// In en, this message translates to:
  /// **'Search the active project above'**
  String get searchPrompt;

  /// Command palette: no results
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get commandPaletteEmpty;

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

  /// Common action: exit the app
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get actionExit;

  /// Exit confirm: dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit Nova?'**
  String get appExitTitle;

  /// Exit confirm: dialog body
  ///
  /// In en, this message translates to:
  /// **'Press Exit to close the app.'**
  String get appExitBody;

  /// Common action: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Common action: restore
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// Common action: discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

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

  /// Settings: font size label
  ///
  /// In en, this message translates to:
  /// **'Font size: {size}'**
  String settingsFontSize(String size);

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

  /// Git: per-file stage action
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get gitStage;

  /// Git: per-file staged confirmation
  ///
  /// In en, this message translates to:
  /// **'Staged {file}'**
  String gitStagedFile(String file);

  /// Git: branches dialog title
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get gitBranches;

  /// Git: checkout branch action
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get gitCheckout;

  /// Git: create branch action
  ///
  /// In en, this message translates to:
  /// **'New branch'**
  String get gitCreateBranch;

  /// Git: new branch name hint
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get gitBranchNameHint;

  /// Git: delete branch confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete branch \'{name}\'?'**
  String gitDeleteBranchConfirm(String name);

  /// Git: branch action failure
  ///
  /// In en, this message translates to:
  /// **'Branch action failed: {error}'**
  String gitBranchActionFailed(String error);

  /// Git: empty branches placeholder
  ///
  /// In en, this message translates to:
  /// **'(no branches)'**
  String get gitNoBranches;

  /// Git: stash section header
  ///
  /// In en, this message translates to:
  /// **'Stash'**
  String get gitStash;

  /// Git: stash save action
  ///
  /// In en, this message translates to:
  /// **'Stash changes'**
  String get gitStashSave;

  /// Git: stash message label
  ///
  /// In en, this message translates to:
  /// **'Stash message'**
  String get gitStashMessage;

  /// Git: stashed confirmation
  ///
  /// In en, this message translates to:
  /// **'Stashed changes'**
  String get gitStashed;

  /// Git: stash action failure
  ///
  /// In en, this message translates to:
  /// **'Stash action failed: {error}'**
  String gitStashActionFailed(String error);

  /// Git: remote section header
  ///
  /// In en, this message translates to:
  /// **'Remote (SSH)'**
  String get gitRemote;

  /// Git: clone action
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get gitClone;

  /// Git: clone URL label
  ///
  /// In en, this message translates to:
  /// **'Repository URL (SSH)'**
  String get gitCloneUrl;

  /// Git: clone destination label
  ///
  /// In en, this message translates to:
  /// **'Destination directory'**
  String get gitCloneDir;

  /// Git: cloned confirmation
  ///
  /// In en, this message translates to:
  /// **'Cloned successfully'**
  String get gitCloned;

  /// Git: fetch action
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get gitFetch;

  /// Git: fetched confirmation
  ///
  /// In en, this message translates to:
  /// **'Fetched'**
  String get gitFetched;

  /// Git: pull action
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get gitPull;

  /// Git: pulled confirmation
  ///
  /// In en, this message translates to:
  /// **'Pulled'**
  String get gitPulled;

  /// Git: push action
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get gitPush;

  /// Git: pushed confirmation
  ///
  /// In en, this message translates to:
  /// **'Pushed'**
  String get gitPushed;

  /// Git: remote failure
  ///
  /// In en, this message translates to:
  /// **'Remote operation failed: {error}'**
  String gitRemoteFailed(String error);

  /// Git: SSH public key label
  ///
  /// In en, this message translates to:
  /// **'App SSH public key'**
  String get gitSshKey;

  /// Git: no SSH key hint
  ///
  /// In en, this message translates to:
  /// **'No key yet — generate one, then add it to your hosting account.'**
  String get gitSshNoKey;

  /// Git: generate SSH key action
  ///
  /// In en, this message translates to:
  /// **'Generate key'**
  String get gitSshGenerate;

  /// Git: copy SSH key action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get gitSshCopy;

  /// Git: key copied confirmation
  ///
  /// In en, this message translates to:
  /// **'Public key copied — add it under your account\'s SSH keys'**
  String get gitSshCopied;

  /// Git: empty stash placeholder
  ///
  /// In en, this message translates to:
  /// **'(no stashed changes)'**
  String get gitStashEmpty;

  /// Git: stash pop action
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get gitStashPop;

  /// Git: stash drop action
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get gitStashDrop;

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

  /// Editor: reload confirm title
  ///
  /// In en, this message translates to:
  /// **'Reload file?'**
  String get editorReloadConfirmTitle;

  /// Editor: reload confirm body
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes and reload from disk?'**
  String get editorReloadConfirmBody;

  /// Editor: reloaded confirmation
  ///
  /// In en, this message translates to:
  /// **'Reloaded {name}'**
  String editorReloaded(String name);

  /// Editor: recovery dialog title
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes found'**
  String get editorRecoverTitle;

  /// Editor: recovery dialog body
  ///
  /// In en, this message translates to:
  /// **'Restore unsaved changes for {name}?'**
  String editorRecoverBody(String name);

  /// Editor: close dirty tab title
  ///
  /// In en, this message translates to:
  /// **'Close without saving?'**
  String get editorCloseDirtyTitle;

  /// Editor: close dirty tab body
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes to {name}?'**
  String editorCloseDirtyBody(String name);

  /// Editor: enter focus mode
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get editorFocusEnter;

  /// Editor: exit focus mode
  ///
  /// In en, this message translates to:
  /// **'Exit focus mode'**
  String get editorFocusExit;

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

  /// AI sheet title
  ///
  /// In en, this message translates to:
  /// **'AI actions'**
  String get aiTitle;

  /// AI: key saved confirmation
  ///
  /// In en, this message translates to:
  /// **'Key saved'**
  String get aiKeySaved;

  /// AI: missing key warning
  ///
  /// In en, this message translates to:
  /// **'Enter an API key first'**
  String get aiEnterKeyFirst;

  /// AI: empty selection placeholder
  ///
  /// In en, this message translates to:
  /// **'No code selected'**
  String get aiNoCode;

  /// AI: explain action
  ///
  /// In en, this message translates to:
  /// **'Explain code'**
  String get aiExplainCode;

  /// AI: fix action
  ///
  /// In en, this message translates to:
  /// **'Fix error'**
  String get aiFixError;

  /// AI: complete action
  ///
  /// In en, this message translates to:
  /// **'Complete code'**
  String get aiCompleteCode;

  /// AI: stop streaming
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aiStop;

  /// AI: insert result into editor
  ///
  /// In en, this message translates to:
  /// **'Insert into editor'**
  String get aiInsert;

  /// AI prompt: explain
  ///
  /// In en, this message translates to:
  /// **'Explain the following code:\n{code}'**
  String aiPromptExplain(String code);

  /// AI prompt: fix
  ///
  /// In en, this message translates to:
  /// **'Fix the error in the following code:\n{code}'**
  String aiPromptFix(String code);

  /// AI prompt: complete
  ///
  /// In en, this message translates to:
  /// **'Complete the following code:\n{code}'**
  String aiPromptComplete(String code);

  /// Settings: system language option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// Settings: run timeout label
  ///
  /// In en, this message translates to:
  /// **'Run timeout: {ms} ms'**
  String settingsRunTimeout(int ms);

  /// Settings: timeout field label
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms, 1000-120000)'**
  String get settingsTimeoutLabel;

  /// Settings: autocomplete title
  ///
  /// In en, this message translates to:
  /// **'Autocomplete'**
  String get settingsAutocomplete;

  /// Settings: autocomplete subtitle
  ///
  /// In en, this message translates to:
  /// **'Keyword, snippet and word suggestions while typing'**
  String get settingsAutocompleteSub;

  /// Settings: AI completion title
  ///
  /// In en, this message translates to:
  /// **'AI completion'**
  String get settingsAiCompletion;

  /// Settings: AI completion subtitle
  ///
  /// In en, this message translates to:
  /// **'Model suggestions in the autocomplete popup'**
  String get settingsAiCompletionSub;

  /// Settings: follow editor theme
  ///
  /// In en, this message translates to:
  /// **'Match app to editor theme'**
  String get settingsMatchTheme;

  /// Settings: follow editor theme subtitle
  ///
  /// In en, this message translates to:
  /// **'Whole app follows the editor theme colors'**
  String get settingsMatchThemeSub;

  /// Settings: word wrap
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get settingsWordWrap;

  /// Settings: word wrap subtitle
  ///
  /// In en, this message translates to:
  /// **'Wrap long lines instead of scrolling sideways'**
  String get settingsWordWrapSub;

  /// Settings: auto save
  ///
  /// In en, this message translates to:
  /// **'Auto save'**
  String get settingsAutoSave;

  /// Settings: auto save subtitle
  ///
  /// In en, this message translates to:
  /// **'Save 1.5s after you stop typing'**
  String get settingsAutoSaveSub;

  /// Settings: editor font label
  ///
  /// In en, this message translates to:
  /// **'Editor font'**
  String get settingsEditorFont;

  /// Settings: font installed
  ///
  /// In en, this message translates to:
  /// **'Font installed'**
  String get settingsFontInstalled;

  /// Settings: font updated
  ///
  /// In en, this message translates to:
  /// **'Editor font updated'**
  String get settingsFontUpdated;

  /// Settings: font download failure
  ///
  /// In en, this message translates to:
  /// **'Download failed: check connection'**
  String get settingsDownloadFailed;

  /// Settings: live preview header
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get settingsLivePreview;

  /// Settings: AI provider label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsProvider;

  /// Settings: custom provider option
  ///
  /// In en, this message translates to:
  /// **'Custom (OpenAI compatible)'**
  String get settingsCustomProvider;

  /// Settings: base URL label
  ///
  /// In en, this message translates to:
  /// **'Base URL (OpenAI compatible)'**
  String get settingsBaseUrl;

  /// Settings: model label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsModel;

  /// Settings: API key label
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsApiKey;

  /// Settings: key saved hint
  ///
  /// In en, this message translates to:
  /// **'Saved in secure storage'**
  String get settingsApiKeySaved;

  /// Settings: key hint
  ///
  /// In en, this message translates to:
  /// **'Paste your key'**
  String get settingsApiKeyHint;

  /// Settings: secure storage note
  ///
  /// In en, this message translates to:
  /// **'The key is stored in encrypted secure storage, never in plain settings.'**
  String get settingsKeySecureNote;

  /// Settings: test connection
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsTestConnection;

  /// Settings: testing state
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get settingsTesting;

  /// Settings: saved confirmation
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// Settings: connection ok
  ///
  /// In en, this message translates to:
  /// **'Connected: {reply}'**
  String settingsConnected(String reply);

  /// Settings: connection failure
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String settingsConnectionFailed(String error);

  /// Settings: theme imported
  ///
  /// In en, this message translates to:
  /// **'Theme \"{name}\" imported'**
  String settingsThemeImported(String name);

  /// Settings: import failure
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// Settings: theme copied
  ///
  /// In en, this message translates to:
  /// **'Theme \"{name}\" JSON copied'**
  String settingsThemeCopied(String name);

  /// Settings: theme exported
  ///
  /// In en, this message translates to:
  /// **'Theme \"{name}\" exported to clipboard'**
  String settingsThemeExported(String name);

  /// Settings: import theme action
  ///
  /// In en, this message translates to:
  /// **'Import theme JSON'**
  String get settingsImportTheme;

  /// Settings: copy theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy theme JSON'**
  String get settingsCopyTheme;

  /// Settings: export theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Export theme'**
  String get settingsExportTheme;

  /// Settings: delete theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete theme'**
  String get settingsDeleteTheme;

  /// Search: screen title
  ///
  /// In en, this message translates to:
  /// **'Search in project'**
  String get searchTitle;

  /// Search: query hint
  ///
  /// In en, this message translates to:
  /// **'Search text or pattern…'**
  String get searchHint;

  /// Search: replace hint
  ///
  /// In en, this message translates to:
  /// **'Replace with…'**
  String get searchReplaceHint;

  /// Search: match case
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get searchMatchCase;

  /// Search: regex tooltip
  ///
  /// In en, this message translates to:
  /// **'Use regular expression'**
  String get searchUseRegex;

  /// Search: action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// Search: action with count
  ///
  /// In en, this message translates to:
  /// **'Search ({hits})'**
  String searchButtonCount(int hits);

  /// Search: replace all
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get searchReplaceAll;

  /// Search: no project error
  ///
  /// In en, this message translates to:
  /// **'No project open'**
  String get searchNoProject;

  /// Search: empty query error
  ///
  /// In en, this message translates to:
  /// **'Type something to search for'**
  String get searchTypeSomething;

  /// Search: bad regex
  ///
  /// In en, this message translates to:
  /// **'Invalid regular expression'**
  String get searchInvalidRegex;

  /// Search: failure
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(String error);

  /// Search: empty state
  ///
  /// In en, this message translates to:
  /// **'Search the active project above'**
  String get searchEmptyHint;

  /// Search: no matches
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// Search: truncated notice
  ///
  /// In en, this message translates to:
  /// **'Showing the first matches only (limits reached)'**
  String get searchTruncated;

  /// Search: per-file replace
  ///
  /// In en, this message translates to:
  /// **'Replace ({count})'**
  String searchReplaceCount(int count);

  /// Search: dirty confirm title
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get searchUnsavedTitle;

  /// Search: dirty confirm body
  ///
  /// In en, this message translates to:
  /// **'These open tabs have unsaved edits that replace would overwrite: {names}. Replace anyway?'**
  String searchUnsavedBody(String names);

  /// Search: confirm replace
  ///
  /// In en, this message translates to:
  /// **'Replace anyway'**
  String get searchReplaceAnyway;

  /// Search: nothing to replace
  ///
  /// In en, this message translates to:
  /// **'No matches to replace'**
  String get searchNoMatchesReplace;

  /// Search: replace-all notice
  ///
  /// In en, this message translates to:
  /// **'Replaced {total} in {files} files. Reopen affected tabs to reload.'**
  String searchReplaced(int total, int files);

  /// Search: replace failure
  ///
  /// In en, this message translates to:
  /// **'Replace failed: {error}'**
  String searchReplaceFailed(String error);

  /// Search: no matches in file
  ///
  /// In en, this message translates to:
  /// **'No matches in {name}'**
  String searchNoMatchesIn(String name);

  /// Search: replaced in file
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} in {name}. Reopen the tab to reload.'**
  String searchReplacedIn(int count, String name);

  /// Editor: find tooltip
  ///
  /// In en, this message translates to:
  /// **'Find in file'**
  String get editorFindInFile;

  /// Editor: go to definition tooltip
  ///
  /// In en, this message translates to:
  /// **'Go to definition'**
  String get editorGoToDefinition;

  /// Editor: definition with no symbol toast
  ///
  /// In en, this message translates to:
  /// **'Place the caret on a symbol first'**
  String get editorNoSymbolAtCaret;

  /// Editor: definition lookup miss toast
  ///
  /// In en, this message translates to:
  /// **'No definition found for \'{name}\''**
  String editorDefinitionNotFound(String name);

  /// Editor: find hint
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get editorFindHint;

  /// Editor: previous match
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get editorPrevMatch;

  /// Editor: next match
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get editorNextMatch;

  /// Editor: match case
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get editorMatchCase;

  /// Editor: regex tooltip
  ///
  /// In en, this message translates to:
  /// **'Use regular expression'**
  String get editorUseRegex;

  /// Editor: close find
  ///
  /// In en, this message translates to:
  /// **'Close find bar'**
  String get editorCloseFind;

  /// Explorer: storage error
  ///
  /// In en, this message translates to:
  /// **'Storage not writable here: {error}'**
  String explorerStorageError(String error);

  /// Explorer: new file hint
  ///
  /// In en, this message translates to:
  /// **'e.g. main.py'**
  String get explorerNewFileHint;

  /// Explorer: no folder
  ///
  /// In en, this message translates to:
  /// **'No folder selected'**
  String get explorerNoFolder;

  /// Markdown: undo
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mdUndo;

  /// Markdown: redo
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get mdRedo;

  /// Markdown: bold
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get mdBold;

  /// Markdown: italic
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get mdItalic;

  /// Markdown: underline
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get mdUnderline;

  /// Markdown: strikethrough
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get mdStrike;

  /// Markdown: inline code
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get mdInlineCode;

  /// Markdown: H1
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get mdH1;

  /// Markdown: H2
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get mdH2;

  /// Markdown: H3
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get mdH3;

  /// Markdown: bullet list
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get mdBulleted;

  /// Markdown: numbered list
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get mdNumbered;

  /// Markdown: quote
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get mdQuote;

  /// Markdown: code block
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get mdCodeBlock;

  /// Terminal: tab limit
  ///
  /// In en, this message translates to:
  /// **'Maximum of 5 terminal tabs reached'**
  String get terminalMaxTabs;

  /// Palette: input hint
  ///
  /// In en, this message translates to:
  /// **'Type a command or file name…'**
  String get paletteHint;

  /// Palette: empty state
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get paletteNoMatches;

  /// Palette: toggle run
  ///
  /// In en, this message translates to:
  /// **'Toggle Run panel'**
  String get paletteToggleRun;

  /// Palette: toggle terminal
  ///
  /// In en, this message translates to:
  /// **'Toggle Terminal'**
  String get paletteToggleTerminal;

  /// Palette: toggle git
  ///
  /// In en, this message translates to:
  /// **'Toggle Git panel'**
  String get paletteToggleGit;

  /// Palette: toggle processes
  ///
  /// In en, this message translates to:
  /// **'Toggle Processes panel'**
  String get paletteToggleProcesses;

  /// Palette: switch theme
  ///
  /// In en, this message translates to:
  /// **'Switch editor theme'**
  String get paletteSwitchTheme;

  /// Palette: search command
  ///
  /// In en, this message translates to:
  /// **'Search in project'**
  String get paletteSearchInProject;

  /// Palette: open settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get paletteOpenSettings;

  /// Workspace: command palette tooltip
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get paletteTitle;

  /// New project: general option
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get projectGeneral;

  /// New project: general subtitle
  ///
  /// In en, this message translates to:
  /// **'No runtime assumed — language auto-detected'**
  String get projectGeneralSub;

  /// Runtime: install ok
  ///
  /// In en, this message translates to:
  /// **'Installed {name} successfully'**
  String runtimeInstalledOk(String name);

  /// Runtime: install failure
  ///
  /// In en, this message translates to:
  /// **'Failed to install {name}: {error}'**
  String runtimeInstallFailed(String name, String error);

  /// Runtime: start install
  ///
  /// In en, this message translates to:
  /// **'Starting install of {name}…'**
  String runtimeStartInstall(String name);

  /// Runtime: start failure
  ///
  /// In en, this message translates to:
  /// **'Failed to start install: {error}'**
  String runtimeStartInstallFailed(String error);

  /// Runtime: start update
  ///
  /// In en, this message translates to:
  /// **'Starting update of {name}…'**
  String runtimeStartUpdate(String name);

  /// Runtime: update start failure
  ///
  /// In en, this message translates to:
  /// **'Failed to start update: {error}'**
  String runtimeStartUpdateFailed(String error);

  /// Runtime: removing
  ///
  /// In en, this message translates to:
  /// **'Removing {name}…'**
  String runtimeRemoving(String name);

  /// Runtime: remove failure
  ///
  /// In en, this message translates to:
  /// **'Removal failed: {error}'**
  String runtimeRemoveFailed(String error);

  /// Runtime: variant prompt
  ///
  /// In en, this message translates to:
  /// **'Choose a Linux system image (downloaded once from the internet):'**
  String get runtimeChooseVariant;

  /// Runtime: slim variant
  ///
  /// In en, this message translates to:
  /// **'Slim ~70MB (recommended)'**
  String get runtimeVariantSlim;

  /// Runtime: slim subtitle
  ///
  /// In en, this message translates to:
  /// **'Core + apt — languages install on demand'**
  String get runtimeVariantSlimSub;

  /// Runtime: full variant
  ///
  /// In en, this message translates to:
  /// **'Full ~283MB'**
  String get runtimeVariantFull;

  /// Runtime: full subtitle
  ///
  /// In en, this message translates to:
  /// **'Node, Python, PHP and Git preinstalled — works offline'**
  String get runtimeVariantFullSub;

  /// Runtime: search empty
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get runtimeNoResults;

  /// Runtime: search hint
  ///
  /// In en, this message translates to:
  /// **'Search for a language or tool…'**
  String get runtimeSearchHint;

  /// Runtime: clear action
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get runtimeClear;

  /// Runtime: unsupported chip
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device'**
  String get runtimeUnsupported;

  /// Runtime: installed header
  ///
  /// In en, this message translates to:
  /// **'Installed ({count})'**
  String runtimeInstalledSection(int count);

  /// Runtime: packs header
  ///
  /// In en, this message translates to:
  /// **'Ready packs ({count})'**
  String runtimePacksSection(int count);

  /// Runtime: languages header
  ///
  /// In en, this message translates to:
  /// **'Languages ({count})'**
  String runtimeLanguagesSection(int count);

  /// Runtime: tools header
  ///
  /// In en, this message translates to:
  /// **'Tools ({count})'**
  String runtimeToolsSection(int count);

  /// Runtime: active op
  ///
  /// In en, this message translates to:
  /// **'Running: {name}'**
  String runtimeWorking(String name);

  /// Runtime: last op
  ///
  /// In en, this message translates to:
  /// **'Last operation: {name}'**
  String runtimeLastOp(String name);

  /// Runtime: log title
  ///
  /// In en, this message translates to:
  /// **'Operation log'**
  String get runtimeLogTitle;

  /// Runtime: log count
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String runtimeLines(int count);

  /// Runtime: done status
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get runtimeDone;

  /// Runtime: apt update status
  ///
  /// In en, this message translates to:
  /// **'Updating package lists…'**
  String get runtimeStatusUpdating;

  /// Runtime: apt install status
  ///
  /// In en, this message translates to:
  /// **'Starting install…'**
  String get runtimeStatusInstalling;

  /// Runtime: reading lists
  ///
  /// In en, this message translates to:
  /// **'Reading package lists…'**
  String get runtimeStatusReading;

  /// Runtime: dep tree
  ///
  /// In en, this message translates to:
  /// **'Building dependency tree…'**
  String get runtimeStatusDeps;

  /// Runtime: unpacking
  ///
  /// In en, this message translates to:
  /// **'Unpacking packages…'**
  String get runtimeStatusUnpacking;

  /// Runtime: setup pkgs
  ///
  /// In en, this message translates to:
  /// **'Setting up packages…'**
  String get runtimeStatusSettingUp;

  /// Runtime: working fallback
  ///
  /// In en, this message translates to:
  /// **'Working on {name}…'**
  String runtimeWorkingOn(String name);

  /// Setup wizard: slim
  ///
  /// In en, this message translates to:
  /// **'Slim ~80MB (default)'**
  String get setupSlimTitle;

  /// Setup wizard: slim subtitle
  ///
  /// In en, this message translates to:
  /// **'Core + apt — languages install on demand'**
  String get setupSlimSub;

  /// Setup wizard: full
  ///
  /// In en, this message translates to:
  /// **'Full ~283MB (offline)'**
  String get setupFullTitle;

  /// Setup wizard: full subtitle
  ///
  /// In en, this message translates to:
  /// **'Node, Python, PHP and Git preinstalled'**
  String get setupFullSub;

  /// Setup wizard: resume note
  ///
  /// In en, this message translates to:
  /// **'Retry reuses the verified download (resume).'**
  String get setupResumeNote;

  /// Setup wizard: sources status title
  ///
  /// In en, this message translates to:
  /// **'Download sources:'**
  String get setupSources;

  /// Setup wizard: source reachable
  ///
  /// In en, this message translates to:
  /// **'reachable'**
  String get setupSourceOk;

  /// Setup wizard: source unreachable
  ///
  /// In en, this message translates to:
  /// **'unreachable — check connection'**
  String get setupSourceDown;

  /// Web preview title
  ///
  /// In en, this message translates to:
  /// **'Web Preview'**
  String get webPreviewTitle;

  /// Runtime desc: php
  ///
  /// In en, this message translates to:
  /// **'Web language — Laravel and WordPress'**
  String get runtimeDescPhp;

  /// Runtime desc: node
  ///
  /// In en, this message translates to:
  /// **'JavaScript and TypeScript — npm included'**
  String get runtimeDescNode;

  /// Runtime desc: python
  ///
  /// In en, this message translates to:
  /// **'Scripts and data — pip included'**
  String get runtimeDescPython;

  /// Runtime desc: go
  ///
  /// In en, this message translates to:
  /// **'Compiled Go — fast and light'**
  String get runtimeDescGo;

  /// Runtime desc: rust
  ///
  /// In en, this message translates to:
  /// **'Rust — memory safety and performance'**
  String get runtimeDescRust;

  /// Runtime desc: ruby
  ///
  /// In en, this message translates to:
  /// **'Ruby for scripts and web'**
  String get runtimeDescRuby;

  /// Runtime desc: java
  ///
  /// In en, this message translates to:
  /// **'Java 25 — full JVM platform'**
  String get runtimeDescJava;

  /// Runtime desc: kotlin
  ///
  /// In en, this message translates to:
  /// **'Kotlin — runs on JVM (needs Java)'**
  String get runtimeDescKotlin;

  /// Runtime desc: dart
  ///
  /// In en, this message translates to:
  /// **'Dart — apps and CLI tools'**
  String get runtimeDescDart;

  /// Runtime desc: c
  ///
  /// In en, this message translates to:
  /// **'C and C++ — fast Clang compiler'**
  String get runtimeDescC;

  /// Runtime desc: git
  ///
  /// In en, this message translates to:
  /// **'Version control and repos'**
  String get runtimeDescGit;

  /// Runtime desc: composer
  ///
  /// In en, this message translates to:
  /// **'PHP package manager'**
  String get runtimeDescComposer;

  /// Runtime desc: nova-web
  ///
  /// In en, this message translates to:
  /// **'PHP + Composer + Ruby + Node.js — web development'**
  String get runtimeDescNovaWeb;

  /// Runtime desc: nova-systems
  ///
  /// In en, this message translates to:
  /// **'Rust + Go + make + cmake — systems languages'**
  String get runtimeDescNovaSystems;

  /// Runtime desc: nova-jvm
  ///
  /// In en, this message translates to:
  /// **'Java 25 + Kotlin — JVM platform'**
  String get runtimeDescNovaJvm;

  /// Runtime desc: nova-python
  ///
  /// In en, this message translates to:
  /// **'Python + pip — scripts and data'**
  String get runtimeDescNovaPython;

  /// Runtime desc: nova-dart
  ///
  /// In en, this message translates to:
  /// **'Dart — CLI tools'**
  String get runtimeDescNovaDart;

  /// Splash: tagline under the Nova logo
  ///
  /// In en, this message translates to:
  /// **'Your dev environment in your pocket'**
  String get splashTagline;

  /// Splash: loader status while warming the engine
  ///
  /// In en, this message translates to:
  /// **'Initializing engine…'**
  String get splashStatusEngine;

  /// Splash: loader status while loading settings
  ///
  /// In en, this message translates to:
  /// **'Loading settings…'**
  String get splashStatusSettings;

  /// Splash: loader status while probing the runtime
  ///
  /// In en, this message translates to:
  /// **'Checking runtime…'**
  String get splashStatusRuntime;

  /// Splash: loader status while preparing the workspace
  ///
  /// In en, this message translates to:
  /// **'Preparing workspace…'**
  String get splashStatusWorkspace;

  /// Splash: version footer
  ///
  /// In en, this message translates to:
  /// **'Nova • v{version} (build {build})'**
  String splashVersionFooter(String version, String build);

  /// Settings: about section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Shared: version with build number
  ///
  /// In en, this message translates to:
  /// **'v{version} (build {build})'**
  String appVersionBuild(String version, String build);

  /// About screen: app bar title
  ///
  /// In en, this message translates to:
  /// **'About & Contact'**
  String get aboutTitle;

  /// About screen: tagline under the app name
  ///
  /// In en, this message translates to:
  /// **'Your dev environment in your pocket'**
  String get aboutTagline;

  /// About screen: about section header
  ///
  /// In en, this message translates to:
  /// **'About Nova'**
  String get aboutSectionAbout;

  /// About screen: short product description
  ///
  /// In en, this message translates to:
  /// **'Nova is a code editor that runs on your Android phone and executes code right on the device — Python, JavaScript, PHP, Go, Rust, Ruby, Java, Kotlin, Dart, C/C++ — with a real terminal, Git, and web preview. No external server, no emulation: write, press Run, and see the result.'**
  String get aboutDescription;

  /// About screen: download section header
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get aboutSectionDownload;

  /// About screen: Play store entry title
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get aboutPlayTitle;

  /// About screen: Play store entry subtitle
  ///
  /// In en, this message translates to:
  /// **'The easy install for most users, updated via the Play Store'**
  String get aboutPlaySub;

  /// About screen: GitHub releases entry title
  ///
  /// In en, this message translates to:
  /// **'GitHub releases'**
  String get aboutGithubTitle;

  /// About screen: GitHub releases entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Direct APKs from the project releases page'**
  String get aboutGithubSub;

  /// About screen: version difference explainer title
  ///
  /// In en, this message translates to:
  /// **'Which version should I use?'**
  String get aboutVersionsTitle;

  /// About screen: version difference explainer body
  ///
  /// In en, this message translates to:
  /// **'The GitHub build targets Android API 28 with direct execution — the current shipping path where the embedded Linux runtime runs at full power. The Play build targets API 36 and executes through the linker, to comply with current Play Store policies. Same editor and features; only the runtime launch path differs.'**
  String get aboutVersionsBody;

  /// About screen: project links section header
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get aboutSectionProject;

  /// About screen: source code row title
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSourceCode;

  /// About screen: releases row title
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get aboutReleases;

  /// About screen: apt repository row title
  ///
  /// In en, this message translates to:
  /// **'Package repository'**
  String get aboutPackageRepo;

  /// About screen: license row title
  ///
  /// In en, this message translates to:
  /// **'License: Waqf General Public License v1'**
  String get aboutLicense;

  /// About screen: license row subtitle
  ///
  /// In en, this message translates to:
  /// **'A waqf for the sake of Allah — free to use, share, and modify'**
  String get aboutLicenseSub;

  /// About screen: contact section header
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get aboutSectionContact;

  /// About screen: email row title
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get aboutEmailUs;

  /// About screen: email row subtitle
  ///
  /// In en, this message translates to:
  /// **'For questions, feedback, and bug reports'**
  String get aboutEmailHint;

  /// About screen: copied-to-clipboard confirmation
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aboutCopied;

  /// About screen: link open failure message
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get aboutOpenFailed;

  /// Auth: account section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authAccount;

  /// Auth: continue without signing in
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// Auth: delete account action
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get authDelete;

  /// Auth: delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account. Continue?'**
  String get authDeleteBody;

  /// Auth: delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get authDeleteTitle;

  /// Auth: email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Auth: forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgot;

  /// Auth: reset dialog hint
  ///
  /// In en, this message translates to:
  /// **'We will email you a reset link.'**
  String get authForgotHint;

  /// Auth: reset dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authForgotTitle;

  /// Auth: GitHub sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with GitHub'**
  String get authGithub;

  /// Auth: Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// Auth: guest-first note
  ///
  /// In en, this message translates to:
  /// **'Guest mode: nothing is locked. Sign-in is optional.'**
  String get authGuestNote;

  /// Auth: anonymous guest label
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get authGuest;

  /// Auth: invalid email message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// Auth: login tab and button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// Auth: sign out action
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authLogout;

  /// Auth: password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Auth: short password message
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// Auth: resend verification action
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get authResend;

  /// Auth: verification sent confirmation
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get authResent;

  /// Auth: send reset link action
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get authSend;

  /// Auth: reset sent confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset email sent'**
  String get authSent;

  /// Auth: signup tab and button
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get authSignup;

  /// Auth: signed-out state
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get authSignedOut;

  /// Auth: login screen title
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTitle;

  /// Auth: verify-email banner
  ///
  /// In en, this message translates to:
  /// **'Email not verified. Verify to secure your account.'**
  String get authVerifyBanner;

  /// Auth: X sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with X'**
  String get authX;

  /// Notifications: copy FCM token action
  ///
  /// In en, this message translates to:
  /// **'Copy push token'**
  String get notifCopyToken;

  /// Notifications: delete one action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notifDelete;

  /// Notifications: empty state
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmpty;

  /// Notifications: mark all read action
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// Notifications: screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// Notifications: token copied confirmation
  ///
  /// In en, this message translates to:
  /// **'Push token copied'**
  String get notifTokenCopied;

  /// First-launch language picker title
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get langTitle;

  /// First-launch language picker subtitle
  ///
  /// In en, this message translates to:
  /// **'You can change it anytime from Settings'**
  String get langSubtitle;

  /// First-launch language picker confirm button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get langContinue;

  /// Onboarding: skip everything
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// Onboarding: next slide
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// Onboarding: finish button
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardStart;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'A real code editor'**
  String get onboard1Title;

  /// Onboarding slide 1 body
  ///
  /// In en, this message translates to:
  /// **'Syntax highlighting, smart autocomplete, and themes for every language.'**
  String get onboard1Body;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Linux terminal on your phone'**
  String get onboard2Title;

  /// Onboarding slide 2 body
  ///
  /// In en, this message translates to:
  /// **'Node.js, Python and Git run natively inside the app — no root needed.'**
  String get onboard2Body;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'AI pair programmer'**
  String get onboard3Title;

  /// Onboarding slide 3 body
  ///
  /// In en, this message translates to:
  /// **'Explain code, fix errors, and generate snippets with any provider.'**
  String get onboard3Body;

  /// Onboarding slide 4 title
  ///
  /// In en, this message translates to:
  /// **'Projects and Git'**
  String get onboard4Title;

  /// Onboarding slide 4 body
  ///
  /// In en, this message translates to:
  /// **'Open folders, browse files, and commit from anywhere.'**
  String get onboard4Body;

  /// Tour: back to the previous step
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// Tour: hub search step title
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get tourHubSearchTitle;

  /// Tour: hub search step body
  ///
  /// In en, this message translates to:
  /// **'Filter the project list by name. Tap the field and type — the list narrows as you type.'**
  String get tourHubSearchBody;

  /// Tour: hub new-project step title
  ///
  /// In en, this message translates to:
  /// **'Create a project'**
  String get tourHubNewTitle;

  /// Tour: hub new-project step body
  ///
  /// In en, this message translates to:
  /// **'Start a new project from a template. Pressing it opens the create dialog — Cancel it (or tap Next) to stay in the tour.'**
  String get tourHubNewBody;

  /// Tour: hub project-card step title
  ///
  /// In en, this message translates to:
  /// **'Your projects'**
  String get tourHubCardTitle;

  /// Tour: hub project-card step body
  ///
  /// In en, this message translates to:
  /// **'Tap a project card to make it the active project. The highlighted card is the one the editor and run tools use.'**
  String get tourHubCardBody;

  /// Tour: hub open-editor step title
  ///
  /// In en, this message translates to:
  /// **'Open the editor'**
  String get tourHubOpenTitle;

  /// Tour: hub open-editor step body
  ///
  /// In en, this message translates to:
  /// **'Jump into the workspace for the active project. Tap Next to stay in the tour — pressing the tile now leaves the hub and ends the tour early.'**
  String get tourHubOpenBody;

  /// Tour: hub recent-files step title
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get tourHubRecentTitle;

  /// Tour: hub recent-files step body
  ///
  /// In en, this message translates to:
  /// **'Reopen the last files you edited, across all projects. Tapping one opens it straight in the editor.'**
  String get tourHubRecentBody;

  /// Tour: hub navigation step title
  ///
  /// In en, this message translates to:
  /// **'Getting around'**
  String get tourHubNavTitle;

  /// Tour: hub navigation step body
  ///
  /// In en, this message translates to:
  /// **'Bottom bar destinations: Projects (here), Editor (workspace), Runtime (language setup), Settings. The ? button replays a tour anytime.'**
  String get tourHubNavBody;

  /// Tour: editor project-switcher step title
  ///
  /// In en, this message translates to:
  /// **'Project switcher'**
  String get tourEdProjectTitle;

  /// Tour: editor project-switcher step body
  ///
  /// In en, this message translates to:
  /// **'Switch the active project — explorer, editor and run tools follow. Pressing opens the menu: pick nothing (Back) or tap Next to continue.'**
  String get tourEdProjectBody;

  /// Tour: editor command-palette step title
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get tourEdPaletteTitle;

  /// Tour: editor command-palette step body
  ///
  /// In en, this message translates to:
  /// **'Fuzzy-find files and run tool/theme commands. Pressing opens the palette — go Back (or tap Next) to continue the tour.'**
  String get tourEdPaletteBody;

  /// Tour: editor file-entry step title
  ///
  /// In en, this message translates to:
  /// **'Project files'**
  String get tourEdEntryTitle;

  /// Tour: editor file-entry step body
  ///
  /// In en, this message translates to:
  /// **'Tap a file to open it in the editor — this guarantees an open tab for the next steps. Long-press for rename and delete.'**
  String get tourEdEntryBody;

  /// Tour: editor new-file step title
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get tourEdNewFileTitle;

  /// Tour: editor new-file step body
  ///
  /// In en, this message translates to:
  /// **'Create a file in the current folder. Pressing asks for a name — Cancel the dialog (or tap Next) to continue.'**
  String get tourEdNewFileBody;

  /// Tour: editor go-up step title
  ///
  /// In en, this message translates to:
  /// **'Go up'**
  String get tourEdGoUpTitle;

  /// Tour: editor go-up step body
  ///
  /// In en, this message translates to:
  /// **'Move the explorer to the parent folder. Disabled at the project root.'**
  String get tourEdGoUpBody;

  /// Tour: editor explorer-visibility step title
  ///
  /// In en, this message translates to:
  /// **'Explorer visibility'**
  String get tourEdExplorerTitle;

  /// Tour: editor explorer-visibility step body
  ///
  /// In en, this message translates to:
  /// **'Hide the file pane for more editor width. All file steps are done, so pressing it now is safe — press again to bring the pane back.'**
  String get tourEdExplorerBody;

  /// Tour: editor tabs step title
  ///
  /// In en, this message translates to:
  /// **'Open tabs'**
  String get tourEdTabsTitle;

  /// Tour: editor tabs step body
  ///
  /// In en, this message translates to:
  /// **'Every open file is a tab. Tap a tab to switch to it.'**
  String get tourEdTabsBody;

  /// Tour: editor save step title
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tourEdSaveTitle;

  /// Tour: editor save step body
  ///
  /// In en, this message translates to:
  /// **'Write the current file to disk. On a clean file this just confirms everything is saved.'**
  String get tourEdSaveBody;

  /// Tour: editor reload step title
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get tourEdReloadTitle;

  /// Tour: editor reload step body
  ///
  /// In en, this message translates to:
  /// **'Re-read the file from disk. Clean files reload silently; dirty files ask for confirmation first.'**
  String get tourEdReloadBody;

  /// Tour: editor AI-assist step title
  ///
  /// In en, this message translates to:
  /// **'AI assist'**
  String get tourEdAiTitle;

  /// Tour: editor AI-assist step body
  ///
  /// In en, this message translates to:
  /// **'Explain, complete or edit the selected code with AI. Pressing opens the AI sheet — close it to continue the tour.'**
  String get tourEdAiBody;

  /// Tour: editor markdown-preview step title
  ///
  /// In en, this message translates to:
  /// **'Markdown preview'**
  String get tourEdPreviewTitle;

  /// Tour: editor markdown-preview step body
  ///
  /// In en, this message translates to:
  /// **'Markdown files toggle between edit and rendered preview here. Hidden for code files.'**
  String get tourEdPreviewBody;

  /// Tour: editor run-tools step title
  ///
  /// In en, this message translates to:
  /// **'Run tools'**
  String get tourEdRunTabTitle;

  /// Tour: editor run-tools step body
  ///
  /// In en, this message translates to:
  /// **'Switch the bottom drawer: Run, Terminal, Git, Processes. This step selects Run so the next steps are visible.'**
  String get tourEdRunTabBody;

  /// Tour: editor run-task step title
  ///
  /// In en, this message translates to:
  /// **'Run task'**
  String get tourEdTaskTitle;

  /// Tour: editor run-task step body
  ///
  /// In en, this message translates to:
  /// **'Pick the detected task to run, e.g. run or test for this project. Pressing opens the menu — choose a task or tap Next.'**
  String get tourEdTaskBody;

  /// Tour: editor run step title
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get tourEdRunTitle;

  /// Tour: editor run step body
  ///
  /// In en, this message translates to:
  /// **'Start the selected task — output streams below. Pressing really starts a process; stop it from the same button.'**
  String get tourEdRunBody;

  /// Tour: editor go-to-definition step title
  ///
  /// In en, this message translates to:
  /// **'Go to definition'**
  String get tourEdDefTitle;

  /// Tour: editor go-to-definition step body
  ///
  /// In en, this message translates to:
  /// **'Jump to the symbol under the caret. You may land in another file — the remaining steps still work there.'**
  String get tourEdDefBody;

  /// Tour: editor close-tab step title
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get tourEdTabCloseTitle;

  /// Tour: editor close-tab step body
  ///
  /// In en, this message translates to:
  /// **'Close this tab; unsaved edits ask for confirmation. If this is your only tab, tap Next instead of the × to keep the tour intact.'**
  String get tourEdTabCloseBody;

  /// Tour: editor delete-project step title
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get tourEdDeleteTitle;

  /// Tour: editor delete-project step body
  ///
  /// In en, this message translates to:
  /// **'Remove the whole project after a confirmation. Pressing opens the dialog — choose Cancel to keep the project and reveal the last step.'**
  String get tourEdDeleteBody;

  /// Tour: editor focus-mode step title
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get tourEdFocusTitle;

  /// Tour: editor focus-mode step body
  ///
  /// In en, this message translates to:
  /// **'Hide all chrome for distraction-free editing. Pressing enters focus mode — use the exit button in the slim bar to return.'**
  String get tourEdFocusBody;

  /// Tour: runtime search step title
  ///
  /// In en, this message translates to:
  /// **'Find a runtime'**
  String get tourRtSearchTitle;

  /// Tour: runtime search step body
  ///
  /// In en, this message translates to:
  /// **'Type here to filter the runtime list. Safe to try — it only filters, nothing is installed.'**
  String get tourRtSearchBody;

  /// Tour: runtime bootstrap-setup step title
  ///
  /// In en, this message translates to:
  /// **'Bootstrap setup'**
  String get tourRtSetupTitle;

  /// Tour: runtime bootstrap-setup step body
  ///
  /// In en, this message translates to:
  /// **'Start Setup downloads the Linux bootstrap. Tap it for real only when you are ready to download.'**
  String get tourRtSetupBody;

  /// Tour: runtime install step title
  ///
  /// In en, this message translates to:
  /// **'Install a runtime'**
  String get tourRtInstallTitle;

  /// Tour: runtime install step body
  ///
  /// In en, this message translates to:
  /// **'This Install button starts a REAL download and install. Press it for real only if you want that runtime now — it is last for a reason.'**
  String get tourRtInstallBody;

  /// Tour: terminal paste step title
  ///
  /// In en, this message translates to:
  /// **'Paste into terminal'**
  String get tourTermPasteTitle;

  /// Tour: terminal paste step body
  ///
  /// In en, this message translates to:
  /// **'Pastes clipboard text into the shell. A real press, but harmless — it types without pressing Enter.'**
  String get tourTermPasteBody;

  /// Tour: terminal Tab-key step title
  ///
  /// In en, this message translates to:
  /// **'Tab key'**
  String get tourTermTabTitle;

  /// Tour: terminal Tab-key step body
  ///
  /// In en, this message translates to:
  /// **'Sends Tab for shell autocomplete. A real press, harmless.'**
  String get tourTermTabBody;

  /// Tour: terminal Ctrl+C step title
  ///
  /// In en, this message translates to:
  /// **'Ctrl+C key'**
  String get tourTermCtrlCTitle;

  /// Tour: terminal Ctrl+C step body
  ///
  /// In en, this message translates to:
  /// **'Sends an interrupt (Ctrl+C). Harmless on an empty prompt; it would cancel a running command.'**
  String get tourTermCtrlCBody;

  /// Tour: terminal new-tab step title
  ///
  /// In en, this message translates to:
  /// **'New terminal tab'**
  String get tourTermNewTabTitle;

  /// Tour: terminal new-tab step body
  ///
  /// In en, this message translates to:
  /// **'Opens a real new shell tab (up to 5). Harmless — close it with the × on its chip. Last because it changes the tab strip.'**
  String get tourTermNewTabBody;

  /// Tour: settings account step title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tourSetAccountTitle;

  /// Tour: settings account step body
  ///
  /// In en, this message translates to:
  /// **'Your sign-in status and account actions live here.'**
  String get tourSetAccountBody;

  /// Tour: settings language step title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get tourSetLangTitle;

  /// Tour: settings language step body
  ///
  /// In en, this message translates to:
  /// **'Switch the app language here. A real press takes effect immediately.'**
  String get tourSetLangBody;

  /// Tour: settings AI-key step title
  ///
  /// In en, this message translates to:
  /// **'AI API key'**
  String get tourSetAiKeyTitle;

  /// Tour: settings AI-key step body
  ///
  /// In en, this message translates to:
  /// **'Paste your AI provider key here. It stays in secure storage and is never shown again.'**
  String get tourSetAiKeyBody;

  /// Tour: settings save step title
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get tourSetSaveTitle;

  /// Tour: settings save step body
  ///
  /// In en, this message translates to:
  /// **'Saves everything on this page for real. Harmless — you can change it back any time. Last for that reason.'**
  String get tourSetSaveBody;

  /// Tour: git refresh-status step title
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get tourGitStatusTitle;

  /// Tour: git refresh-status step body
  ///
  /// In en, this message translates to:
  /// **'Reloads git status for the current project. A real reload, harmless.'**
  String get tourGitStatusBody;

  /// Tour: git commit step title
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get tourGitCommitTitle;

  /// Tour: git commit step body
  ///
  /// In en, this message translates to:
  /// **'Opens the commit message prompt. You can cancel — nothing is committed until you confirm. Last for that reason.'**
  String get tourGitCommitBody;

  /// Tour: notifications mark-read step title
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get tourNotifMarkReadTitle;

  /// Tour: notifications mark-read step body
  ///
  /// In en, this message translates to:
  /// **'Marks every notification read. Real but harmless — entries stay, only the unread dots clear.'**
  String get tourNotifMarkReadBody;

  /// Tour: replay-tour action title
  ///
  /// In en, this message translates to:
  /// **'Replay guided tour'**
  String get tourReplay;

  /// Tour: tours-reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Tours reset — tap ? on any screen'**
  String get tourResetDone;

  /// Tour: editor new-project step title
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get tourEdNewProjectTitle;

  /// Tour: editor new-project step body
  ///
  /// In en, this message translates to:
  /// **'Create another project from a template. Read-only during the tour — try it yourself afterwards from this same button.'**
  String get tourEdNewProjectBody;

  /// Tour: editor terminal-tab step title
  ///
  /// In en, this message translates to:
  /// **'Terminal drawer'**
  String get tourEdTermTabTitle;

  /// Tour: editor terminal-tab step body
  ///
  /// In en, this message translates to:
  /// **'Switch the bottom drawer to the embedded terminal. A real press — the shell session stays alive when you switch away.'**
  String get tourEdTermTabBody;

  /// Tour: editor git-tab step title
  ///
  /// In en, this message translates to:
  /// **'Git drawer'**
  String get tourEdGitTabTitle;

  /// Tour: editor git-tab step body
  ///
  /// In en, this message translates to:
  /// **'Switch the bottom drawer to Git: status, stage, commit and branches for this project.'**
  String get tourEdGitTabBody;

  /// Tour: editor processes-tab step title
  ///
  /// In en, this message translates to:
  /// **'Processes drawer'**
  String get tourEdProcTabTitle;

  /// Tour: editor processes-tab step body
  ///
  /// In en, this message translates to:
  /// **'Switch the bottom drawer to Processes: every running command with its output and a stop button.'**
  String get tourEdProcTabBody;

  /// Tour: editor tools-hide step title
  ///
  /// In en, this message translates to:
  /// **'Hide the tools'**
  String get tourEdToolsTitle;

  /// Tour: editor tools-hide step body
  ///
  /// In en, this message translates to:
  /// **'Collapse the whole bottom drawer for maximum editor height. Pressing hides it now — bring it back with the thin grabber strip, or tap Next.'**
  String get tourEdToolsBody;

  /// Tour: editor toolbar-hide step title
  ///
  /// In en, this message translates to:
  /// **'Hide the toolbar'**
  String get tourEdToolbarTitle;

  /// Tour: editor toolbar-hide step body
  ///
  /// In en, this message translates to:
  /// **'Collapse the top bar into a 28px strip. Pressing hides it now — restore it with the expand button in the strip, then take the last step.'**
  String get tourEdToolbarBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'ru',
    'zh',
  ].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
