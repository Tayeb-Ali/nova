import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/dart.dart";

import "../../core/settings_store.dart";
import "../editor/theme/editor_fonts.dart";
import "../editor/theme/theme_pack_store.dart";

// Settings UI: theme, run timeout, AI endpoint and model.
// API key is owned by the AI feature via secure storage, so this screen
// only edits base URL and model. Key field is an optional placeholder.
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsStoreProvider);
    final store = ref.read(settingsStoreProvider.notifier);
    _ensureInit(settings);

    // Keep controllers in sync when state changes externally.
    if (_baseUrlCtrl.text != settings.aiBaseUrl &&
        !FocusScope.of(context).hasFocus) {
      _baseUrlCtrl.text = settings.aiBaseUrl;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Appearance"),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text("System")),
              ButtonSegment(value: ThemeMode.light, label: Text("Light")),
              ButtonSegment(value: ThemeMode.dark, label: Text("Dark")),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (sel) => store.setThemeMode(sel.first),
          ),
          const SizedBox(height: 24),
          Text("Run timeout: ${settings.timeoutMs} ms"),
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
            decoration: const InputDecoration(
              labelText: "Timeout (ms, 1000-120000)",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final ms = int.tryParse(v.trim());
              if (ms != null) {
                store.setTimeoutMs(ms);
                _timeoutCtrl.text = ms.clamp(1000, 120000).toString();
              }
            },
          ),
          const SizedBox(height: 24),
          const Text("Editor"),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Autocomplete"),
            subtitle: const Text(
                "Keyword, snippet and word suggestions while typing"),
            value: settings.autocompleteEnabled,
            onChanged: (v) => store.setAutocompleteEnabled(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Match app to editor theme"),
            subtitle: const Text(
                "Whole app follows the editor theme colors"),
            value: settings.followEditorTheme,
            onChanged: (v) => store.setFollowEditorTheme(v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.editorFont,
            decoration: const InputDecoration(
              labelText: "Editor font",
              border: OutlineInputBorder(),
            ),
            items: [
              for (final font in editorFonts)
                DropdownMenuItem(
                  value: font.id,
                  child: Text(
                    font.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: fontFamilyFor(font.id) ?? "monospace",
                    ),
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) store.setEditorFont(id);
            },
          ),
          const SizedBox(height: 8),
          Text("Font size: ${settings.editorFontSize.toStringAsFixed(0)}"),
          Slider(
            min: 10,
            max: 24,
            divisions: 14,
            value: settings.editorFontSize.clamp(10, 24),
            label: settings.editorFontSize.toStringAsFixed(0),
            onChanged: (v) => store.setEditorFontSize(v),
          ),
          const SizedBox(height: 4),
          const Text("Live preview"),
          const SizedBox(height: 8),
          const _EditorPreview(),
          const _EditorThemePicker(),
          const SizedBox(height: 24),
          const Text("AI"),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: "Base URL (OpenAI compatible)",
              hintText: "https://api.openai.com/v1",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => store.setAiBaseUrl(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(
              labelText: "Model",
              hintText: "gpt-4o-mini",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => store.setAiModel(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "API key (managed by AI feature)",
              hintText: "Optional placeholder",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Note: key persistence uses secure storage and is implemented by the AI agent.",
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await store.setAiBaseUrl(_baseUrlCtrl.text);
              await store.setAiModel(_modelCtrl.text);
              final ms = int.tryParse(_timeoutCtrl.text.trim());
              if (ms != null) await store.setTimeoutMs(ms);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Settings saved")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

/// Live read-only editor preview: shows exactly how code will look with
/// the current font, size and theme pack.
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
    final pack =
        ref.read(editorThemeStoreProvider.notifier).packFor(brightness);
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
              languages: {
                "dart": CodeHighlightThemeMode(mode: langDart),
              },
              theme: pack.toHighlightTokens(),
            ),
          ),
          wordWrap: false,
        ),
      ),
    );
  }
}

/// Editor theme picker: light/dark packs, JSON import, custom deletion.
class _EditorThemePicker extends ConsumerWidget {
  const _EditorThemePicker();

  Future<void> _import(BuildContext context, WidgetRef ref) async {
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
          SnackBar(content: Text('Theme "${pack.name}" imported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(editorThemeStoreProvider);
    final store = ref.read(editorThemeStoreProvider.notifier);
    final packs = store.allPacks;
    Widget dropdown(String label, String value, Brightness brightness) {
      return DropdownButtonFormField<String>(
        initialValue: packs.any((p) => p.id == value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final pack in packs)
            DropdownMenuItem(
              value: pack.id,
              child: Text(
                "${pack.name} (${pack.brightness == Brightness.light ? "light" : "dark"})",
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (id) {
          if (id != null) store.setPackFor(brightness, id);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        dropdown("Light theme", themeState.lightPackId, Brightness.light),
        const SizedBox(height: 12),
        dropdown("Dark theme", themeState.darkPackId, Brightness.dark),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _import(context, ref),
          icon: const Icon(Icons.file_upload_outlined, size: 18),
          label: const Text("Import theme JSON"),
        ),
        for (final pack in themeState.customPacks)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.palette_outlined, size: 18),
            title: Text(pack.name, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: "Delete theme",
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => store.deleteCustomPack(pack.id),
            ),
          ),
      ],
    );
  }
}
