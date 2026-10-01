import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/dart.dart";

import "package:flutter_secure_storage/flutter_secure_storage.dart";

import "../../../l10n/generated/app_localizations.dart";
import "../../core/services/app_info_service.dart";
import "../../core/settings_store.dart";
import "../ai/ai_client.dart";
import "../ai/ai_presets.dart";
import "../ai/ai_providers.dart";
import "../editor/theme/editor_fonts.dart";
import "../editor/theme/font_loader.dart";
import "../editor/theme/editor_theme_pack.dart";
import "../editor/theme/theme_pack_store.dart";

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _timeoutCtrl;
  late TextEditingController _apiKeyCtrl;
  bool _init = false;
  bool _fontLoading = false;
  bool _fontWarmupDone = false;
  bool _aiTesting = false;

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _timeoutCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _ensureInit(Settings s) {
    if (_init) return;
    _init = true;
    _baseUrlCtrl = TextEditingController(text: s.aiBaseUrl);
    _modelCtrl = TextEditingController(text: s.aiModel);
    _timeoutCtrl = TextEditingController(text: s.timeoutMs.toString());
    _apiKeyCtrl = TextEditingController();
  }

  // Sends a minimal chat request to verify the provider connects.
  // Reads the key from the field, falling back to the stored key.
  Future<void> _testAiConnection(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) {
      try {
        key =
            await const FlutterSecureStorage().read(key: kNovaAiKeyStorageKey) ??
            "";
      } catch (_) {
        key = "";
      }
    }
    if (key.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.aiEnterKeyFirst)),
      );
      return;
    }
    setState(() => _aiTesting = true);
    try {
      final reply = await AiClient().call(
        baseUrl: _baseUrlCtrl.text.trim(),
        apiKey: key,
        model: _modelCtrl.text.trim(),
        messages: const [
          {"role": "user", "content": "Reply with exactly: OK"},
        ],
        maxTokens: 10,
      );
      if (!mounted) return;
      final shown = reply.trim().replaceAll("\n", " ");
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsConnected(shown.length > 120 ? "${shown.substring(0, 120)}…" : shown),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsConnectionFailed("$e"))));
    } finally {
      if (mounted) setState(() => _aiTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsStoreProvider);
    final store = ref.read(settingsStoreProvider.notifier);
    _ensureInit(settings);

    if (_baseUrlCtrl.text != settings.aiBaseUrl &&
        !FocusScope.of(context).hasFocus) {
      _baseUrlCtrl.text = settings.aiBaseUrl;
    }

    final scheme = Theme.of(context).colorScheme;
    ShapeBorder sectionShape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: scheme.outlineVariant),
    );
    Widget sectionTitle(String text) => Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: scheme.primary, letterSpacing: 1.2),
    );
    InputBorder fieldBorder() =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(4));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(AppLocalizations.of(context).settingsAppearance),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: settings.appLocale,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsLanguage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context).settingsSystem)),
                      const DropdownMenuItem(value: "en", child: Text("English")),
                      const DropdownMenuItem(value: "ar", child: Text("العربية")),
                    ],
                    onChanged: (v) => store.setAppLocale(v),
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(AppLocalizations.of(context).actionRun),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).settingsRunTimeout(settings.timeoutMs)),
                  Slider(
                    min: 1000,
                    max: 120000,
                    divisions: 119,
                    value: settings.timeoutMs.toDouble().clamp(1000, 120000),
                    label: settings.timeoutMs.toString(),
                    onChanged: (v) => store.setTimeoutMs(v.round()),
                  ),
                  TextField(
                    controller: _timeoutCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsTimeoutLabel,
                      border: fieldBorder(),
                    ),
                    onSubmitted: (v) {
                      final ms = int.tryParse(v.trim());
                      if (ms != null) {
                        store.setTimeoutMs(ms);
                        _timeoutCtrl.text = ms.clamp(1000, 120000).toString();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(AppLocalizations.of(context).settingsEditor),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context).settingsAutocomplete),
                    subtitle: Text(
                      AppLocalizations.of(context).settingsAutocompleteSub,
                    ),
                    value: settings.autocompleteEnabled,
                    onChanged: (v) => store.setAutocompleteEnabled(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context).settingsMatchTheme),
                    subtitle: Text(
                      AppLocalizations.of(context).settingsMatchThemeSub,
                    ),
                    value: settings.followEditorTheme,
                    onChanged: (v) => store.setFollowEditorTheme(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(AppLocalizations.of(context).settingsWordWrap),
                    subtitle: Text(
                      AppLocalizations.of(context).settingsWordWrapSub,
                    ),
                    value: settings.wordWrap,
                    onChanged: (v) => store.setWordWrap(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(AppLocalizations.of(context).settingsAutoSave),
                    subtitle: Text(AppLocalizations.of(context).settingsAutoSaveSub),
                    value: settings.autoSave,
                    onChanged: (v) => store.setAutoSave(v),
                  ),
                  const SizedBox(height: 8),
                  // Warmup: cached url fonts load from disk so the cloud badge
                  // clears without a download; in-memory isLoaded then flips.
                  if (!_fontWarmupDone)
                    Builder(
                      builder: (context) {
                        _fontWarmupDone = true;
                        EditorFontLoader.warmupFromDisk().then((_) {
                          if (mounted) setState(() {});
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: settings.editorFont,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsEditorFont,
                      border: fieldBorder(),
                    ),
                    items: [
                      for (final font in editorFonts)
                        DropdownMenuItem(
                          value: font.id,
                          // No flex inside menu items: the menu lays out with
                          // unbounded width, so Expanded would throw.
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Text(
                                  font.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily:
                                        (font.bundled ||
                                            EditorFontLoader.isLoaded(font.id))
                                        ? fontFamilyFor(font.id) ?? "monospace"
                                        : "monospace",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                (font.bundled ||
                                        EditorFontLoader.isLoaded(font.id))
                                    ? Icons.check
                                    : Icons.cloud_download,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: _fontLoading
                        ? null
                        : (id) async {
                            if (id == null || id == settings.editorFont) return;
                            final needsInstall = !EditorFontLoader.isLoaded(id);
                            final l10n = AppLocalizations.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _fontLoading = true);
                            final ok = await EditorFontLoader.ensureLoaded(id);
                            if (!mounted) return;
                            setState(() => _fontLoading = false);
                            if (ok) {
                              store.setEditorFont(id);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    needsInstall
                                        ? l10n.settingsFontInstalled
                                        : l10n.settingsFontUpdated,
                                  ),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.settingsDownloadFailed,
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                  if (_fontLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).settingsFontSize(settings.editorFontSize.toStringAsFixed(0)),
                  ),
                  Slider(
                    min: 10,
                    max: 24,
                    divisions: 14,
                    value: settings.editorFontSize.clamp(10, 24),
                    label: settings.editorFontSize.toStringAsFixed(0),
                    onChanged: (v) => store.setEditorFontSize(v),
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context).settingsLivePreview),
                  const SizedBox(height: 8),
                  const _EditorPreview(),
                  const _EditorThemePicker(),
                ],
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainer,
            shape: sectionShape(),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(AppLocalizations.of(context).settingsAi),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: aiPresetById(settings.aiProvider) == null
                        ? "custom"
                        : settings.aiProvider,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsProvider,
                      border: fieldBorder(),
                    ),
                    items: [
                      for (final preset in aiPresets)
                        DropdownMenuItem(
                          value: preset.id,
                          child: Text(
                            preset.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      DropdownMenuItem(
                        value: "custom",
                        child: Text(
                          AppLocalizations.of(context).settingsCustomProvider,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (id) async {
                      if (id == null) return;
                      await store.setAiProvider(id);
                      final preset = aiPresetById(id);
                      if (preset != null) {
                        _baseUrlCtrl.text = preset.baseUrl;
                        _modelCtrl.text = preset.model;
                        await store.setAiBaseUrl(preset.baseUrl);
                        await store.setAiModel(preset.model);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _baseUrlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsBaseUrl,
                      hintText: "https://api.openai.com/v1",
                      border: fieldBorder(),
                    ),
                    onSubmitted: (v) {
                      store.setAiBaseUrl(v);
                      store.setAiProvider("custom");
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsModel,
                      hintText: "gpt-4o-mini",
                      border: fieldBorder(),
                    ),
                    onSubmitted: (v) {
                      store.setAiModel(v);
                      store.setAiProvider("custom");
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyCtrl,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).settingsApiKey,
                      hintText: ref.watch(aiKeyProvider).maybeWhen(
                            data: (v) => v,
                            orElse: () => null,
                          ) !=
                          null
                          ? AppLocalizations.of(context).settingsApiKeySaved
                          : AppLocalizations.of(context).settingsApiKeyHint,
                      border: fieldBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).settingsKeySecureNote,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _aiTesting
                        ? null
                        : () => _testAiConnection(context, ref),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: _aiTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_outlined, size: 18),
                    label: Text(
                      _aiTesting ? AppLocalizations.of(context).settingsTesting : AppLocalizations.of(context).settingsTestConnection,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onPressed: () async {
              final l10n = AppLocalizations.of(context);
              await store.setAiBaseUrl(_baseUrlCtrl.text);
              await store.setAiModel(_modelCtrl.text);
              final ms = int.tryParse(_timeoutCtrl.text.trim());
              if (ms != null) await store.setTimeoutMs(ms);
              final key = _apiKeyCtrl.text.trim();
              if (key.isNotEmpty) {
                try {
                  await const FlutterSecureStorage().write(
                    key: kNovaAiKeyStorageKey,
                    value: key,
                  );
                  _apiKeyCtrl.clear();
                  ref.invalidate(aiKeyProvider);
                } catch (_) {
                  // Secure storage unavailable; other settings still saved.
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
              }
            },
            child: Text(AppLocalizations.of(context).actionSave),
          ),
          const SizedBox(height: 8),
          // About card with the platform version/build (see AppInfo).
          // Hidden until loaded so a blank version never shows.
          if (AppInfo.isLoaded)
            Card(
              elevation: 0,
              color: scheme.surfaceContainer,
              shape: sectionShape(),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.info_outline, color: scheme.primary),
                title: Text(AppLocalizations.of(context).settingsAbout),
                subtitle: Text(
                  AppLocalizations.of(context).appVersionBuild(
                    AppInfo.version,
                    AppInfo.buildNumber,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorPreview extends ConsumerStatefulWidget {
  const _EditorPreview();

  @override
  ConsumerState<_EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends ConsumerState<_EditorPreview> {
  static const _sample = '''class User {
  final String name;
  User(this.name);
  String greet(String who) {
    return "hi \$who"; // say hi
  }
}

void main() {
  const retries = 3;
  final user = User("nova");
  print(user.greet("world"));
}
''';

  late final CodeLineEditingController _controller;
  late final CodeScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(_sample);
    _scrollController = CodeScrollController(
      verticalScroller: ScrollController(),
      horizontalScroller: ScrollController(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.verticalScroller.dispose();
    _scrollController.horizontalScroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    ref.watch(editorThemeStoreProvider.select((s) => s.lightPackId));
    ref.watch(editorThemeStoreProvider.select((s) => s.darkPackId));
    final pack = ref
        .read(editorThemeStoreProvider.notifier)
        .packFor(brightness);
    final appSettings = ref.watch(settingsStoreProvider);
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: pack.chrome.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: IgnorePointer(
        child: CodeEditor(
          controller: _controller,
          scrollController: _scrollController,
          style: CodeEditorStyle(
            fontFamily: fontFamilyFor(appSettings.editorFont),
            fontSize: appSettings.editorFontSize,
            textColor: pack.chrome.foreground,
            backgroundColor: pack.chrome.background,
            cursorColor: pack.chrome.cursor,
            selectionColor: pack.chrome.selection,
            codeTheme: CodeHighlightTheme(
              languages: {"dart": CodeHighlightThemeMode(mode: langDart)},
              theme: pack.toHighlightTokens(),
            ),
          ),
          wordWrap: false,
        ),
      ),
    );
  }
}

class _EditorThemePicker extends ConsumerWidget {
  const _EditorThemePicker();

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["json"],
    );
    if (files.isEmpty) return;
    final bytes = await files.first.readAsBytes();
    if (bytes.isEmpty) return;
    String jsonString;
    try {
      jsonString = const Utf8Decoder().convert(bytes);
    } catch (_) {
      jsonString = "";
    }
    if (jsonString.isEmpty || !context.mounted) return;
    final store = ref.read(editorThemeStoreProvider.notifier);
    try {
      final pack = await store.importPack(jsonString);
      await store.setPackFor(pack.brightness, pack.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsThemeImported(pack.name))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.settingsImportFailed("$e"))));
      }
    }
  }

  Future<void> _copyPack(BuildContext context, EditorThemePack pack) async {
    final l10n = AppLocalizations.of(context);
    final json = jsonEncode(pack.toJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsThemeCopied(pack.name))),
      );
    }
  }

  Future<void> _exportPack(BuildContext context, EditorThemePack pack) async {
    final l10n = AppLocalizations.of(context);
    final json = jsonEncode(pack.toJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsThemeExported(pack.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(editorThemeStoreProvider);
    final store = ref.read(editorThemeStoreProvider.notifier);
    final settingsStore = ref.read(settingsStoreProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final packs = store.allPacks;

    final activeId = Theme.of(context).brightness == Brightness.dark
        ? themeState.darkPackId
        : themeState.lightPackId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: packs.any((p) => p.id == activeId) ? activeId : null,
          decoration: InputDecoration(
            labelText: l10n.settingsTheme,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
          items: [
            for (final pack in packs)
              DropdownMenuItem(
                value: pack.id,
                child: Text(
                  pack.brightness == Brightness.light
                      ? "${pack.name} (${l10n.themeLight})"
                      : "${pack.name} (${l10n.themeDark})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) async {
            if (id == null) return;
            final pack = store.allPacks.firstWhere((p) => p.id == id);
            await store.setPackFor(pack.brightness, id);
            await settingsStore.setThemeMode(
              pack.brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
            );
          },
        ),
        const SizedBox(height: 8),
        if (ref.watch(settingsStoreProvider.select((s) => s.themeMode)) !=
            ThemeMode.system)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => settingsStore.setThemeMode(ThemeMode.system),
              icon: const Icon(Icons.brightness_auto_outlined, size: 18),
              label: Text(l10n.themeFollowSystem),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _import(context, ref),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.file_upload_outlined, size: 18),
          label: Text(l10n.settingsImportTheme),
        ),
        for (final pack in themeState.customPacks)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(
                Icons.palette_outlined,
                size: 18,
                color: scheme.primary,
              ),
              title: Text(pack.name, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.settingsCopyTheme,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    onPressed: () => _copyPack(context, pack),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: l10n.settingsExportTheme,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    onPressed: () => _exportPack(context, pack),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: l10n.settingsDeleteTheme,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: scheme.error,
                    ),
                    onPressed: () => store.deleteCustomPack(pack.id),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
