// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get searchEmpty => 'Совпадений нет';

  @override
  String get searchPrompt => 'Поиск по активному проекту выше';

  @override
  String get commandPaletteEmpty => 'Совпадений нет';

  @override
  String get navProjects => 'Проекты';

  @override
  String get navEditor => 'Редактор';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => 'Настройки';

  @override
  String get actionOpen => 'Открыть';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionCreate => 'Создать';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionExit => 'Exit';

  @override
  String get appExitTitle => 'Exit Nova?';

  @override
  String get appExitBody => 'Press Exit to close the app.';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get actionRestore => 'Восстановить';

  @override
  String get actionDiscard => 'Отменить';

  @override
  String get actionSearch => 'Поиск';

  @override
  String get actionImport => 'Импорт';

  @override
  String get actionExport => 'Экспорт';

  @override
  String get actionCopy => 'Копировать';

  @override
  String get actionShare => 'Поделиться';

  @override
  String get projectsWorkspaceStats => 'Статистика рабочей области';

  @override
  String get projectsOpenFolder => 'Открыть папку';

  @override
  String get projectsOpenFile => 'Открыть файл';

  @override
  String get projectsCloneGit => 'Клонировать git-репозиторий';

  @override
  String get projectsNewProject => 'Новый проект';

  @override
  String get projectsRecentProjects => 'Недавние проекты';

  @override
  String get projectsRecentFiles => 'Недавние файлы';

  @override
  String get projectsTipsTitle => 'Советы';

  @override
  String get projectsTipOrganize =>
      'Держите один каталог на проект, чтобы быстрее переключаться.';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsEditor => 'Редактор';

  @override
  String settingsFontSize(String size) {
    return 'Размер шрифта: $size';
  }

  @override
  String get settingsAi => 'ИИ';

  @override
  String get settingsTimeout => 'Тайм-аут';

  @override
  String get themeNovaDark => 'Nova тёмная';

  @override
  String get themeNovaLight => 'Nova светлая';

  @override
  String get actionRun => 'Запустить';

  @override
  String get actionStop => 'Остановить';

  @override
  String get actionRefresh => 'Обновить';

  @override
  String get actionRename => 'Переименовать';

  @override
  String get actionInstall => 'Установить';

  @override
  String get actionUpdate => 'Обновить';

  @override
  String get actionUninstall => 'Удалить';

  @override
  String commonError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String commonCreateFailed(String error) {
    return 'Не удалось создать: $error';
  }

  @override
  String commonDeleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String commonRenameFailed(String error) {
    return 'Не удалось переименовать: $error';
  }

  @override
  String get projectsProjectNameHint => 'Название проекта';

  @override
  String get projectsDeleteTitle => 'Удалить проект?';

  @override
  String projectsDeleteMessage(String name) {
    return 'Удалить «$name» и все его файлы?';
  }

  @override
  String get projectsSearchHint => 'Поиск проектов...';

  @override
  String get projectsStatusUnavailable => 'Статус среды выполнения недоступен';

  @override
  String get projectsSetupNeeded => 'Требуется настройка среды выполнения';

  @override
  String get projectsRuntimeReady => 'Среда выполнения готова';

  @override
  String get projectsOpenEditor => 'Открыть редактор';

  @override
  String get projectsDeleteProject => 'Удалить проект';

  @override
  String get projectsEmptyTitle => 'Проектов пока нет';

  @override
  String get projectsTipsBody =>
      'Нажмите на проект, чтобы открыть его в редакторе. Воспользуйтесь вкладкой «Пакеты», чтобы установить среды выполнения перед созданием проектов Node или Python.';

  @override
  String get editorEmptyHint => 'Откройте файл из проводника';

  @override
  String editorSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String editorSaved(String name) {
    return 'Сохранено: $name';
  }

  @override
  String editorOpenFailed(String error) {
    return 'Не удалось открыть файл: $error';
  }

  @override
  String get explorerNewFile => 'Новый файл';

  @override
  String get explorerNewNameHint => 'Новое имя';

  @override
  String get explorerDeleteTitle => 'Удалить?';

  @override
  String explorerDeleteMessage(String name) {
    return 'Удалить $name?';
  }

  @override
  String get explorerSelectProject => 'Выберите проект';

  @override
  String get explorerEmptyFolder => 'Пустая папка';

  @override
  String runStartFailed(String error) {
    return 'Не удалось запустить задачу: $error';
  }

  @override
  String get runNoTasks => 'Задачи не обнаружены';

  @override
  String get runHideConsole => 'Скрыть консоль';

  @override
  String get runShowConsole => 'Показать консоль';

  @override
  String get runEmptyHint =>
      'Нажмите «Запустить», чтобы выполнить выбранную задачу. Вывод появится здесь.';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitCommitMessage => 'Сообщение commit';

  @override
  String get gitCommitted => 'Commit выполнен';

  @override
  String gitCommitFailed(String error) {
    return 'Commit не удался: $error';
  }

  @override
  String get gitStageAll => 'Индексировать всё';

  @override
  String get gitStagedAll => 'Все изменения проиндексированы';

  @override
  String gitStageFailed(String error) {
    return 'Не удалось проиндексировать: $error';
  }

  @override
  String get gitStage => 'Индексировать';

  @override
  String gitStagedFile(String file) {
    return 'Проиндексирован: $file';
  }

  @override
  String get gitBranches => 'Ветки';

  @override
  String get gitCheckout => 'Переключиться';

  @override
  String get gitCreateBranch => 'Новая ветка';

  @override
  String get gitBranchNameHint => 'Название ветки';

  @override
  String gitDeleteBranchConfirm(String name) {
    return 'Удалить ветку «$name»?';
  }

  @override
  String gitBranchActionFailed(String error) {
    return 'Операция с веткой не удалась: $error';
  }

  @override
  String get gitNoBranches => '(веток нет)';

  @override
  String get gitStash => 'Stash';

  @override
  String get gitStashSave => 'Отложить изменения';

  @override
  String get gitStashMessage => 'Сообщение stash';

  @override
  String get gitStashed => 'Изменения отложены';

  @override
  String gitStashActionFailed(String error) {
    return 'Операция stash не удалась: $error';
  }

  @override
  String get gitRemote => 'Удалённый репозиторий (SSH)';

  @override
  String get gitClone => 'Клонировать';

  @override
  String get gitCloneUrl => 'URL репозитория (SSH)';

  @override
  String get gitCloneDir => 'Целевой каталог';

  @override
  String get gitCloned => 'Успешно клонировано';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitFetched => 'Получено';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPulled => 'Извлечено';

  @override
  String get gitPush => 'Push';

  @override
  String get gitPushed => 'Отправлено';

  @override
  String gitRemoteFailed(String error) {
    return 'Операция с удалённым репозиторием не удалась: $error';
  }

  @override
  String get gitSshKey => 'Публичный SSH-ключ приложения';

  @override
  String get gitSshNoKey =>
      'Ключа пока нет — создайте его и добавьте в свой аккаунт хостинга.';

  @override
  String get gitSshGenerate => 'Создать ключ';

  @override
  String get gitSshCopy => 'Копировать';

  @override
  String get gitSshCopied =>
      'Публичный ключ скопирован — добавьте его в SSH-ключи своего аккаунта';

  @override
  String get gitStashEmpty => '(отложенных изменений нет)';

  @override
  String get gitStashPop => 'Вернуть';

  @override
  String get gitStashDrop => 'Удалить';

  @override
  String get terminalTitle => 'Терминал';

  @override
  String get terminalNewSession => 'Новый сеанс';

  @override
  String get terminalStartFailed => 'Не удалось запустить сеанс терминала';

  @override
  String get processTitle => 'Процессы';

  @override
  String get processRunHint => 'Команда для запуска… например, npm run dev';

  @override
  String get processEmpty =>
      'Нет запущенных процессов.\nЗапустите задачу, и она появится здесь.';

  @override
  String get runtimeTitle => 'Среда выполнения';

  @override
  String get runtimeBootstrap => 'Bootstrap';

  @override
  String get runtimeStartSetup => 'Начать настройку';

  @override
  String get runtimeInstalled => 'Установлено';

  @override
  String get runtimeAvailable => 'Доступно';

  @override
  String runtimeUninstallConfirm(String name) {
    return 'Удалить $name?';
  }

  @override
  String get runtimeEmpty => 'Нет доступных сред выполнения.';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeFollowSystem => 'Как в системе';

  @override
  String get toolsShow => 'Показать инструменты';

  @override
  String get toolsHide => 'Скрыть инструменты';

  @override
  String get toolbarShow => 'Показать панель инструментов';

  @override
  String get toolbarHide => 'Скрыть панель инструментов';

  @override
  String get explorerShow => 'Показать проводник';

  @override
  String get explorerHide => 'Скрыть проводник';

  @override
  String get projectNew => 'Новый проект';

  @override
  String get projectNameHint => 'Название проекта';

  @override
  String get projectDelete => 'Удалить проект';

  @override
  String get projectDeleteTitle => 'Удалить проект?';

  @override
  String projectDeleteBody(String name) {
    return 'Удалить «$name» и все его файлы?';
  }

  @override
  String get workspaceEmpty => 'Проектов пока нет';

  @override
  String get workspaceTitle => 'Рабочая область';

  @override
  String get toolTerminal => 'Терминал';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => 'Процессы';

  @override
  String get projectSelect => 'Выбрать проект';

  @override
  String get projectsHintTemplate => 'Начать с шаблона';

  @override
  String get projectsHintContinue => 'Продолжить работу';

  @override
  String get projectsHintReload => 'Обновить список проектов';

  @override
  String get projectsHintRemoveActive => 'Удалить активный проект';

  @override
  String projectsFilterAll(int count) {
    return 'Все ($count)';
  }

  @override
  String projectsCount(int count) {
    return 'Проектов: $count';
  }

  @override
  String get editorEdit => 'Редактировать';

  @override
  String get editorPreview => 'Просмотр';

  @override
  String get editorTabActions => 'Действия вкладки';

  @override
  String get editorReloadConfirmTitle => 'Перезагрузить файл?';

  @override
  String get editorReloadConfirmBody =>
      'Отменить несохранённые изменения и перезагрузить с диска?';

  @override
  String editorReloaded(String name) {
    return 'Перезагружено: $name';
  }

  @override
  String get editorRecoverTitle => 'Найдены несохранённые изменения';

  @override
  String editorRecoverBody(String name) {
    return 'Восстановить несохранённые изменения для $name?';
  }

  @override
  String get editorCloseDirtyTitle => 'Закрыть без сохранения?';

  @override
  String editorCloseDirtyBody(String name) {
    return 'Отменить несохранённые изменения в $name?';
  }

  @override
  String get editorFocusEnter => 'Фокус-режим';

  @override
  String get editorFocusExit => 'Выйти из фокус-режима';

  @override
  String get explorerTitle => 'ПРОВОДНИК';

  @override
  String get explorerGoUp => 'Вверх';

  @override
  String get runClearOutput => 'Очистить вывод';

  @override
  String get runStartingProcess => 'Запуск процесса…';

  @override
  String get gitProject => 'Проект';

  @override
  String get gitOpenProject => 'Открыть проект';

  @override
  String get gitSelectProject => 'Выбрать проект';

  @override
  String get gitProjectPath => 'Путь к проекту';

  @override
  String get gitStatus => 'Статус';

  @override
  String get gitDiff => 'Diff';

  @override
  String get gitUnavailable => 'Git недоступен';

  @override
  String gitBranch(String branch) {
    return 'Ветка: $branch';
  }

  @override
  String get gitModified => 'Изменённые';

  @override
  String get gitAdded => 'Добавленные';

  @override
  String get gitDeleted => 'Удалённые';

  @override
  String get gitUntracked => 'Неотслеживаемые';

  @override
  String get gitEmptyDiff => '(пустой diff)';

  @override
  String get terminalPaste => 'Вставить';

  @override
  String terminalSessionExited(int code) {
    return 'Сеанс завершён (код $code)';
  }

  @override
  String get terminalKeyTab => 'Tab';

  @override
  String get terminalKeyEsc => 'Esc';

  @override
  String get terminalKeyUp => 'Вверх';

  @override
  String get terminalKeyDown => 'Вниз';

  @override
  String get terminalKeyLeft => 'Влево';

  @override
  String get terminalKeyRight => 'Вправо';

  @override
  String processStarted(String pid, String command) {
    return 'Запущен $pid · $command';
  }

  @override
  String get processStartedByNova => 'Запущено Nova';

  @override
  String get runtimeReady => 'Готово';

  @override
  String get runtimeBootstrapReady =>
      'Bootstrap готов. Среды выполнения можно установить ниже.';

  @override
  String get bootstrapRequired => 'Требуется среда выполнения';

  @override
  String get bootstrapRequiredBody =>
      'Среда Linux не установлена. Скачать её сейчас, чтобы использовать терминал и языковые среды?';

  @override
  String get actionDownload => 'Скачать';

  @override
  String get actionLater => 'Позже';

  @override
  String get runtimeBootstrapUnavailable => 'Состояние Bootstrap недоступно.';

  @override
  String get runtimeBootstrapNotInstalled => 'Bootstrap пока не установлен.';

  @override
  String runtimeVersion(String version) {
    return 'Версия: $version';
  }

  @override
  String get runtimeSetupFailed => 'Настройка не удалась';

  @override
  String get aiTitle => 'Действия ИИ';

  @override
  String get aiKeySaved => 'Ключ сохранён';

  @override
  String get aiEnterKeyFirst => 'Сначала введите API-ключ';

  @override
  String get aiNoCode => 'Код не выбран';

  @override
  String get aiExplainCode => 'Объяснить код';

  @override
  String get aiFixError => 'Исправить ошибку';

  @override
  String get aiCompleteCode => 'Дополнить код';

  @override
  String get aiStop => 'Остановить';

  @override
  String get aiInsert => 'Вставить в редактор';

  @override
  String aiPromptExplain(String code) {
    return 'Объясни следующий код:\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return 'Исправь ошибку в следующем коде:\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return 'Дополни следующий код:\n$code';
  }

  @override
  String get settingsSystem => 'Системный';

  @override
  String settingsRunTimeout(int ms) {
    return 'Тайм-аут запуска: $ms мс';
  }

  @override
  String get settingsTimeoutLabel => 'Тайм-аут (мс, 1000–120000)';

  @override
  String get settingsAutocomplete => 'Автодополнение';

  @override
  String get settingsAutocompleteSub =>
      'Подсказки ключевых слов, сниппетов и слов при вводе';

  @override
  String get settingsAiCompletion => 'ИИ-дополнение';

  @override
  String get settingsAiCompletionSub =>
      'Подсказки модели во всплывающем окне автодополнения';

  @override
  String get settingsMatchTheme => 'Оформление приложения по теме редактора';

  @override
  String get settingsMatchThemeSub =>
      'Всё приложение следует цветам темы редактора';

  @override
  String get settingsWordWrap => 'Перенос строк';

  @override
  String get settingsWordWrapSub =>
      'Переносить длинные строки вместо горизонтальной прокрутки';

  @override
  String get settingsAutoSave => 'Автосохранение';

  @override
  String get settingsAutoSaveSub =>
      'Сохранять через 1,5 с после окончания ввода';

  @override
  String get settingsEditorFont => 'Шрифт редактора';

  @override
  String get settingsFontInstalled => 'Шрифт установлен';

  @override
  String get settingsFontUpdated => 'Шрифт редактора обновлён';

  @override
  String get settingsDownloadFailed =>
      'Не удалось скачать: проверьте соединение';

  @override
  String get settingsLivePreview => 'Живой предпросмотр';

  @override
  String get settingsProvider => 'Провайдер';

  @override
  String get settingsCustomProvider => 'Свой (совместимый с OpenAI)';

  @override
  String get settingsBaseUrl => 'Базовый URL (совместимый с OpenAI)';

  @override
  String get settingsModel => 'Модель';

  @override
  String get settingsApiKey => 'API-ключ';

  @override
  String get settingsApiKeySaved => 'Сохранён в защищённом хранилище';

  @override
  String get settingsApiKeyHint => 'Вставьте свой ключ';

  @override
  String get settingsKeySecureNote =>
      'Ключ хранится в зашифрованном защищённом хранилище, а не в обычных настройках.';

  @override
  String get settingsTestConnection => 'Проверить соединение';

  @override
  String get settingsTesting => 'Проверка…';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String settingsConnected(String reply) {
    return 'Подключено: $reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return 'Не удалось подключиться: $error';
  }

  @override
  String settingsThemeImported(String name) {
    return 'Тема «$name» импортирована';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String settingsThemeCopied(String name) {
    return 'JSON темы «$name» скопирован';
  }

  @override
  String settingsThemeExported(String name) {
    return 'Тема «$name» экспортирована в буфер обмена';
  }

  @override
  String get settingsImportTheme => 'Импортировать JSON темы';

  @override
  String get settingsCopyTheme => 'Копировать JSON темы';

  @override
  String get settingsExportTheme => 'Экспортировать тему';

  @override
  String get settingsDeleteTheme => 'Удалить тему';

  @override
  String get searchTitle => 'Поиск по проекту';

  @override
  String get searchHint => 'Текст или шаблон для поиска…';

  @override
  String get searchReplaceHint => 'Заменить на…';

  @override
  String get searchMatchCase => 'Учитывать регистр';

  @override
  String get searchUseRegex => 'Использовать регулярное выражение';

  @override
  String get searchButton => 'Найти';

  @override
  String searchButtonCount(int hits) {
    return 'Найти ($hits)';
  }

  @override
  String get searchReplaceAll => 'Заменить всё';

  @override
  String get searchNoProject => 'Нет открытого проекта';

  @override
  String get searchTypeSomething => 'Введите текст для поиска';

  @override
  String get searchInvalidRegex => 'Некорректное регулярное выражение';

  @override
  String searchFailed(String error) {
    return 'Поиск не удался: $error';
  }

  @override
  String get searchEmptyHint => 'Поиск по активному проекту выше';

  @override
  String get searchNoMatches => 'Совпадений нет';

  @override
  String get searchTruncated =>
      'Показаны только первые совпадения (достигнуты лимиты)';

  @override
  String searchReplaceCount(int count) {
    return 'Заменить ($count)';
  }

  @override
  String get searchUnsavedTitle => 'Несохранённые изменения';

  @override
  String searchUnsavedBody(String names) {
    return 'В этих открытых вкладках есть несохранённые правки, которые будут перезаписаны заменой: $names. Всё равно заменить?';
  }

  @override
  String get searchReplaceAnyway => 'Всё равно заменить';

  @override
  String get searchNoMatchesReplace => 'Нечего заменять';

  @override
  String searchReplaced(int total, int files) {
    return 'Заменено $total в $files файлах. Переоткройте затронутые вкладки для перезагрузки.';
  }

  @override
  String searchReplaceFailed(String error) {
    return 'Замена не удалась: $error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return 'Нет совпадений в $name';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return 'Заменено $count в $name. Переоткройте вкладку для перезагрузки.';
  }

  @override
  String get editorFindInFile => 'Найти в файле';

  @override
  String get editorGoToDefinition => 'Перейти к определению';

  @override
  String get editorNoSymbolAtCaret => 'Сначала поставьте курсор на символ';

  @override
  String editorDefinitionNotFound(String name) {
    return 'Определение для «$name» не найдено';
  }

  @override
  String get editorFindHint => 'Найти';

  @override
  String get editorPrevMatch => 'Предыдущее совпадение';

  @override
  String get editorNextMatch => 'Следующее совпадение';

  @override
  String get editorMatchCase => 'Учитывать регистр';

  @override
  String get editorUseRegex => 'Использовать регулярное выражение';

  @override
  String get editorCloseFind => 'Закрыть панель поиска';

  @override
  String explorerStorageError(String error) {
    return 'Хранилище недоступно для записи: $error';
  }

  @override
  String get explorerNewFileHint => 'например, main.py';

  @override
  String get explorerNoFolder => 'Папка не выбрана';

  @override
  String get mdUndo => 'Отменить';

  @override
  String get mdRedo => 'Вернуть';

  @override
  String get mdBold => 'Жирный';

  @override
  String get mdItalic => 'Курсив';

  @override
  String get mdUnderline => 'Подчёркнутый';

  @override
  String get mdStrike => 'Зачёркнутый';

  @override
  String get mdInlineCode => 'Встроенный код';

  @override
  String get mdH1 => 'Заголовок 1';

  @override
  String get mdH2 => 'Заголовок 2';

  @override
  String get mdH3 => 'Заголовок 3';

  @override
  String get mdBulleted => 'Маркированный список';

  @override
  String get mdNumbered => 'Нумерованный список';

  @override
  String get mdQuote => 'Цитата';

  @override
  String get mdCodeBlock => 'Блок кода';

  @override
  String get terminalMaxTabs => 'Достигнут лимит: 5 вкладок терминала';

  @override
  String get paletteHint => 'Введите команду или имя файла…';

  @override
  String get paletteNoMatches => 'Совпадений нет';

  @override
  String get paletteToggleRun => 'Переключить панель запуска';

  @override
  String get paletteToggleTerminal => 'Переключить терминал';

  @override
  String get paletteToggleGit => 'Переключить панель Git';

  @override
  String get paletteToggleProcesses => 'Переключить панель процессов';

  @override
  String get paletteSwitchTheme => 'Сменить тему редактора';

  @override
  String get paletteSearchInProject => 'Поиск по проекту';

  @override
  String get paletteOpenSettings => 'Открыть настройки';

  @override
  String get paletteTitle => 'Командная палитра';

  @override
  String get projectGeneral => 'Общий';

  @override
  String get projectGeneralSub =>
      'Среда выполнения не предполагается — язык определяется автоматически';

  @override
  String runtimeInstalledOk(String name) {
    return '$name успешно установлен';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return 'Не удалось установить $name: $error';
  }

  @override
  String runtimeStartInstall(String name) {
    return 'Начинается установка $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return 'Не удалось начать установку: $error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return 'Начинается обновление $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return 'Не удалось начать обновление: $error';
  }

  @override
  String runtimeRemoving(String name) {
    return 'Удаление $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get runtimeChooseVariant =>
      'Выберите образ системы Linux (скачивается один раз из интернета):';

  @override
  String get runtimeVariantSlim => 'Лёгкий ~70 МБ (рекомендуется)';

  @override
  String get runtimeVariantSlimSub =>
      'Ядро + apt — языки устанавливаются по требованию';

  @override
  String get runtimeVariantFull => 'Полный ~283 МБ';

  @override
  String get runtimeVariantFullSub =>
      'Node, Python, PHP и Git предустановлены — работает офлайн';

  @override
  String get runtimeNoResults => 'Ничего не найдено';

  @override
  String get runtimeSearchHint => 'Найти язык или инструмент…';

  @override
  String get runtimeClear => 'Очистить';

  @override
  String get runtimeUnsupported => 'Не поддерживается на этом устройстве';

  @override
  String runtimeInstalledSection(int count) {
    return 'Установлено ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return 'Готовые наборы ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return 'Языки ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return 'Инструменты ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return 'Выполняется: $name';
  }

  @override
  String runtimeLastOp(String name) {
    return 'Последняя операция: $name';
  }

  @override
  String get runtimeLogTitle => 'Журнал операций';

  @override
  String runtimeLines(int count) {
    return 'Строк: $count';
  }

  @override
  String get runtimeDone => 'Готово';

  @override
  String get runtimeStatusUpdating => 'Обновление списков пакетов…';

  @override
  String get runtimeStatusInstalling => 'Начало установки…';

  @override
  String get runtimeStatusReading => 'Чтение списков пакетов…';

  @override
  String get runtimeStatusDeps => 'Построение дерева зависимостей…';

  @override
  String get runtimeStatusUnpacking => 'Распаковка пакетов…';

  @override
  String get runtimeStatusSettingUp => 'Настройка пакетов…';

  @override
  String runtimeWorkingOn(String name) {
    return 'Обработка $name…';
  }

  @override
  String get setupSlimTitle => 'Лёгкий ~80 МБ (по умолчанию)';

  @override
  String get setupSlimSub => 'Ядро + apt — языки устанавливаются по требованию';

  @override
  String get setupFullTitle => 'Полный ~283 МБ (офлайн)';

  @override
  String get setupFullSub => 'Node, Python, PHP и Git предустановлены';

  @override
  String get setupResumeNote =>
      'Повторная попытка использует проверенную загрузку (продолжение).';

  @override
  String get setupSources => 'Источники загрузки:';

  @override
  String get setupSourceOk => 'доступен';

  @override
  String get setupSourceDown => 'недоступен — проверьте соединение';

  @override
  String get webPreviewTitle => 'Веб-предпросмотр';

  @override
  String get runtimeDescPhp => 'Веб-язык — Laravel и WordPress';

  @override
  String get runtimeDescNode => 'JavaScript и TypeScript — npm включён';

  @override
  String get runtimeDescPython => 'Скрипты и данные — pip включён';

  @override
  String get runtimeDescGo => 'Компилируемый Go — быстрый и лёгкий';

  @override
  String get runtimeDescRust =>
      'Rust — безопасность памяти и производительность';

  @override
  String get runtimeDescRuby => 'Ruby для скриптов и веба';

  @override
  String get runtimeDescJava => 'Java 25 — полная платформа JVM';

  @override
  String get runtimeDescKotlin => 'Kotlin — работает на JVM (нужна Java)';

  @override
  String get runtimeDescDart => 'Dart — приложения и CLI-инструменты';

  @override
  String get runtimeDescC => 'C и C++ — быстрый компилятор Clang';

  @override
  String get runtimeDescGit => 'Контроль версий и репозитории';

  @override
  String get runtimeDescComposer => 'Менеджер пакетов PHP';

  @override
  String get runtimeDescNovaWeb =>
      'PHP + Composer + Ruby + Node.js — веб-разработка';

  @override
  String get runtimeDescNovaSystems =>
      'Rust + Go + make + cmake — системные языки';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin — платформа JVM';

  @override
  String get runtimeDescNovaPython => 'Python + pip — скрипты и данные';

  @override
  String get runtimeDescNovaDart => 'Dart — CLI-инструменты';

  @override
  String get splashTagline => 'Ваша среда разработки — в кармане';

  @override
  String get splashStatusEngine => 'Инициализация движка…';

  @override
  String get splashStatusSettings => 'Загрузка настроек…';

  @override
  String get splashStatusRuntime => 'Проверка среды выполнения…';

  @override
  String get splashStatusWorkspace => 'Подготовка рабочей области…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • v$version (сборка $build)';
  }

  @override
  String get settingsAbout => 'О приложении';

  @override
  String appVersionBuild(String version, String build) {
    return 'v$version (сборка $build)';
  }

  @override
  String get aboutTitle => 'О приложении и контакты';

  @override
  String get aboutTagline => 'Ваша среда разработки — в кармане';

  @override
  String get aboutSectionAbout => 'О Nova';

  @override
  String get aboutDescription =>
      'Nova — редактор кода, который работает на вашем Android-телефоне и выполняет код прямо на устройстве: Python, JavaScript, PHP, Go, Rust, Ruby, Java, Kotlin, Dart, C/C++ — с настоящим терминалом, Git и веб-предпросмотром. Без внешнего сервера и эмуляции: пишите, нажимайте «Запустить» и смотрите результат.';

  @override
  String get aboutSectionDownload => 'Скачать';

  @override
  String get aboutPlayTitle => 'Google Play';

  @override
  String get aboutPlaySub =>
      'Простая установка для большинства пользователей, обновления через Play Store';

  @override
  String get aboutGithubTitle => 'Релизы на GitHub';

  @override
  String get aboutGithubSub => 'Прямые APK со страницы релизов проекта';

  @override
  String get aboutVersionsTitle => 'Какую версию выбрать?';

  @override
  String get aboutVersionsBody =>
      'Сборка GitHub ориентирована на Android API 28 с прямым запуском — текущий основной путь, при котором встроенная среда Linux работает на полной мощности. Сборка Play ориентирована на API 36 и запускается через linker в соответствии с актуальными правилами Play Store. Редактор и функции одинаковые; отличается только путь запуска среды выполнения.';

  @override
  String get aboutSectionProject => 'Проект';

  @override
  String get aboutSourceCode => 'Исходный код';

  @override
  String get aboutReleases => 'Релизы';

  @override
  String get aboutPackageRepo => 'Репозиторий пакетов';

  @override
  String get aboutLicense => 'Лицензия: Waqf General Public License v1';

  @override
  String get aboutLicenseSub =>
      'Вакф ради Аллаха — свободное использование, распространение и изменение';

  @override
  String get aboutSectionContact => 'Связаться с нами';

  @override
  String get aboutEmailUs => 'Написать нам';

  @override
  String get aboutEmailHint => 'По вопросам, отзывам и сообщениям об ошибках';

  @override
  String get aboutCopied => 'Скопировано';

  @override
  String get aboutOpenFailed => 'Не удалось открыть ссылку';

  @override
  String get authAccount => 'Аккаунт';

  @override
  String get authContinueAsGuest => 'Продолжить как гость';

  @override
  String get authDelete => 'Удалить аккаунт';

  @override
  String get authDeleteBody =>
      'Это действие навсегда удалит ваш аккаунт. Продолжить?';

  @override
  String get authDeleteTitle => 'Удалить аккаунт?';

  @override
  String get authEmail => 'Электронная почта';

  @override
  String get authForgot => 'Забыли пароль?';

  @override
  String get authForgotHint => 'Мы отправим вам ссылку для сброса.';

  @override
  String get authForgotTitle => 'Сброс пароля';

  @override
  String get authGithub => 'Продолжить через GitHub';

  @override
  String get authGoogle => 'Продолжить через Google';

  @override
  String get authGuestNote =>
      'Гостевой режим: ничего не заблокировано. Вход необязателен.';

  @override
  String get authInvalidEmail => 'Введите корректный адрес электронной почты';

  @override
  String get authLogin => 'Вход';

  @override
  String get authLogout => 'Выйти';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authPasswordTooShort =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get authResend => 'Отправить повторно';

  @override
  String get authResent => 'Письмо для подтверждения отправлено';

  @override
  String get authSend => 'Отправить';

  @override
  String get authSent => 'Письмо для сброса отправлено';

  @override
  String get authSignup => 'Регистрация';

  @override
  String get authSignedOut => 'Вы вышли из аккаунта';

  @override
  String get authTitle => 'Вход';

  @override
  String get authVerifyBanner =>
      'Электронная почта не подтверждена. Подтвердите её для защиты аккаунта.';

  @override
  String get authX => 'Продолжить через X';

  @override
  String get notifCopyToken => 'Копировать push-токен';

  @override
  String get notifDelete => 'Удалить';

  @override
  String get notifEmpty => 'Уведомлений пока нет';

  @override
  String get notifMarkAllRead => 'Отметить все как прочитанные';

  @override
  String get notifTitle => 'Уведомления';

  @override
  String get notifTokenCopied => 'Push-токен скопирован';

  @override
  String get langTitle => 'Выберите язык';

  @override
  String get langSubtitle => 'Его всегда можно изменить в настройках';

  @override
  String get langContinue => 'Продолжить';

  @override
  String get onboardSkip => 'Пропустить';

  @override
  String get onboardNext => 'Далее';

  @override
  String get onboardStart => 'Начать';

  @override
  String get onboard1Title => 'Настоящий редактор кода';

  @override
  String get onboard1Body =>
      'Подсветка синтаксиса, умное автодополнение и темы для каждого языка.';

  @override
  String get onboard2Title => 'Терминал Linux на вашем телефоне';

  @override
  String get onboard2Body =>
      'Node.js, Python и Git работают внутри приложения — root не нужен.';

  @override
  String get onboard3Title => 'ИИ-помощник по программированию';

  @override
  String get onboard3Body =>
      'Объясняйте код, исправляйте ошибки и создавайте сниппеты с любым провайдером.';

  @override
  String get onboard4Title => 'Проекты и Git';

  @override
  String get onboard4Body =>
      'Открывайте папки, просматривайте файлы и делайте commit из любого места.';
}
