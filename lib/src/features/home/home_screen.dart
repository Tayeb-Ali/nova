import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../editor/editor_tab.dart";
import "../files/file_explorer.dart";
import "../files/files_providers.dart";
import "../run/output_panel.dart";
import "../run/run_providers.dart";
import "../run/termux_setup_guide.dart";
import "../ai/ai_actions.dart";
import "../settings/settings_screen.dart";
import "dart:io";

/// Main IDE shell: explorer drawer, tabbed editor, output panel.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(openTabsProvider);
    final activeTab = ref.watch(activeTabModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova"),
        actions: [
          IconButton(
            tooltip: "AI",
            icon: const Icon(Icons.auto_awesome),
            onPressed: activeTab == null
                ? null
                : () async {
                    String code = "";
                    try {
                      code = await ref.read(fileServiceProvider).readFile(File(activeTab.path));
                    } catch (_) {}
                    if (context.mounted) {
                      AiActionsSheet.show(context, selectedCode: code);
                    }
                  },
          ),
          IconButton(
            tooltip: "Settings",
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(
            tooltip: "Run",
            icon: const Icon(Icons.play_arrow),
            onPressed: activeTab == null
                ? null
                : () async {
                    final installed = await ref
                        .read(termuxBridgeProvider)
                        .isTermuxInstalled();
                    if (!context.mounted) return;
                    if (!installed) {
                      showTermuxSetupDialog(context);
                      return;
                    }
                    runCurrentFile(
                      ref,
                      filePath: activeTab.path,
                      language: activeTab.language,
                    );
                  },
          ),
        ],
      ),
      drawer: const FileExplorer(),
      body: Column(
        children: [
          if (tabs.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, i) {
                  final tab = tabs[i];
                  final selected = tab.id == activeTab?.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: InputChip(
                      selected: selected,
                      showCheckmark: false,
                      label: Text(
                        "${p.basename(tab.path)}${tab.dirty ? ' *' : ''}",
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        ref
                            .read(openTabsProvider.notifier)
                            .close(tab.id);
                        if (activeTab?.id == tab.id) {
                          final rest =
                              ref.read(openTabsProvider);
                          ref
                              .read(activeTabProvider.notifier)
                              .state = rest.isEmpty
                                  ? null
                                  : rest.last.id;
                        }
                      },
                      onPressed: () {
                        ref.read(activeTabProvider.notifier).state =
                            tab.id;
                      },
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: activeTab == null
                ? const Center(
                    child: Text(
                      "No file open.\nUse the drawer to browse and open a file.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : EditorTab(
                    key: ValueKey(activeTab.id),
                    tab: activeTab,
                  ),
          ),
        ],
      ),
      bottomSheet: const SizedBox(height: 200, child: OutputPanel()),
    );
  }
}