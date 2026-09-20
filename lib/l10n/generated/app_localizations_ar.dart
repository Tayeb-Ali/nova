// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String get settingsFontSize => 'حجم الخط';

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
}
