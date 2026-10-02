// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get searchEmpty => 'لا نتائج';

  @override
  String get searchPrompt => 'ابحث في المشروع النشط أعلاه';

  @override
  String get commandPaletteEmpty => 'لا نتائج';

  @override
  String get navProjects => 'المشاريع';

  @override
  String get navEditor => 'المحرر';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get actionOpen => 'فتح';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionRestore => 'استعادة';

  @override
  String get actionDiscard => 'تجاهل';

  @override
  String get actionSearch => 'بحث';

  @override
  String get actionImport => 'استيراد';

  @override
  String get actionExport => 'تصدير';

  @override
  String get actionCopy => 'نسخ';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get projectsWorkspaceStats => 'إحصاءات مساحة العمل';

  @override
  String get projectsOpenFolder => 'فتح مجلد';

  @override
  String get projectsOpenFile => 'فتح ملف';

  @override
  String get projectsCloneGit => 'استنساخ مستودع git';

  @override
  String get projectsNewProject => 'مشروع جديد';

  @override
  String get projectsRecentProjects => 'المشاريع الأخيرة';

  @override
  String get projectsRecentFiles => 'الملفات الأخيرة';

  @override
  String get projectsTipsTitle => 'تلميحات';

  @override
  String get projectsTipOrganize =>
      'احتفظ بمجلد واحد لكل مشروع للتنقل بشكل أسرع.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsEditor => 'المحرر';

  @override
  String settingsFontSize(String size) {
    return 'حجم الخط: $size';
  }

  @override
  String get settingsAi => 'الذكاء الاصطناعي';

  @override
  String get settingsTimeout => 'المهلة';

  @override
  String get themeNovaDark => 'نوفا الداكنة';

  @override
  String get themeNovaLight => 'نوفا الفاتحة';

  @override
  String get actionRun => 'تشغيل';

  @override
  String get actionStop => 'إيقاف';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionRename => 'إعادة تسمية';

  @override
  String get actionInstall => 'تثبيت';

  @override
  String get actionUpdate => 'تحديث';

  @override
  String get actionUninstall => 'إلغاء التثبيت';

  @override
  String commonError(String error) {
    return 'خطأ: $error';
  }

  @override
  String commonCreateFailed(String error) {
    return 'فشل الإنشاء: $error';
  }

  @override
  String commonDeleteFailed(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String commonRenameFailed(String error) {
    return 'فشل إعادة التسمية: $error';
  }

  @override
  String get projectsProjectNameHint => 'اسم المشروع';

  @override
  String get projectsDeleteTitle => 'حذف المشروع؟';

  @override
  String projectsDeleteMessage(String name) {
    return 'حذف \'$name\' وجميع ملفاته؟';
  }

  @override
  String get projectsSearchHint => 'ابحث في المشاريع...';

  @override
  String get projectsStatusUnavailable => 'حالة بيئة التشغيل غير متوفرة';

  @override
  String get projectsSetupNeeded => 'يلزم إعداد بيئة التشغيل';

  @override
  String get projectsRuntimeReady => 'بيئة التشغيل جاهزة';

  @override
  String get projectsOpenEditor => 'فتح المحرر';

  @override
  String get projectsDeleteProject => 'حذف المشروع';

  @override
  String get projectsEmptyTitle => 'لا توجد مشاريع بعد';

  @override
  String get projectsTipsBody =>
      'انقر على مشروع لفتحه في المحرر. استخدم تبويب الحزم لتثبيت بيئات التشغيل قبل إنشاء مشاريع Node أو Python.';

  @override
  String get editorEmptyHint => 'افتح ملفًا من المستكشف';

  @override
  String editorSaveFailed(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String editorSaved(String name) {
    return 'تم حفظ $name';
  }

  @override
  String editorOpenFailed(String error) {
    return 'تعذر فتح الملف: $error';
  }

  @override
  String get explorerNewFile => 'ملف جديد';

  @override
  String get explorerNewNameHint => 'اسم جديد';

  @override
  String get explorerDeleteTitle => 'حذف؟';

  @override
  String explorerDeleteMessage(String name) {
    return 'حذف $name؟';
  }

  @override
  String get explorerSelectProject => 'اختر مشروعًا';

  @override
  String get explorerEmptyFolder => 'مجلد فارغ';

  @override
  String runStartFailed(String error) {
    return 'فشل بدء المهمة: $error';
  }

  @override
  String get runNoTasks => 'لم يتم اكتشاف مهام';

  @override
  String get runHideConsole => 'إخفاء وحدة التحكم';

  @override
  String get runShowConsole => 'إظهار وحدة التحكم';

  @override
  String get runEmptyHint =>
      'اضغط تشغيل لتنفيذ المهمة المحددة. ستظهر المخرجات هنا.';

  @override
  String get gitTitle => 'جيت';

  @override
  String get gitCommit => 'اعتماد';

  @override
  String get gitCommitMessage => 'رسالة الاعتماد';

  @override
  String get gitCommitted => 'تم الاعتماد';

  @override
  String gitCommitFailed(String error) {
    return 'فشل الاعتماد: $error';
  }

  @override
  String get gitStageAll => 'تجهيز الكل';

  @override
  String get gitStagedAll => 'تم تجهيز كل التغييرات';

  @override
  String gitStageFailed(String error) {
    return 'فشل التجهيز: $error';
  }

  @override
  String get gitStage => 'تجهيز';

  @override
  String gitStagedFile(String file) {
    return 'تم تجهيز $file';
  }

  @override
  String get gitBranches => 'الفروع';

  @override
  String get gitCheckout => 'تبديل';

  @override
  String get gitCreateBranch => 'فرع جديد';

  @override
  String get gitBranchNameHint => 'اسم الفرع';

  @override
  String gitDeleteBranchConfirm(String name) {
    return 'حذف الفرع «$name»؟';
  }

  @override
  String gitBranchActionFailed(String error) {
    return 'فشل إجراء الفرع: $error';
  }

  @override
  String get gitNoBranches => '(لا توجد فروع)';

  @override
  String get gitStash => 'التخزين المؤقت';

  @override
  String get gitStashSave => 'تخزين التغييرات';

  @override
  String get gitStashMessage => 'رسالة التخزين';

  @override
  String get gitStashed => 'تم تخزين التغييرات';

  @override
  String gitStashActionFailed(String error) {
    return 'فشل إجراء التخزين: $error';
  }

  @override
  String get gitRemote => 'البعيد (SSH)';

  @override
  String get gitClone => 'استنساخ';

  @override
  String get gitCloneUrl => 'رابط المستودع (SSH)';

  @override
  String get gitCloneDir => 'مجلد الوجهة';

  @override
  String get gitCloned => 'تم الاستنساخ بنجاح';

  @override
  String get gitFetch => 'جلب';

  @override
  String get gitFetched => 'تم الجلب';

  @override
  String get gitPull => 'سحب';

  @override
  String get gitPulled => 'تم السحب';

  @override
  String get gitPush => 'دفع';

  @override
  String get gitPushed => 'تم الدفع';

  @override
  String gitRemoteFailed(String error) {
    return 'فشلت العملية البعيدة: $error';
  }

  @override
  String get gitSshKey => 'مفتاح SSH العام للتطبيق';

  @override
  String get gitSshNoKey =>
      'لا يوجد مفتاح بعد — ولّد واحدًا ثم أضفه إلى حساب الاستضافة.';

  @override
  String get gitSshGenerate => 'توليد مفتاح';

  @override
  String get gitSshCopy => 'نسخ';

  @override
  String get gitSshCopied =>
      'تم نسخ المفتاح العام — أضفه ضمن مفاتيح SSH في حسابك';

  @override
  String get gitStashEmpty => '(لا توجد تغييرات مخزنة)';

  @override
  String get gitStashPop => 'استعادة';

  @override
  String get gitStashDrop => 'إسقاط';

  @override
  String get terminalTitle => 'الطرفية';

  @override
  String get terminalNewSession => 'جلسة جديدة';

  @override
  String get terminalStartFailed => 'فشل بدء جلسة الطرفية';

  @override
  String get processTitle => 'العمليات';

  @override
  String get processRunHint => 'تشغيل أمر… مثل: npm run dev';

  @override
  String get processEmpty =>
      'لا توجد عمليات قيد التشغيل.\nابدأ مهمة لتظهر هنا.';

  @override
  String get runtimeTitle => 'بيئة التشغيل';

  @override
  String get runtimeBootstrap => 'بوتستراب';

  @override
  String get runtimeStartSetup => 'بدء الإعداد';

  @override
  String get runtimeInstalled => 'مثبّت';

  @override
  String get runtimeAvailable => 'متوفر';

  @override
  String runtimeUninstallConfirm(String name) {
    return 'إلغاء تثبيت $name؟';
  }

  @override
  String get runtimeEmpty => 'لا توجد بيئات تشغيل متوفرة.';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeFollowSystem => 'اتباع النظام';

  @override
  String get toolsShow => 'إظهار الأدوات';

  @override
  String get toolsHide => 'إخفاء الأدوات';

  @override
  String get toolbarShow => 'إظهار الشريط';

  @override
  String get toolbarHide => 'إخفاء الشريط';

  @override
  String get explorerShow => 'إظهار المستكشف';

  @override
  String get explorerHide => 'إخفاء المستكشف';

  @override
  String get projectNew => 'مشروع جديد';

  @override
  String get projectNameHint => 'اسم المشروع';

  @override
  String get projectDelete => 'حذف المشروع';

  @override
  String get projectDeleteTitle => 'حذف المشروع؟';

  @override
  String projectDeleteBody(String name) {
    return 'حذف «$name» وكل ملفاته؟';
  }

  @override
  String get workspaceEmpty => 'لا توجد مشاريع بعد';

  @override
  String get workspaceTitle => 'مساحة العمل';

  @override
  String get toolTerminal => 'الطرفية';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => 'العمليات';

  @override
  String get projectSelect => 'اختر المشروع';

  @override
  String get projectsHintTemplate => 'ابدأ من قالب';

  @override
  String get projectsHintContinue => 'مواصلة العمل';

  @override
  String get projectsHintReload => 'إعادة تحميل قائمة المشاريع';

  @override
  String get projectsHintRemoveActive => 'إزالة المشروع النشط';

  @override
  String projectsFilterAll(int count) {
    return 'الكل ($count)';
  }

  @override
  String projectsCount(int count) {
    return '$count مشاريع';
  }

  @override
  String get editorEdit => 'تحرير';

  @override
  String get editorPreview => 'معاينة';

  @override
  String get editorTabActions => 'إجراءات التبويب';

  @override
  String get editorReloadConfirmTitle => 'إعادة تحميل الملف؟';

  @override
  String get editorReloadConfirmBody =>
      'تجاهل التغييرات غير المحفوظة وإعادة التحميل من القرص؟';

  @override
  String editorReloaded(String name) {
    return 'تمت إعادة تحميل $name';
  }

  @override
  String get editorRecoverTitle => 'تم العثور على تغييرات غير محفوظة';

  @override
  String editorRecoverBody(String name) {
    return 'استعادة التغييرات غير المحفوظة لـ $name؟';
  }

  @override
  String get editorCloseDirtyTitle => 'إغلاق بدون حفظ؟';

  @override
  String editorCloseDirtyBody(String name) {
    return 'تجاهل التغييرات غير المحفوظة في $name؟';
  }

  @override
  String get editorFocusEnter => 'وضع التركيز';

  @override
  String get editorFocusExit => 'خروج من وضع التركيز';

  @override
  String get explorerTitle => 'المستكشف';

  @override
  String get explorerGoUp => 'انتقل للأعلى';

  @override
  String get runClearOutput => 'مسح المخرجات';

  @override
  String get runStartingProcess => 'جارٍ بدء العملية…';

  @override
  String get gitProject => 'المشروع';

  @override
  String get gitOpenProject => 'فتح مشروع';

  @override
  String get gitSelectProject => 'اختر المشروع';

  @override
  String get gitProjectPath => 'مسار المشروع';

  @override
  String get gitStatus => 'الحالة';

  @override
  String get gitDiff => 'الفرق';

  @override
  String get gitUnavailable => 'جيت غير متوفر';

  @override
  String gitBranch(String branch) {
    return 'الفرع: $branch';
  }

  @override
  String get gitModified => 'معدّلة';

  @override
  String get gitAdded => 'مضافة';

  @override
  String get gitDeleted => 'محذوفة';

  @override
  String get gitUntracked => 'غير متتبعة';

  @override
  String get gitEmptyDiff => '(لا توجد فروقات)';

  @override
  String get terminalPaste => 'لصق';

  @override
  String terminalSessionExited(int code) {
    return 'انتهت الجلسة (الرمز $code)';
  }

  @override
  String get terminalKeyTab => 'تاب';

  @override
  String get terminalKeyEsc => 'خروج';

  @override
  String get terminalKeyUp => 'أعلى';

  @override
  String get terminalKeyDown => 'أسفل';

  @override
  String get terminalKeyLeft => 'يسار';

  @override
  String get terminalKeyRight => 'يمين';

  @override
  String processStarted(String pid, String command) {
    return 'تم بدء $pid · $command';
  }

  @override
  String get processStartedByNova => 'بدأ بواسطة نوفا';

  @override
  String get runtimeReady => 'جاهز';

  @override
  String get runtimeBootstrapReady =>
      'البوتستراب جاهز. يمكن تثبيت الحزم أدناه.';

  @override
  String get bootstrapRequired => 'البيئة الأساسية مطلوبة';

  @override
  String get bootstrapRequiredBody =>
      'بيئة لينكس غير مثبتة. حمّلها الآن لاستخدام الطرفية وحزم اللغات؟';

  @override
  String get actionDownload => 'تنزيل';

  @override
  String get actionLater => 'لاحقًا';

  @override
  String get runtimeBootstrapUnavailable => 'حالة البوتستراب غير متوفرة.';

  @override
  String get runtimeBootstrapNotInstalled => 'لم يتم تثبيت البوتستراب بعد.';

  @override
  String runtimeVersion(String version) {
    return 'الإصدار: $version';
  }

  @override
  String get runtimeSetupFailed => 'فشل الإعداد';

  @override
  String get aiTitle => 'إجراءات الذكاء الاصطناعي';

  @override
  String get aiKeySaved => 'تم حفظ المفتاح';

  @override
  String get aiEnterKeyFirst => 'أدخل مفتاح API أولا';

  @override
  String get aiNoCode => 'لا يوجد كود محدد';

  @override
  String get aiExplainCode => 'اشرح الكود';

  @override
  String get aiFixError => 'أصلح الخطأ';

  @override
  String get aiCompleteCode => 'أكمل الكود';

  @override
  String get aiStop => 'إيقاف';

  @override
  String get aiInsert => 'إدراج في المحرر';

  @override
  String aiPromptExplain(String code) {
    return 'اشرح الكود التالي:\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return 'أصلح الخطأ في الكود التالي:\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return 'أكمل الكود التالي:\n$code';
  }

  @override
  String get settingsSystem => 'النظام';

  @override
  String settingsRunTimeout(int ms) {
    return 'مهلة التشغيل: $ms مللي ثانية';
  }

  @override
  String get settingsTimeoutLabel => 'المهلة (مللي ثانية، 1000-120000)';

  @override
  String get settingsAutocomplete => 'الإكمال التلقائي';

  @override
  String get settingsAutocompleteSub =>
      'اقتراحات الكلمات والمقاطع أثناء الكتابة';

  @override
  String get settingsAiCompletion => 'الإكمال بالذكاء الاصطناعي';

  @override
  String get settingsAiCompletionSub => 'اقتراحات النموذج في قائمة الإكمال';

  @override
  String get settingsMatchTheme => 'مطابقة التطبيق مع سمة المحرر';

  @override
  String get settingsMatchThemeSub => 'التطبيق كله يتبع ألوان سمة المحرر';

  @override
  String get settingsWordWrap => 'التفاف الأسطر';

  @override
  String get settingsWordWrapSub => 'التفاف الأسطر الطويلة بدل التمرير الجانبي';

  @override
  String get settingsAutoSave => 'الحفظ التلقائي';

  @override
  String get settingsAutoSaveSub => 'الحفظ بعد 1.5 ثانية من توقف الكتابة';

  @override
  String get settingsEditorFont => 'خط المحرر';

  @override
  String get settingsFontInstalled => 'تم تثبيت الخط';

  @override
  String get settingsFontUpdated => 'تم تحديث خط المحرر';

  @override
  String get settingsDownloadFailed => 'فشل التنزيل: تحقق من الاتصال';

  @override
  String get settingsLivePreview => 'معاينة حية';

  @override
  String get settingsProvider => 'المزود';

  @override
  String get settingsCustomProvider => 'مخصص (متوافق مع OpenAI)';

  @override
  String get settingsBaseUrl => 'الرابط الأساسي (متوافق مع OpenAI)';

  @override
  String get settingsModel => 'النموذج';

  @override
  String get settingsApiKey => 'مفتاح API';

  @override
  String get settingsApiKeySaved => 'محفوظ في التخزين الآمن';

  @override
  String get settingsApiKeyHint => 'الصق مفتاحك';

  @override
  String get settingsKeySecureNote =>
      'المفتاح يُحفظ في تخزين آمن مشفر، وليس في الإعدادات العادية.';

  @override
  String get settingsTestConnection => 'اختبار الاتصال';

  @override
  String get settingsTesting => 'جارٍ الاختبار…';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String settingsConnected(String reply) {
    return 'متصل: $reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return 'فشل الاتصال: $error';
  }

  @override
  String settingsThemeImported(String name) {
    return 'تم استيراد السمة «$name»';
  }

  @override
  String settingsImportFailed(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String settingsThemeCopied(String name) {
    return 'تم نسخ JSON للسمة «$name»';
  }

  @override
  String settingsThemeExported(String name) {
    return 'تم تصدير السمة «$name» إلى الحافظة';
  }

  @override
  String get settingsImportTheme => 'استيراد JSON لسمة';

  @override
  String get settingsCopyTheme => 'نسخ JSON للسمة';

  @override
  String get settingsExportTheme => 'تصدير السمة';

  @override
  String get settingsDeleteTheme => 'حذف السمة';

  @override
  String get searchTitle => 'البحث في المشروع';

  @override
  String get searchHint => 'ابحث عن نص أو نمط…';

  @override
  String get searchReplaceHint => 'استبدل بـ…';

  @override
  String get searchMatchCase => 'مطابقة حالة الأحرف';

  @override
  String get searchUseRegex => 'استخدام التعبيرات النمطية';

  @override
  String get searchButton => 'بحث';

  @override
  String searchButtonCount(int hits) {
    return 'بحث ($hits)';
  }

  @override
  String get searchReplaceAll => 'استبدال الكل';

  @override
  String get searchNoProject => 'لا يوجد مشروع مفتوح';

  @override
  String get searchTypeSomething => 'اكتب شيئًا للبحث عنه';

  @override
  String get searchInvalidRegex => 'تعبير نمطي غير صالح';

  @override
  String searchFailed(String error) {
    return 'فشل البحث: $error';
  }

  @override
  String get searchEmptyHint => 'ابحث في المشروع النشط أعلاه';

  @override
  String get searchNoMatches => 'لا توجد نتائج';

  @override
  String get searchTruncated => 'تُعرض أول النتائج فقط (تم بلوغ الحد)';

  @override
  String searchReplaceCount(int count) {
    return 'استبدال ($count)';
  }

  @override
  String get searchUnsavedTitle => 'تغييرات غير محفوظة';

  @override
  String searchUnsavedBody(String names) {
    return 'هذه التبويبات المفتوحة بها تعديلات غير محفوظة سيتجاوزها الاستبدال: $names. استبدال على أي حال؟';
  }

  @override
  String get searchReplaceAnyway => 'استبدال على أي حال';

  @override
  String get searchNoMatchesReplace => 'لا توجد نتائج للاستبدال';

  @override
  String searchReplaced(int total, int files) {
    return 'تم استبدال $total في $files ملفات. أعد فتح التبويبات المتأثرة للتحميل.';
  }

  @override
  String searchReplaceFailed(String error) {
    return 'فشل الاستبدال: $error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return 'لا توجد نتائج في $name';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return 'تم استبدال $count في $name. أعد فتح التبويب للتحميل.';
  }

  @override
  String get editorFindInFile => 'بحث في الملف';

  @override
  String get editorGoToDefinition => 'الذهاب إلى التعريف';

  @override
  String get editorNoSymbolAtCaret => 'ضع المؤشر على رمز أولًا';

  @override
  String editorDefinitionNotFound(String name) {
    return 'لم يتم العثور على تعريف \'$name\'';
  }

  @override
  String get editorFindHint => 'بحث';

  @override
  String get editorPrevMatch => 'النتيجة السابقة';

  @override
  String get editorNextMatch => 'النتيجة التالية';

  @override
  String get editorMatchCase => 'مطابقة حالة الأحرف';

  @override
  String get editorUseRegex => 'استخدام التعبيرات النمطية';

  @override
  String get editorCloseFind => 'إغلاق شريط البحث';

  @override
  String explorerStorageError(String error) {
    return 'التخزين غير قابل للكتابة هنا: $error';
  }

  @override
  String get explorerNewFileHint => 'مثال: main.py';

  @override
  String get explorerNoFolder => 'لم يتم اختيار مجلد';

  @override
  String get mdUndo => 'تراجع';

  @override
  String get mdRedo => 'إعادة';

  @override
  String get mdBold => 'عريض';

  @override
  String get mdItalic => 'مائل';

  @override
  String get mdUnderline => 'تحته خط';

  @override
  String get mdStrike => 'يتوسطه خط';

  @override
  String get mdInlineCode => 'كود مضمن';

  @override
  String get mdH1 => 'عنوان 1';

  @override
  String get mdH2 => 'عنوان 2';

  @override
  String get mdH3 => 'عنوان 3';

  @override
  String get mdBulleted => 'قائمة نقطية';

  @override
  String get mdNumbered => 'قائمة مرقمة';

  @override
  String get mdQuote => 'اقتباس';

  @override
  String get mdCodeBlock => 'كتلة كود';

  @override
  String get terminalMaxTabs => 'تم بلوغ الحد الأقصى (5 تبويبات طرفية)';

  @override
  String get paletteHint => 'اكتب أمرًا أو اسم ملف…';

  @override
  String get paletteNoMatches => 'لا توجد نتائج';

  @override
  String get paletteToggleRun => 'تبديل لوحة التشغيل';

  @override
  String get paletteToggleTerminal => 'تبديل الطرفية';

  @override
  String get paletteToggleGit => 'تبديل لوحة Git';

  @override
  String get paletteToggleProcesses => 'تبديل لوحة العمليات';

  @override
  String get paletteSwitchTheme => 'تبديل سمة المحرر';

  @override
  String get paletteSearchInProject => 'البحث في المشروع';

  @override
  String get paletteOpenSettings => 'فتح الإعدادات';

  @override
  String get paletteTitle => 'لوحة الأوامر';

  @override
  String get projectGeneral => 'عام';

  @override
  String get projectGeneralSub => 'بدون بيئة مفترضة — يُكتشف اللغة تلقائيًا';

  @override
  String runtimeInstalledOk(String name) {
    return 'تم تثبيت $name بنجاح ✅';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return 'فشل تثبيت $name: $error';
  }

  @override
  String runtimeStartInstall(String name) {
    return 'بدء تثبيت $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return 'فشل بدء التثبيت: $error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return 'بدء تحديث $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return 'فشل بدء التحديث: $error';
  }

  @override
  String runtimeRemoving(String name) {
    return 'إزالة $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return 'فشل الإزالة: $error';
  }

  @override
  String get runtimeChooseVariant =>
      'اختر نسخة نظام لينكس (تُحمَّل من الإنترنت لمرة واحدة):';

  @override
  String get runtimeVariantSlim => 'خفيفة ~70MB (موصى بها)';

  @override
  String get runtimeVariantSlimSub =>
      'الأساسيات + apt — واللغات تُثبَّت عند الحاجة';

  @override
  String get runtimeVariantFull => 'كاملة ~283MB';

  @override
  String get runtimeVariantFullSub =>
      'node وpython وphp وgit مثبتة مسبقًا — تعمل دون إنترنت';

  @override
  String get runtimeNoResults => 'لا نتائج مطابقة للبحث';

  @override
  String get runtimeSearchHint => 'بحث عن لغة أو أداة...';

  @override
  String get runtimeClear => 'مسح';

  @override
  String get runtimeUnsupported => 'غير مدعوم على هذا الجهاز';

  @override
  String runtimeInstalledSection(int count) {
    return 'المثبتة ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return 'الحزم الجاهزة ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return 'لغات البرمجة ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return 'الأدوات ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return 'جاري تنفيذ: $name';
  }

  @override
  String runtimeLastOp(String name) {
    return 'آخر عملية: $name';
  }

  @override
  String get runtimeLogTitle => 'سجل العمليات';

  @override
  String runtimeLines(int count) {
    return '$count سطر';
  }

  @override
  String get runtimeDone => 'اكتمل';

  @override
  String get runtimeStatusUpdating => 'تحديث قوائم الحزم...';

  @override
  String get runtimeStatusInstalling => 'بدء التثبيت...';

  @override
  String get runtimeStatusReading => 'قراءة قوائم الحزم...';

  @override
  String get runtimeStatusDeps => 'بناء شجرة الاعتماديات...';

  @override
  String get runtimeStatusUnpacking => 'فك الحزم...';

  @override
  String get runtimeStatusSettingUp => 'إعداد الحزم...';

  @override
  String runtimeWorkingOn(String name) {
    return 'جاري العمل على $name...';
  }

  @override
  String get setupSlimTitle => 'خفيفة ~80MB (افتراضي)';

  @override
  String get setupSlimSub => 'الأساسيات + apt — واللغات تُثبَّت عند الحاجة';

  @override
  String get setupFullTitle => 'كاملة ~283MB (دون إنترنت)';

  @override
  String get setupFullSub => 'node وpython وphp وgit مثبتة مسبقًا';

  @override
  String get setupResumeNote =>
      'إعادة المحاولة تعيد استخدام التنزيل المتحقق منه (استئناف).';

  @override
  String get setupSources => 'مصادر التنزيل:';

  @override
  String get setupSourceOk => 'متاح';

  @override
  String get setupSourceDown => 'غير متاح — تحقق من الاتصال';

  @override
  String get webPreviewTitle => 'معاينة الويب';

  @override
  String get runtimeDescPhp => 'لغة الويب — Laravel وWordPress';

  @override
  String get runtimeDescNode => 'JavaScript وTypeScript — npm مدمجة';

  @override
  String get runtimeDescPython => 'سكربتات وبيانات — pip مدمجة';

  @override
  String get runtimeDescGo => 'لغة Go المترجمة — سريعة وخفيفة';

  @override
  String get runtimeDescRust => 'لغة Rust — أمان الذاكرة والأداء';

  @override
  String get runtimeDescRuby => 'لغة Ruby للسكربتات والويب';

  @override
  String get runtimeDescJava => 'Java 25 — منصة JVM كاملة';

  @override
  String get runtimeDescKotlin => 'Kotlin — تعمل على JVM (تحتاج Java)';

  @override
  String get runtimeDescDart => 'Dart — تطبيقات وأدوات سطر أوامر';

  @override
  String get runtimeDescC => 'لغة C وC++ — مترجم Clang السريع';

  @override
  String get runtimeDescGit => 'إدارة الإصدارات والمستودعات';

  @override
  String get runtimeDescComposer => 'مدير حزم PHP';

  @override
  String get runtimeDescNovaWeb =>
      'PHP + Composer + Ruby + Node.js — تطوير الويب';

  @override
  String get runtimeDescNovaSystems =>
      'Rust + Go + make + cmake — لغات الأنظمة';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin — منصة JVM';

  @override
  String get runtimeDescNovaPython => 'Python + pip — سكربتات وبيانات';

  @override
  String get runtimeDescNovaDart => 'Dart — أدوات سطر الأوامر';

  @override
  String get splashTagline => 'بيئة التطوير في جيبك';

  @override
  String get splashStatusEngine => 'تهيئة المحرك…';

  @override
  String get splashStatusSettings => 'تحميل الإعدادات…';

  @override
  String get splashStatusRuntime => 'فحص بيئة التشغيل…';

  @override
  String get splashStatusWorkspace => 'تجهيز مساحة العمل…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • الإصدار $version (بناء $build)';
  }

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String appVersionBuild(String version, String build) {
    return 'الإصدار $version (بناء $build)';
  }

  @override
  String get aboutTitle => 'عنا والاتصال بنا';

  @override
  String get aboutTagline => 'بيئة التطوير في جيبك';

  @override
  String get aboutSectionAbout => 'عن نوفا';

  @override
  String get aboutDescription =>
      'نوفا محرر كود يشتغل على موبايلك الأندرويد، ويشغّل الكود فعليًا على الجهاز نفسه — بايثون، جافاسكربت، PHP، ‏Go، ‏Rust، ‏Ruby، ‏Java، ‏Kotlin، ‏Dart، ‏C/C++ — مع تيرمينال حقيقي، Git، ومعاينة ويب. لا سيرفر خارجي، لا محاكاة: تكتب، تضغط تشغيل، وتشوف النتيجة.';

  @override
  String get aboutSectionDownload => 'التحميل';

  @override
  String get aboutPlayTitle => 'Google Play';

  @override
  String get aboutPlaySub =>
      'التثبيت الأسهل لمعظم المستخدمين، مع تحديثات عبر متجر Play';

  @override
  String get aboutGithubTitle => 'إصدارات GitHub';

  @override
  String get aboutGithubSub => 'ملفات APK مباشرة من صفحة إصدارات المشروع';

  @override
  String get aboutVersionsTitle => 'أي نسخة أختار؟';

  @override
  String get aboutVersionsBody =>
      'نسخة GitHub تستهدف Android API 28 مع تشغيل مباشر — مسار الشحن الحالي حيث تعمل بيئة لينكس المضمّنة بكامل قوتها. نسخة Play تستهدف API 36 وتشغّل عبر الـ linker التزامًا بسياسات متجر Play الحالية. نفس المحرر والميزات؛ الفرق فقط في طريقة إطلاق بيئة التشغيل.';

  @override
  String get aboutSectionProject => 'المشروع';

  @override
  String get aboutSourceCode => 'الكود المصدري';

  @override
  String get aboutReleases => 'الإصدارات';

  @override
  String get aboutPackageRepo => 'مستودع الحزم';

  @override
  String get aboutLicense => 'الرخصة: رخصة وقف العامة — الإصدار الأول';

  @override
  String get aboutLicenseSub =>
      'وقف لله تعالى — حر في الاستخدام والمشاركة والتعديل';

  @override
  String get aboutSectionContact => 'الاتصال بنا';

  @override
  String get aboutEmailUs => 'راسلنا عبر البريد';

  @override
  String get aboutEmailHint => 'للأسئلة والملاحظات والتبليغ عن الأخطاء';

  @override
  String get aboutCopied => 'تم النسخ';

  @override
  String get aboutOpenFailed => 'تعذّر فتح الرابط';
}
