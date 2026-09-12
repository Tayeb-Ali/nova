import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;

import "../editor/editor_tab.dart";
import "../files/file_explorer.dart";
import "../files/files_providers.dart";
// ignore: uri_does_not_exist
import "../run/output_panel.dart";
// ignore: uri_does_not_exist
import "../run/run_providers.dart";

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
            tooltip: "Run",
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // Implemented by the run agent in ../run/run_providers.dart
              // as: Future<void> runCurrentFile(WidgetRef ref, String? path)
                            runCurrentFile(ref, activeTab?.path); // ignore: undefined_method
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
      bottomSheet: SizedBox(height: 200, child: OutputPanel()); // ignore: undefined_method
    );
  }
}