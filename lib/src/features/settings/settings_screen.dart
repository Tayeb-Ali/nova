import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/settings_store.dart";

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
