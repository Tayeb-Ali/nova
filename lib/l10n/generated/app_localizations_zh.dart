// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get searchEmpty => '无匹配结果';

  @override
  String get searchPrompt => '在上方搜索当前项目';

  @override
  String get commandPaletteEmpty => '无匹配结果';

  @override
  String get navProjects => '项目';

  @override
  String get navEditor => '编辑器';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => '设置';

  @override
  String get actionOpen => '打开';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionCreate => '创建';

  @override
  String get actionRetry => '重试';

  @override
  String get actionExit => 'Exit';

  @override
  String get appExitTitle => 'Exit Nova?';

  @override
  String get appExitBody => 'Press Exit to close the app.';

  @override
  String get actionClose => '关闭';

  @override
  String get actionRestore => '恢复';

  @override
  String get actionDiscard => '舍弃';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionImport => '导入';

  @override
  String get actionExport => '导出';

  @override
  String get actionCopy => '复制';

  @override
  String get actionShare => '分享';

  @override
  String get projectsWorkspaceStats => '工作区统计';

  @override
  String get projectsOpenFolder => '打开文件夹';

  @override
  String get projectsOpenFile => '打开文件';

  @override
  String get projectsCloneGit => '克隆 Git 仓库';

  @override
  String get projectsNewProject => '新建项目';

  @override
  String get projectsRecentProjects => '最近的项目';

  @override
  String get projectsRecentFiles => '最近的文件';

  @override
  String get projectsTipsTitle => '提示';

  @override
  String get projectsTipOrganize => '每个项目使用单独的文件夹，可更快切换。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsEditor => '编辑器';

  @override
  String settingsFontSize(String size) {
    return '字号：$size';
  }

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsTimeout => '超时';

  @override
  String get themeNovaDark => 'Nova 深色';

  @override
  String get themeNovaLight => 'Nova 浅色';

  @override
  String get actionRun => '运行';

  @override
  String get actionStop => '停止';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionRename => '重命名';

  @override
  String get actionInstall => '安装';

  @override
  String get actionUpdate => '更新';

  @override
  String get actionUninstall => '卸载';

  @override
  String commonError(String error) {
    return '错误：$error';
  }

  @override
  String commonCreateFailed(String error) {
    return '创建失败：$error';
  }

  @override
  String commonDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String commonRenameFailed(String error) {
    return '重命名失败：$error';
  }

  @override
  String get projectsProjectNameHint => '项目名称';

  @override
  String get projectsDeleteTitle => '删除项目？';

  @override
  String projectsDeleteMessage(String name) {
    return '删除“$name”及其所有文件？';
  }

  @override
  String get projectsSearchHint => '搜索项目…';

  @override
  String get projectsStatusUnavailable => '运行时状态不可用';

  @override
  String get projectsSetupNeeded => '需要设置运行时';

  @override
  String get projectsRuntimeReady => '运行时就绪';

  @override
  String get projectsOpenEditor => '打开编辑器';

  @override
  String get projectsDeleteProject => '删除项目';

  @override
  String get projectsEmptyTitle => '暂无项目';

  @override
  String get projectsTipsBody =>
      '点击项目即可在编辑器中打开。创建 Node 或 Python 项目前，请先在 Packages 选项卡中安装运行时。';

  @override
  String get editorEmptyHint => '从文件浏览器中打开文件';

  @override
  String editorSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String editorSaved(String name) {
    return '已保存 $name';
  }

  @override
  String editorOpenFailed(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get explorerNewFile => '新建文件';

  @override
  String get explorerNewNameHint => '新名称';

  @override
  String get explorerDeleteTitle => '删除？';

  @override
  String explorerDeleteMessage(String name) {
    return '删除 $name？';
  }

  @override
  String get explorerSelectProject => '选择项目';

  @override
  String get explorerEmptyFolder => '空文件夹';

  @override
  String runStartFailed(String error) {
    return '启动任务失败：$error';
  }

  @override
  String get runNoTasks => '未检测到任务';

  @override
  String get runHideConsole => '隐藏控制台';

  @override
  String get runShowConsole => '显示控制台';

  @override
  String get runEmptyHint => '按“运行”执行所选任务，输出将显示在此处。';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitCommitMessage => 'Commit 信息';

  @override
  String get gitCommitted => '已 commit';

  @override
  String gitCommitFailed(String error) {
    return 'Commit 失败：$error';
  }

  @override
  String get gitStageAll => '暂存全部';

  @override
  String get gitStagedAll => '已暂存所有更改';

  @override
  String gitStageFailed(String error) {
    return '暂存失败：$error';
  }

  @override
  String get gitStage => '暂存';

  @override
  String gitStagedFile(String file) {
    return '已暂存 $file';
  }

  @override
  String get gitBranches => '分支';

  @override
  String get gitCheckout => '检出';

  @override
  String get gitCreateBranch => '新建分支';

  @override
  String get gitBranchNameHint => '分支名称';

  @override
  String gitDeleteBranchConfirm(String name) {
    return '删除分支“$name”？';
  }

  @override
  String gitBranchActionFailed(String error) {
    return '分支操作失败：$error';
  }

  @override
  String get gitNoBranches => '（暂无分支）';

  @override
  String get gitStash => '储藏';

  @override
  String get gitStashSave => '储藏更改';

  @override
  String get gitStashMessage => '储藏说明';

  @override
  String get gitStashed => '已储藏更改';

  @override
  String gitStashActionFailed(String error) {
    return '储藏操作失败：$error';
  }

  @override
  String get gitRemote => '远程仓库 (SSH)';

  @override
  String get gitClone => '克隆';

  @override
  String get gitCloneUrl => '仓库地址 (SSH)';

  @override
  String get gitCloneDir => '目标目录';

  @override
  String get gitCloned => '克隆成功';

  @override
  String get gitFetch => '获取';

  @override
  String get gitFetched => '已获取';

  @override
  String get gitPull => '拉取';

  @override
  String get gitPulled => '已拉取';

  @override
  String get gitPush => '推送';

  @override
  String get gitPushed => '已推送';

  @override
  String gitRemoteFailed(String error) {
    return '远程操作失败：$error';
  }

  @override
  String get gitSshKey => '应用 SSH 公钥';

  @override
  String get gitSshNoKey => '暂无密钥 — 请生成一个，然后将其添加到你的托管账户中。';

  @override
  String get gitSshGenerate => '生成密钥';

  @override
  String get gitSshCopy => '复制';

  @override
  String get gitSshCopied => '公钥已复制 — 请将其添加到你账户的 SSH 密钥中';

  @override
  String get gitStashEmpty => '（暂无储藏的更改）';

  @override
  String get gitStashPop => '弹出';

  @override
  String get gitStashDrop => '丢弃';

  @override
  String get terminalTitle => '终端';

  @override
  String get terminalNewSession => '新建会话';

  @override
  String get terminalStartFailed => '启动终端会话失败';

  @override
  String get processTitle => '进程';

  @override
  String get processRunHint => '运行命令…例如 npm run dev';

  @override
  String get processEmpty => '暂无正在运行的进程。\n启动任务后可在此查看。';

  @override
  String get runtimeTitle => '运行时';

  @override
  String get runtimeBootstrap => 'Bootstrap';

  @override
  String get runtimeStartSetup => '开始设置';

  @override
  String get runtimeInstalled => '已安装';

  @override
  String get runtimeAvailable => '可用';

  @override
  String runtimeUninstallConfirm(String name) {
    return '卸载 $name？';
  }

  @override
  String get runtimeEmpty => '暂无可用的运行时。';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeFollowSystem => '跟随系统';

  @override
  String get toolsShow => '显示工具';

  @override
  String get toolsHide => '隐藏工具';

  @override
  String get toolbarShow => '显示工具栏';

  @override
  String get toolbarHide => '隐藏工具栏';

  @override
  String get explorerShow => '显示文件浏览器';

  @override
  String get explorerHide => '隐藏文件浏览器';

  @override
  String get projectNew => '新建项目';

  @override
  String get projectNameHint => '项目名称';

  @override
  String get projectDelete => '删除项目';

  @override
  String get projectDeleteTitle => '删除项目？';

  @override
  String projectDeleteBody(String name) {
    return '删除“$name”及其所有文件？';
  }

  @override
  String get workspaceEmpty => '暂无项目';

  @override
  String get workspaceTitle => '工作区';

  @override
  String get toolTerminal => '终端';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => '进程';

  @override
  String get projectSelect => '选择项目';

  @override
  String get projectsHintTemplate => '从模板开始';

  @override
  String get projectsHintContinue => '继续工作';

  @override
  String get projectsHintReload => '重新加载项目列表';

  @override
  String get projectsHintRemoveActive => '移除当前项目';

  @override
  String projectsFilterAll(int count) {
    return '全部 ($count)';
  }

  @override
  String projectsCount(int count) {
    return '$count 个项目';
  }

  @override
  String get editorEdit => '编辑';

  @override
  String get editorPreview => '预览';

  @override
  String get editorTabActions => '标签页操作';

  @override
  String get editorReloadConfirmTitle => '重新加载文件？';

  @override
  String get editorReloadConfirmBody => '舍弃未保存的更改并从磁盘重新加载？';

  @override
  String editorReloaded(String name) {
    return '已重新加载 $name';
  }

  @override
  String get editorRecoverTitle => '发现未保存的更改';

  @override
  String editorRecoverBody(String name) {
    return '恢复 $name 的未保存更改？';
  }

  @override
  String get editorCloseDirtyTitle => '不保存直接关闭？';

  @override
  String editorCloseDirtyBody(String name) {
    return '舍弃对 $name 的未保存更改？';
  }

  @override
  String get editorFocusEnter => '专注模式';

  @override
  String get editorFocusExit => '退出专注模式';

  @override
  String get explorerTitle => '资源管理器';

  @override
  String get explorerGoUp => '返回上级';

  @override
  String get runClearOutput => '清空输出';

  @override
  String get runStartingProcess => '正在启动进程…';

  @override
  String get gitProject => '项目';

  @override
  String get gitOpenProject => '打开项目';

  @override
  String get gitSelectProject => '选择项目';

  @override
  String get gitProjectPath => '项目路径';

  @override
  String get gitStatus => '状态';

  @override
  String get gitDiff => '差异';

  @override
  String get gitUnavailable => 'Git 不可用';

  @override
  String gitBranch(String branch) {
    return '分支：$branch';
  }

  @override
  String get gitModified => '已修改';

  @override
  String get gitAdded => '已添加';

  @override
  String get gitDeleted => '已删除';

  @override
  String get gitUntracked => '未跟踪';

  @override
  String get gitEmptyDiff => '（空差异）';

  @override
  String get terminalPaste => '粘贴';

  @override
  String terminalSessionExited(int code) {
    return '会话已退出（代码 $code）';
  }

  @override
  String get terminalKeyTab => 'Tab';

  @override
  String get terminalKeyEsc => 'Esc';

  @override
  String get terminalKeyUp => '上';

  @override
  String get terminalKeyDown => '下';

  @override
  String get terminalKeyLeft => '左';

  @override
  String get terminalKeyRight => '右';

  @override
  String processStarted(String pid, String command) {
    return '已启动 $pid · $command';
  }

  @override
  String get processStartedByNova => '由 Nova 启动';

  @override
  String get runtimeReady => '就绪';

  @override
  String get runtimeBootstrapReady => 'Bootstrap 已就绪，可在下方安装运行时。';

  @override
  String get bootstrapRequired => '需要运行时';

  @override
  String get bootstrapRequiredBody => '尚未安装 Linux 运行时。立即下载以使用终端和语言运行时？';

  @override
  String get actionDownload => '下载';

  @override
  String get actionLater => '稍后';

  @override
  String get runtimeBootstrapUnavailable => 'Bootstrap 状态不可用。';

  @override
  String get runtimeBootstrapNotInstalled => '尚未安装 Bootstrap。';

  @override
  String runtimeVersion(String version) {
    return '版本：$version';
  }

  @override
  String get runtimeSetupFailed => '设置失败';

  @override
  String get aiTitle => 'AI 操作';

  @override
  String get aiKeySaved => '密钥已保存';

  @override
  String get aiEnterKeyFirst => '请先输入 API 密钥';

  @override
  String get aiNoCode => '未选择代码';

  @override
  String get aiExplainCode => '解释代码';

  @override
  String get aiFixError => '修复错误';

  @override
  String get aiCompleteCode => '补全代码';

  @override
  String get aiStop => '停止';

  @override
  String get aiInsert => '插入到编辑器';

  @override
  String aiPromptExplain(String code) {
    return '解释以下代码：\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return '修复以下代码中的错误：\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return '补全以下代码：\n$code';
  }

  @override
  String get settingsSystem => '跟随系统';

  @override
  String settingsRunTimeout(int ms) {
    return '运行超时：$ms 毫秒';
  }

  @override
  String get settingsTimeoutLabel => '超时（毫秒，1000-120000）';

  @override
  String get settingsAutocomplete => '自动补全';

  @override
  String get settingsAutocompleteSub => '输入时提供关键字、代码片段和单词建议';

  @override
  String get settingsAiCompletion => 'AI 补全';

  @override
  String get settingsAiCompletionSub => '在自动补全弹窗中显示模型建议';

  @override
  String get settingsMatchTheme => '应用跟随编辑器主题';

  @override
  String get settingsMatchThemeSub => '整个应用跟随编辑器主题配色';

  @override
  String get settingsWordWrap => '自动换行';

  @override
  String get settingsWordWrapSub => '长行自动换行，而非横向滚动';

  @override
  String get settingsAutoSave => '自动保存';

  @override
  String get settingsAutoSaveSub => '停止输入 1.5 秒后保存';

  @override
  String get settingsEditorFont => '编辑器字体';

  @override
  String get settingsFontInstalled => '字体已安装';

  @override
  String get settingsFontUpdated => '编辑器字体已更新';

  @override
  String get settingsDownloadFailed => '下载失败：请检查网络连接';

  @override
  String get settingsLivePreview => '实时预览';

  @override
  String get settingsProvider => '服务商';

  @override
  String get settingsCustomProvider => '自定义（兼容 OpenAI）';

  @override
  String get settingsBaseUrl => 'Base URL（兼容 OpenAI）';

  @override
  String get settingsModel => '模型';

  @override
  String get settingsApiKey => 'API 密钥';

  @override
  String get settingsApiKeySaved => '已保存在安全存储中';

  @override
  String get settingsApiKeyHint => '粘贴你的密钥';

  @override
  String get settingsKeySecureNote => '密钥保存在加密的安全存储中，不会以明文存放在设置里。';

  @override
  String get settingsTestConnection => '测试连接';

  @override
  String get settingsTesting => '测试中…';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String settingsConnected(String reply) {
    return '已连接：$reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String settingsThemeImported(String name) {
    return '主题“$name”已导入';
  }

  @override
  String settingsImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String settingsThemeCopied(String name) {
    return '主题“$name”的 JSON 已复制';
  }

  @override
  String settingsThemeExported(String name) {
    return '主题“$name”已导出到剪贴板';
  }

  @override
  String get settingsImportTheme => '导入主题 JSON';

  @override
  String get settingsCopyTheme => '复制主题 JSON';

  @override
  String get settingsExportTheme => '导出主题';

  @override
  String get settingsDeleteTheme => '删除主题';

  @override
  String get searchTitle => '在项目中搜索';

  @override
  String get searchHint => '搜索文本或表达式…';

  @override
  String get searchReplaceHint => '替换为…';

  @override
  String get searchMatchCase => '区分大小写';

  @override
  String get searchUseRegex => '使用正则表达式';

  @override
  String get searchButton => '搜索';

  @override
  String searchButtonCount(int hits) {
    return '搜索 ($hits)';
  }

  @override
  String get searchReplaceAll => '全部替换';

  @override
  String get searchNoProject => '未打开项目';

  @override
  String get searchTypeSomething => '请输入要搜索的内容';

  @override
  String get searchInvalidRegex => '无效的正则表达式';

  @override
  String searchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String get searchEmptyHint => '在上方搜索当前项目';

  @override
  String get searchNoMatches => '无匹配结果';

  @override
  String get searchTruncated => '仅显示前面的匹配结果（已达上限）';

  @override
  String searchReplaceCount(int count) {
    return '替换 ($count)';
  }

  @override
  String get searchUnsavedTitle => '未保存的更改';

  @override
  String searchUnsavedBody(String names) {
    return '以下打开的标签页有未保存的编辑，替换将覆盖它们：$names。仍要替换吗？';
  }

  @override
  String get searchReplaceAnyway => '仍要替换';

  @override
  String get searchNoMatchesReplace => '没有可替换的匹配项';

  @override
  String searchReplaced(int total, int files) {
    return '已在 $files 个文件中替换 $total 处。请重新打开受影响的标签页以重新加载。';
  }

  @override
  String searchReplaceFailed(String error) {
    return '替换失败：$error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return '$name 中无匹配结果';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return '已在 $name 中替换 $count 处。请重新打开该标签页以重新加载。';
  }

  @override
  String get editorFindInFile => '在文件中查找';

  @override
  String get editorGoToDefinition => '转到定义';

  @override
  String get editorNoSymbolAtCaret => '请先将光标放在某个符号上';

  @override
  String editorDefinitionNotFound(String name) {
    return '未找到“$name”的定义';
  }

  @override
  String get editorFindHint => '查找';

  @override
  String get editorPrevMatch => '上一个匹配项';

  @override
  String get editorNextMatch => '下一个匹配项';

  @override
  String get editorMatchCase => '区分大小写';

  @override
  String get editorUseRegex => '使用正则表达式';

  @override
  String get editorCloseFind => '关闭查找栏';

  @override
  String explorerStorageError(String error) {
    return '此处存储不可写：$error';
  }

  @override
  String get explorerNewFileHint => '例如 main.py';

  @override
  String get explorerNoFolder => '未选择文件夹';

  @override
  String get mdUndo => '撤销';

  @override
  String get mdRedo => '重做';

  @override
  String get mdBold => '加粗';

  @override
  String get mdItalic => '斜体';

  @override
  String get mdUnderline => '下划线';

  @override
  String get mdStrike => '删除线';

  @override
  String get mdInlineCode => '行内代码';

  @override
  String get mdH1 => '标题 1';

  @override
  String get mdH2 => '标题 2';

  @override
  String get mdH3 => '标题 3';

  @override
  String get mdBulleted => '无序列表';

  @override
  String get mdNumbered => '有序列表';

  @override
  String get mdQuote => '引用';

  @override
  String get mdCodeBlock => '代码块';

  @override
  String get terminalMaxTabs => '已达到最多 5 个终端标签页的上限';

  @override
  String get paletteHint => '输入命令或文件名…';

  @override
  String get paletteNoMatches => '无匹配结果';

  @override
  String get paletteToggleRun => '切换运行面板';

  @override
  String get paletteToggleTerminal => '切换终端';

  @override
  String get paletteToggleGit => '切换 Git 面板';

  @override
  String get paletteToggleProcesses => '切换进程面板';

  @override
  String get paletteSwitchTheme => '切换编辑器主题';

  @override
  String get paletteSearchInProject => '在项目中搜索';

  @override
  String get paletteOpenSettings => '打开设置';

  @override
  String get paletteTitle => '命令面板';

  @override
  String get projectGeneral => '通用';

  @override
  String get projectGeneralSub => '不预设运行时 — 自动检测语言';

  @override
  String runtimeInstalledOk(String name) {
    return '已成功安装 $name';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return '安装 $name 失败：$error';
  }

  @override
  String runtimeStartInstall(String name) {
    return '正在开始安装 $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return '开始安装失败：$error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return '正在开始更新 $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return '开始更新失败：$error';
  }

  @override
  String runtimeRemoving(String name) {
    return '正在移除 $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return '移除失败：$error';
  }

  @override
  String get runtimeChooseVariant => '选择一个 Linux 系统镜像（仅需从互联网下载一次）：';

  @override
  String get runtimeVariantSlim => '精简版 ~70MB（推荐）';

  @override
  String get runtimeVariantSlimSub => '核心 + apt — 按需安装语言';

  @override
  String get runtimeVariantFull => '完整版 ~283MB';

  @override
  String get runtimeVariantFullSub => '预装 Node、Python、PHP 和 Git — 可离线使用';

  @override
  String get runtimeNoResults => '无匹配结果';

  @override
  String get runtimeSearchHint => '搜索语言或工具…';

  @override
  String get runtimeClear => '清空';

  @override
  String get runtimeUnsupported => '此设备不支持';

  @override
  String runtimeInstalledSection(int count) {
    return '已安装 ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return '现成套件 ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return '语言 ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return '工具 ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return '正在运行：$name';
  }

  @override
  String runtimeLastOp(String name) {
    return '上次操作：$name';
  }

  @override
  String get runtimeLogTitle => '操作日志';

  @override
  String runtimeLines(int count) {
    return '$count 行';
  }

  @override
  String get runtimeDone => '完成';

  @override
  String get runtimeStatusUpdating => '正在更新软件包列表…';

  @override
  String get runtimeStatusInstalling => '正在开始安装…';

  @override
  String get runtimeStatusReading => '正在读取软件包列表…';

  @override
  String get runtimeStatusDeps => '正在构建依赖关系树…';

  @override
  String get runtimeStatusUnpacking => '正在解包…';

  @override
  String get runtimeStatusSettingUp => '正在配置软件包…';

  @override
  String runtimeWorkingOn(String name) {
    return '正在处理 $name…';
  }

  @override
  String get setupSlimTitle => '精简版 ~80MB（默认）';

  @override
  String get setupSlimSub => '核心 + apt — 按需安装语言';

  @override
  String get setupFullTitle => '完整版 ~283MB（离线）';

  @override
  String get setupFullSub => '预装 Node、Python、PHP 和 Git';

  @override
  String get setupResumeNote => '重试将复用已验证的下载（断点续传）。';

  @override
  String get setupSources => '下载源：';

  @override
  String get setupSourceOk => '可访问';

  @override
  String get setupSourceDown => '不可访问 — 请检查网络连接';

  @override
  String get webPreviewTitle => '网页预览';

  @override
  String get runtimeDescPhp => 'Web 语言 — Laravel 与 WordPress';

  @override
  String get runtimeDescNode => 'JavaScript 与 TypeScript — 内含 npm';

  @override
  String get runtimeDescPython => '脚本与数据处理 — 内含 pip';

  @override
  String get runtimeDescGo => '编译型 Go — 快速轻量';

  @override
  String get runtimeDescRust => 'Rust — 内存安全与高性能';

  @override
  String get runtimeDescRuby => 'Ruby — 脚本与 Web 开发';

  @override
  String get runtimeDescJava => 'Java 25 — 完整 JVM 平台';

  @override
  String get runtimeDescKotlin => 'Kotlin — 运行于 JVM（需要 Java）';

  @override
  String get runtimeDescDart => 'Dart — 应用与命令行工具';

  @override
  String get runtimeDescC => 'C 与 C++ — 快速的 Clang 编译器';

  @override
  String get runtimeDescGit => '版本控制与仓库管理';

  @override
  String get runtimeDescComposer => 'PHP 包管理器';

  @override
  String get runtimeDescNovaWeb => 'PHP + Composer + Ruby + Node.js — Web 开发';

  @override
  String get runtimeDescNovaSystems => 'Rust + Go + make + cmake — 系统级语言';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin — JVM 平台';

  @override
  String get runtimeDescNovaPython => 'Python + pip — 脚本与数据处理';

  @override
  String get runtimeDescNovaDart => 'Dart — 命令行工具';

  @override
  String get splashTagline => '口袋里的开发环境';

  @override
  String get splashStatusEngine => '正在初始化引擎…';

  @override
  String get splashStatusSettings => '正在加载设置…';

  @override
  String get splashStatusRuntime => '正在检查运行时…';

  @override
  String get splashStatusWorkspace => '正在准备工作区…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • v$version（构建 $build）';
  }

  @override
  String get settingsAbout => '关于';

  @override
  String appVersionBuild(String version, String build) {
    return 'v$version（构建 $build）';
  }

  @override
  String get aboutTitle => '关于与联系';

  @override
  String get aboutTagline => '口袋里的开发环境';

  @override
  String get aboutSectionAbout => '关于 Nova';

  @override
  String get aboutDescription =>
      'Nova 是一款运行在 Android 手机上的代码编辑器，可直接在设备上运行代码 — Python、JavaScript、PHP、Go、Rust、Ruby、Java、Kotlin、Dart、C/C++ — 配备真正的终端、Git 与网页预览。无需外部服务器，无需模拟：编写代码，按下运行，即可看到结果。';

  @override
  String get aboutSectionDownload => '下载';

  @override
  String get aboutPlayTitle => 'Google Play';

  @override
  String get aboutPlaySub => '适合大多数用户的便捷安装方式，通过 Play 商店更新';

  @override
  String get aboutGithubTitle => 'GitHub releases';

  @override
  String get aboutGithubSub => '从项目 releases 页面直接下载 APK';

  @override
  String get aboutVersionsTitle => '我该用哪个版本？';

  @override
  String get aboutVersionsBody =>
      'GitHub 构建目标为 Android API 28，采用直接执行 — 这是当前正式的发布路径，内嵌 Linux 运行时可全功率运行。Play 构建目标为 API 36，通过 linker 执行，以符合现行 Play 商店政策。编辑器与功能完全相同，仅运行时启动路径不同。';

  @override
  String get aboutSectionProject => '项目';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get aboutReleases => 'Releases';

  @override
  String get aboutPackageRepo => '软件包仓库';

  @override
  String get aboutLicense => '许可证：Waqf General Public License v1';

  @override
  String get aboutLicenseSub => '为主道而设的 waqf — 可自由使用、分享与修改';

  @override
  String get aboutSectionContact => '联系我们';

  @override
  String get aboutEmailUs => '给我们发邮件';

  @override
  String get aboutEmailHint => '咨询、反馈与错误报告';

  @override
  String get aboutCopied => '已复制';

  @override
  String get aboutOpenFailed => '无法打开链接';

  @override
  String get authAccount => '账户';

  @override
  String get authContinueAsGuest => '以访客身份继续';

  @override
  String get authDelete => '删除账户';

  @override
  String get authDeleteBody => '这将永久删除你的账户。继续吗？';

  @override
  String get authDeleteTitle => '删除账户？';

  @override
  String get authEmail => '邮箱';

  @override
  String get authForgot => '忘记密码？';

  @override
  String get authForgotHint => '我们将向你发送重置链接邮件。';

  @override
  String get authForgotTitle => '重置密码';

  @override
  String get authGithub => '使用 GitHub 继续';

  @override
  String get authGoogle => '使用 Google 继续';

  @override
  String get authGuestNote => '访客模式：无任何功能锁定，登录为可选项。';

  @override
  String get authGuest => '访客';

  @override
  String get authInvalidEmail => '请输入有效的邮箱';

  @override
  String get authLogin => '登录';

  @override
  String get authLogout => '退出登录';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordTooShort => '密码至少需要 6 个字符';

  @override
  String get authResend => '重新发送';

  @override
  String get authResent => '验证邮件已发送';

  @override
  String get authSend => '发送';

  @override
  String get authSent => '重置邮件已发送';

  @override
  String get authSignup => '注册';

  @override
  String get authSignedOut => '已退出登录';

  @override
  String get authTitle => '登录';

  @override
  String get authVerifyBanner => '邮箱尚未验证。请验证以保护你的账户。';

  @override
  String get authX => '使用 X 继续';

  @override
  String get notifCopyToken => '复制推送令牌';

  @override
  String get notifDelete => '删除';

  @override
  String get notifEmpty => '暂无通知';

  @override
  String get notifMarkAllRead => '全部标为已读';

  @override
  String get notifTitle => '通知';

  @override
  String get notifTokenCopied => '推送令牌已复制';

  @override
  String get langTitle => '选择你的语言';

  @override
  String get langSubtitle => '可随时在“设置”中更改';

  @override
  String get langContinue => '继续';

  @override
  String get onboardSkip => '跳过';

  @override
  String get onboardNext => '下一步';

  @override
  String get onboardStart => '开始使用';

  @override
  String get onboard1Title => '真正的代码编辑器';

  @override
  String get onboard1Body => '语法高亮、智能自动补全，以及适配每种语言的主题。';

  @override
  String get onboard2Title => '手机上的 Linux 终端';

  @override
  String get onboard2Body => 'Node.js、Python 和 Git 在应用内原生运行 — 无需 root。';

  @override
  String get onboard3Title => 'AI 结对编程伙伴';

  @override
  String get onboard3Body => '可使用任意服务商解释代码、修复错误并生成代码片段。';

  @override
  String get onboard4Title => '项目与 Git';

  @override
  String get onboard4Body => '打开文件夹、浏览文件，随时随地 commit。';

  @override
  String get tourBack => '返回';

  @override
  String get tourHubSearchTitle => '搜索项目';

  @override
  String get tourHubSearchBody => '按名称筛选项目列表。点击输入框并输入 — 列表会随输入实时缩小范围。';

  @override
  String get tourHubNewTitle => '创建项目';

  @override
  String get tourHubNewBody => '从模板开始一个新项目。点击会打开创建对话框 — 选择“取消”（或点击下一步）即可留在导览中。';

  @override
  String get tourHubCardTitle => '你的项目';

  @override
  String get tourHubCardBody => '点击项目卡片将其设为当前项目。高亮的卡片即编辑器与运行工具所使用的项目。';

  @override
  String get tourHubOpenTitle => '打开编辑器';

  @override
  String get tourHubOpenBody =>
      '进入当前项目的工作区。点击下一步可留在导览中 — 若现在点击该磁贴，将离开项目中心并提前结束导览。';

  @override
  String get tourHubRecentTitle => '最近的文件';

  @override
  String get tourHubRecentBody => '重新打开你在所有项目中最近编辑过的文件。点击其中一个即可直接在编辑器中打开。';

  @override
  String get tourHubNavTitle => '应用导航';

  @override
  String get tourHubNavBody =>
      '底部栏目的地：项目（当前页）、编辑器（工作区）、运行时（语言配置）、设置。? 按钮可随时重播导览。';

  @override
  String get tourEdProjectTitle => '项目切换器';

  @override
  String get tourEdProjectBody =>
      '切换当前项目 — 文件浏览器、编辑器与运行工具都会跟随切换。点击会打开菜单：不做选择（返回）或点击下一步继续。';

  @override
  String get tourEdPaletteTitle => '命令面板';

  @override
  String get tourEdPaletteBody =>
      '模糊查找文件并运行工具/主题命令。点击会打开命令面板 — 选择返回（或点击下一步）即可继续导览。';

  @override
  String get tourEdEntryTitle => '项目文件';

  @override
  String get tourEdEntryBody => '点击文件即可在编辑器中打开 — 这可确保后续步骤有已打开的标签页。长按可重命名或删除。';

  @override
  String get tourEdNewFileTitle => '新建文件';

  @override
  String get tourEdNewFileBody => '在当前文件夹中新建文件。点击会要求输入名称 — 取消该对话框（或点击下一步）即可继续。';

  @override
  String get tourEdGoUpTitle => '返回上级';

  @override
  String get tourEdGoUpBody => '将文件浏览器定位到父文件夹。在项目根目录下不可用。';

  @override
  String get tourEdExplorerTitle => '文件浏览器显隐';

  @override
  String get tourEdExplorerBody =>
      '隐藏文件窗格以获得更宽的编辑区。文件相关步骤已完成，现在点击是安全的 — 再次点击即可恢复窗格。';

  @override
  String get tourEdTabsTitle => '打开的标签页';

  @override
  String get tourEdTabsBody => '每个打开的文件都是一个标签页。点击标签页即可切换。';

  @override
  String get tourEdSaveTitle => '保存';

  @override
  String get tourEdSaveBody => '将当前文件写入磁盘。若文件没有未保存的更改，只会确认一切已保存。';

  @override
  String get tourEdReloadTitle => '重新加载';

  @override
  String get tourEdReloadBody => '从磁盘重新读取文件。无更改的文件会静默重载；有未保存更改的文件会先要求确认。';

  @override
  String get tourEdAiTitle => 'AI 助手';

  @override
  String get tourEdAiBody => '用 AI 解释、补全或编辑选中的代码。点击会打开 AI 面板 — 关闭它即可继续导览。';

  @override
  String get tourEdPreviewTitle => 'Markdown 预览';

  @override
  String get tourEdPreviewBody => 'Markdown 文件可在此切换编辑与渲染预览。代码文件不显示此项。';

  @override
  String get tourEdRunTabTitle => '运行工具';

  @override
  String get tourEdRunTabBody => '切换底部抽屉：运行、终端、Git、进程。此步骤会选中“运行”，以便后续步骤可见。';

  @override
  String get tourEdTaskTitle => '运行任务';

  @override
  String get tourEdTaskBody =>
      '选择要运行的已检测任务，例如本项目的 run 或 test。点击会打开菜单 — 选择一个任务或点击下一步。';

  @override
  String get tourEdRunTitle => '运行';

  @override
  String get tourEdRunBody => '启动所选任务 — 输出会实时显示在下方。点击会真正启动一个进程；可用同一按钮停止它。';

  @override
  String get tourEdDefTitle => '转到定义';

  @override
  String get tourEdDefBody => '跳转到光标处的符号定义。你可能会落到另一个文件 — 其余步骤在那里同样有效。';

  @override
  String get tourEdTabCloseTitle => '关闭标签页';

  @override
  String get tourEdTabCloseBody =>
      '关闭此标签页；未保存的编辑会要求确认。若这是你唯一的标签页，请点击下一步而非 ×，以保持导览完整。';

  @override
  String get tourEdDeleteTitle => '删除项目';

  @override
  String get tourEdDeleteBody => '确认后删除整个项目。点击会打开对话框 — 选择“取消”可保留项目并显示最后一步。';

  @override
  String get tourEdFocusTitle => '专注模式';

  @override
  String get tourEdFocusBody => '隐藏所有界面元素，进入无干扰编辑。点击即进入专注模式 — 用纤细栏中的退出按钮返回。';

  @override
  String get tourRtSearchTitle => '查找运行时';

  @override
  String get tourRtSearchBody => '在此输入以筛选运行时列表。放心尝试 — 这只会筛选，不会安装任何东西。';

  @override
  String get tourRtSetupTitle => 'Bootstrap 设置';

  @override
  String get tourRtSetupBody => '点击开始设置会下载 Linux bootstrap。仅在你准备好下载时才真正点击它。';

  @override
  String get tourRtInstallTitle => '安装运行时';

  @override
  String get tourRtInstallBody =>
      '此安装按钮会启动真正的下载与安装。仅在你现在确实需要该运行时才真正点击 — 它排在最后是有原因的。';

  @override
  String get tourTermPasteTitle => '粘贴到终端';

  @override
  String get tourTermPasteBody =>
      '将剪贴板文本粘贴到 shell 中。点击会真正执行，但无害 — 只会输入文本，不会按下回车。';

  @override
  String get tourTermTabTitle => 'Tab 键';

  @override
  String get tourTermTabBody => '发送 Tab 以触发 shell 自动补全。点击会真正执行，但无害。';

  @override
  String get tourTermCtrlCTitle => 'Ctrl+C 键';

  @override
  String get tourTermCtrlCBody => '发送中断信号 (Ctrl+C)。在空提示符下无害；若有命令正在运行，会取消该命令。';

  @override
  String get tourTermNewTabTitle => '新建终端标签页';

  @override
  String get tourTermNewTabBody =>
      '打开一个真正的 shell 新标签页（最多 5 个）。无害 — 用其标签上的 × 关闭它。排在最后是因为它会改变标签栏。';

  @override
  String get tourSetAccountTitle => '账户';

  @override
  String get tourSetAccountBody => '你的登录状态与账户操作都在这里。';

  @override
  String get tourSetLangTitle => '语言';

  @override
  String get tourSetLangBody => '在此切换应用语言。点击立即生效。';

  @override
  String get tourSetAiKeyTitle => 'AI API 密钥';

  @override
  String get tourSetAiKeyBody => '在此粘贴 AI 服务商密钥。它保存在安全存储中，不会再次显示。';

  @override
  String get tourSetSaveTitle => '保存设置';

  @override
  String get tourSetSaveBody => '真正保存本页的所有设置。无害 — 你随时可以改回来。排在最后是有原因的。';

  @override
  String get tourGitStatusTitle => '刷新状态';

  @override
  String get tourGitStatusBody => '重新加载当前项目的 Git 状态。真正的重新加载，但无害。';

  @override
  String get tourGitCommitTitle => 'Commit';

  @override
  String get tourGitCommitBody =>
      '打开 commit 信息输入框。你可以取消 — 确认之前不会真正提交。排在最后是有原因的。';

  @override
  String get tourNotifMarkReadTitle => '全部标为已读';

  @override
  String get tourNotifMarkReadBody => '将所有通知标为已读。真正执行但无害 — 条目保留，只清除未读圆点。';

  @override
  String get tourReplay => '重播导览';

  @override
  String get tourResetDone => '导览已重置 — 点击任意屏幕上的 ?';

  @override
  String get tourEdNewProjectTitle => '新建项目';

  @override
  String get tourEdNewProjectBody => '从模板再建一个项目。导览期间只读 — 之后可用同一按钮亲自尝试。';

  @override
  String get tourEdTermTabTitle => '终端抽屉';

  @override
  String get tourEdTermTabBody => '将底部抽屉切换到内嵌终端。真正的切换 — 切换走后 shell 会话仍保持运行。';

  @override
  String get tourEdGitTabTitle => 'Git 抽屉';

  @override
  String get tourEdGitTabBody => '将底部抽屉切换到 Git：查看本项目的状态、暂存、commit 与分支。';

  @override
  String get tourEdProcTabTitle => '进程抽屉';

  @override
  String get tourEdProcTabBody => '将底部抽屉切换到进程：每个正在运行的命令及其输出，还有停止按钮。';

  @override
  String get tourEdToolsTitle => '隐藏工具';

  @override
  String get tourEdToolsBody => '收起整个底部抽屉以获得最大编辑高度。点击会立即隐藏 — 用细长的抓取条恢复，或点击下一步。';

  @override
  String get tourEdToolbarTitle => '隐藏工具栏';

  @override
  String get tourEdToolbarBody =>
      '将顶栏收起为 28px 的细条。点击会立即隐藏 — 用细条中的展开按钮恢复，然后完成最后一步。';
}
