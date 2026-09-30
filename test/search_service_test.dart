import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:nova/src/core/models/project.dart";
import "package:nova/src/core/services/project_service.dart";
import "package:nova/src/core/services/search_service.dart";
import "package:nova/src/features/search/search_screen.dart";
import "package:nova/src/features/workspace/workspace_providers.dart";

/// In-memory ProjectService: [files] maps full path to content.
/// Directories are implicit from file paths.
class _FakeProjectService extends ProjectService {
  _FakeProjectService(this.files);

  final Map<String, String> files;

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    final prefix = path.endsWith("/") ? path : "$path/";
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
}

Map<String, String> _seed() => {
      "/proj/lib/main.dart": "void main() {\n  print('hello');\n}\n",
      "/proj/lib/util.dart": "String hello() => 'hello world';\n",
      "/proj/README.md": "# hello project\n",
      "/proj/.git/config": "hello should be skipped\n",
      "/proj/node_modules/pkg/index.js": "hello should be skipped\n",
      "/proj/.dart_tool/package_config.json": "hello should be skipped\n",
      "/proj/build/output.dart": "hello should be skipped\n",
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group("search", () {
    test("finds literal hits with 1-based line/column", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final result = await service.search("/proj", "hello");
      // main.dart line 2 (1x), util.dart line 1 (2x), README line 1 (1x).
      expect(result.hits.length, 4);
      expect(result.truncated, isFalse);
      expect(result.filesScanned, 3);
      final main = result.hits.firstWhere(
        (h) => h.path == "/proj/lib/main.dart",
      );
      expect(main.line, 2);
      expect(main.column, 10);
      expect(main.lineText, "  print('hello');");
      expect(main.matchLength, 5);
    });

    test("skips .git, node_modules, .dart_tool, build", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final result = await service.search("/proj", "skipped");
      expect(result.hits, isEmpty);
      expect(result.filesScanned, 3);
    });

    test("case-insensitive by default, sensitive on demand", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final insensitive = await service.search("/proj", "HELLO");
      expect(insensitive.hits.length, 4);
      final sensitive = await service.search(
        "/proj",
        "HELLO",
        const SearchOptions(caseSensitive: true),
      );
      expect(sensitive.hits, isEmpty);
    });

    test("regex mode and invalid regex throws FormatException", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final result = await service.search(
        "/proj",
        "hel+o",
        const SearchOptions(regex: true),
      );
      expect(result.hits.length, 4);
      expect(
        () => service.search(
          "/proj",
          "(unclosed",
          const SearchOptions(regex: true),
        ),
        throwsFormatException,
      );
    });

    test("empty query returns empty result", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final result = await service.search("/proj", "");
      expect(result.hits, isEmpty);
      expect(result.filesScanned, 0);
    });

    test("maxHits truncates", () async {
      final service = SearchService(_FakeProjectService(_seed()));
      final result = await service.search(
        "/proj",
        "hello",
        const SearchOptions(maxHits: 2),
      );
      expect(result.hits.length, 2);
      expect(result.truncated, isTrue);
    });

    test("maxFileSize skips big files", () async {
      final files = _seed()..["/proj/big.txt"] = "hello\n" * 100;
      final service = SearchService(_FakeProjectService(files));
      final result = await service.search(
        "/proj",
        "hello",
        const SearchOptions(maxFileSize: 16),
      );
      expect(
        result.hits.any((h) => h.path == "/proj/big.txt"),
        isFalse,
      );
    });
  });

  group("replace", () {
    test("replaceInFile counts and writes; no match writes nothing", () async {
      final files = _seed();
      final fake = _FakeProjectService(files);
      final service = SearchService(fake);
      final count = await service.replaceInFile(
        path: "/proj/lib/util.dart",
        query: "hello",
        replacement: "hi",
      );
      expect(count, 2);
      expect(files["/proj/lib/util.dart"], "String hi() => 'hi world';\n");

      final before = files["/proj/README.md"];
      final zero = await service.replaceInFile(
        path: "/proj/README.md",
        query: "missing",
        replacement: "x",
      );
      expect(zero, 0);
      expect(files["/proj/README.md"], before);
    });

    test("replaceAll totals per-file counts and skips excluded dirs",
        () async {
      final files = _seed();
      final service = SearchService(_FakeProjectService(files));
      final outcome = await service.replaceAll(
        rootPath: "/proj",
        query: "hello",
        replacement: "hi",
      );
      expect(outcome.totalReplacements, 4);
      expect(outcome.perFile.length, 3);
      expect(files["/proj/lib/main.dart"], contains("hi"));
      expect(files["/proj/.git/config"], contains("hello"));
    });
  });

  group("search screen helpers", () {
    test("searchHitPreview swaps the matched range", () {
      const hit = SearchHit(
        path: "/proj/a.dart",
        line: 2,
        column: 10,
        lineText: "  print('hello');",
        matchLength: 5,
      );
      expect(searchHitPreview(hit, "hi"), "  print('hi');");
    });
  });

  group("workspace open with initial line", () {
    test("open records pending line; takeInitialLine consumes it", () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);
      final id = notifier.open("/proj/lib/main.dart", initialLine: 41);
      expect(container.read(pendingInitialLineProvider)[id], 41);
      expect(notifier.takeInitialLine(id), 41);
      expect(container.read(pendingInitialLineProvider).containsKey(id),
          isFalse);
      expect(notifier.takeInitialLine(id), isNull);
    });

    test("open without a line stores nothing", () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final id = container
          .read(workspaceTabsProvider.notifier)
          .open("/proj/lib/main.dart");
      expect(container.read(pendingInitialLineProvider).containsKey(id),
          isFalse);
    });
  });
}
