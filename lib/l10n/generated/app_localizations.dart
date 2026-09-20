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
  /// **'Packages & SDK'**
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
