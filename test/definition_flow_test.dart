import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:nova/app.dart";
import "package:nova/src/core/models/project.dart";
import "package:nova/src/core/services/project_service.dart";
import "package:nova/src/features/lsp/go_lsp_manager.dart";
import "package:nova/src/features/lsp/lsp_client.dart";
import "package:nova/src/features/lsp/lsp_providers.dart";
import "package:nova/src/features/workspace/workspace_providers.dart";

/// In-memory ProjectService: [files] maps full path to content.
class _FakeProjectService extends ProjectService {
  _FakeProjectService(this.files);

  final Map<String, String> files;

  @override
  Future<List<ProjectInfo>> listProjects() async => const [
        ProjectInfo(name: "demo", path: "/data/demo", language: "python"),
      ];

  @override
  Future<List<FileEntry>> listFiles(String path) async {    final prefix = path.endsWith("/") ? path : "$path/";
    final dirs = <String>{};
    final out = <FileEntry>[];
    for (final fp in files.keys) {
      if (!fp.startsWith(prefix)) continue;
      final rest = fp.substring(prefix.length);
      if (rest.isEmpty) continue;
      final slash = rest.indexOf("/");
      if (slash < 0) {
        out.add(
          FileEntry(
            name: rest,
            path: fp,
            isDirectory: false,
            size: files[fp]!.length,
          ),
        );
      } else {
        final dirName = rest.substring(0, slash);
        if (dirs.add(dirName)) {
          out.add(
            FileEntry(
              name: dirName,
              path: "$prefix$dirName",
              isDirectory: true,
            ),
          );
        }
      }
    }
    return out;
  }

  @override
  Future<String> readFile(String path) async {
    final content = files[path];
    if (content == null) throw StateError("missing file $path");
    return content;
  }

  @override
  Future<void> writeFile(String path, String content) async {
    files[path] = content;
  }

  @override
  Future<void> openProject(String path) async {}
}

/// GoLspManager with a canned definition answer (never spawns a server).
class _CannedManager extends GoLspManager {
  _CannedManager(this.location)
      : super(transportFactory: (_) => throw StateError("no spawn"));

  final LspLocation? location;

  @override
  Future<void> didChangeFile(
    String projectPath,
    String filePath,
    String language,
    String text,
  ) async {
    // No-op: syncing to a real server is covered by manager tests.
  }

  @override
  Future<LspLocation?> definitionFor(
    String projectPath,
    String language,
    String filePath,
    int line,
    int character,
  ) async =>
      location;
}

const _project = ProjectInfo(
  name: "demo",
  path: "/data/demo",
  language: "python",
);

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester, {
  required Map<String, String> files,
  required LspLocation? canned,
  required String openPath,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectServiceProvider.overrideWithValue(_FakeProjectService(files)),
        goLspManagerProvider.overrideWithValue(_CannedManager(canned)),
      ],
      child: const NovaApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text("Editor"));
  await tester.pump(const Duration(seconds: 1));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(IdeShell)),
  );
  // Select the project first: definition needs an active project root.
  container.read(activeProjectProvider.notifier).state = _project;
  final id = container.read(workspaceTabsProvider.notifier).open(openPath);
  container.read(activeEditorTabProvider.notifier).state = id;
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  return container;
}

Future<void> _tapDefinition(WidgetTester tester) async {
  // Close the explorer so the tab strip leaves compact mode and renders
  // its action buttons inline (overlay menu taps are not hit-testable).
  await tester.tap(find.byTooltip("Hide explorer"));
  await tester.pump();
  await tester.pump();
  await tester.tap(find.byTooltip("Go to definition"));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Drop focus so re_editor's cursor-blink chain stops, then flush its
/// trailing one-shot timer with plain pumps.
Future<void> _releaseFocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets("fallback opens the defining file and jumps", (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = await _pumpEditor(
      tester,
      canned: null,
      openPath: "/data/demo/main.py",
      files: {
        // `foo` under the caret whether it starts at (0,0) or the end.
        "/data/demo/main.py": "foo()\nfoo",
        "/data/demo/util.py": "def foo():\n    pass\n",
      },
    );

    // Caret sits on `foo` in a fresh editor.
    await _tapDefinition(tester);

    final tabs = container.read(workspaceTabsProvider);
    expect(tabs.any((t) => t.path == "/data/demo/util.py"), isTrue);
    expect(container.read(activeEditorTabProvider), "/data/demo/util.py");
    // The jump consumed the pending line (proves initialLine plumbing ran
    // through open with the resolved line).
    expect(
      container.read(pendingInitialLineProvider).containsKey(
            "/data/demo/util.py",
          ),
      isFalse,
    );
    await _releaseFocus(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets("LSP hit opens the server location", (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = await _pumpEditor(
      tester,
      canned: const LspLocation(path: "/data/demo/other.py", line: 9, character: 2),
      openPath: "/data/demo/main.py",
      files: {
        "/data/demo/main.py": "foo()\nfoo",
      },
    );

    await _tapDefinition(tester);

    final tabs = container.read(workspaceTabsProvider);
    expect(tabs.any((t) => t.path == "/data/demo/other.py"), isTrue);
    expect(container.read(activeEditorTabProvider), "/data/demo/other.py");
    await _releaseFocus(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets("miss shows a toast and opens nothing", (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = await _pumpEditor(
      tester,
      canned: null,
      openPath: "/data/demo/main.py",
      files: {
        "/data/demo/main.py": "foo()\nfoo",
      },
    );

    await _tapDefinition(tester);

    expect(container.read(workspaceTabsProvider), hasLength(1));
    expect(find.text("No definition found for 'foo'"), findsOneWidget);
    await _releaseFocus(tester);
    expect(tester.takeException(), isNull);
  });
}
