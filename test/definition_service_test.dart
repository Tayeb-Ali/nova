import "package:flutter_test/flutter_test.dart";

import "package:nova/src/core/models/project.dart";
import "package:nova/src/core/services/project_service.dart";
import "package:nova/src/core/services/search_service.dart";
import "package:nova/src/features/lsp/definition_service.dart";
import "package:nova/src/features/lsp/go_lsp_manager.dart";
import "package:nova/src/features/lsp/lsp_client.dart";

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

/// GoLspManager with a canned definition answer (no server spawned).
/// Uses an unregistered flow for didChange: `ensureForLanguage` throws
/// for unknown languages and the base methods swallow it.
class _CannedManager extends GoLspManager {
  _CannedManager(this.location)
      : super(transportFactory: (_) => throw StateError("no spawn"));

  final LspLocation? location;

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

DefinitionService _service({
  LspLocation? location,
  required Map<String, String> files,
}) {
  return DefinitionService(
    lsp: _CannedManager(location),
    search: SearchService(_FakeProjectService(files)),
  );
}

Future<DefinitionTarget?> _resolve(
  DefinitionService service, {
  String language = "python",
  String file = "/proj/main.py",
  int line = 1,
  int char = 0,
  String word = "foo",
}) {
  return service.resolve(
    projectPath: "/proj",
    language: language,
    filePath: file,
    line: line,
    character: char,
    word: word,
  );
}

Future<List<DefinitionTarget>> _resolveAll(
  DefinitionService service, {
  String language = "python",
  String file = "/proj/main.py",
  int line = 1,
  int char = 0,
  String word = "foo",
}) {
  return service.resolveAll(
    projectPath: "/proj",
    language: language,
    filePath: file,
    line: line,
    character: char,
    word: word,
  );
}

void main() {
  group("wordAtCaret", () {
    test("extracts a call name", () {
      expect(wordAtCaret("foo(", 3), "foo");
      expect(wordAtCaret("  foo(", 5), "foo");
    });

    test("caret in the middle still finds the word", () {
      expect(wordAtCaret("foo(", 1), "foo");
    });

    test("strips one PHP dollar", () {
      expect(wordAtCaret(r"$request->inp", 5), "request");
      expect(wordAtCaret(r"$request->inp", 12), "inp");
    });

    test("returns null off-word", () {
      expect(wordAtCaret("foo(1, 2)", 6), isNull);
      expect(wordAtCaret("", 0), isNull);
      expect(wordAtCaret(r"$", 1), isNull);
    });
  });

  group("resolve via LSP", () {
    test("server hit wins over text", () async {
      final service = _service(
        location: const LspLocation(path: "/proj/b.py", line: 4, character: 0),
        files: {
          "/proj/main.py": "foo()\n",
          "/proj/b.py": "import x\ndef foo():\n    pass\n",
        },
      );
      final target = await _resolve(service);
      expect(target, isNotNull);
      expect(target!.path, "/proj/b.py");
      expect(target.line, 4);
    });
  });

  group("resolve via text fallback", () {
    test("finds a python def in another file", () async {
      final service = _service(files: {
        "/proj/main.py": "from util import foo\nfoo()\n",
        "/proj/util.py": "def foo():\n    pass\n",
      });
      final target = await _resolve(service, line: 1);
      expect(target, isNotNull);
      expect(target!.path, "/proj/util.py");
      expect(target.line, 0);
    });

    test("prefers the current file", () async {
      final service = _service(files: {
        "/proj/main.py": "def foo():\n    pass\nfoo()\n",
        "/proj/util.py": "def foo():\n    pass\n",
      });
      final target = await _resolve(service, line: 2);
      expect(target, isNotNull);
      expect(target!.path, "/proj/main.py");
      expect(target.line, 0);
    });

    test("finds a C-style signature", () async {
      final service = _service(files: {
        "/proj/main.dart": "void main() {\n  greet();\n}\n",
        "/proj/util.dart": "String greet() => 'hi';\n",
      });
      final target = await _resolve(
        service,
        language: "dart",
        file: "/proj/main.dart",
        line: 1,
        word: "greet",
      );
      expect(target, isNotNull);
      expect(target!.path, "/proj/util.dart");
      expect(target.line, 0);
    });

    test("finds a JS const declarator", () async {
      final service = _service(files: {
        "/proj/a.js": "run();\n",
        "/proj/b.js": "const run = () => {};\n",
      });
      final target = await _resolve(
        service,
        language: "javascript",
        file: "/proj/a.js",
        line: 0,
        word: "run",
      );
      expect(target, isNotNull);
      expect(target!.path, "/proj/b.js");
    });

    test("returns null when nothing matches", () async {
      final service = _service(files: {
        "/proj/main.py": "foo()\n",
        "/proj/util.py": "x = 1\n",
      });
      expect(await _resolve(service, line: 0), isNull);
    });

    test("empty word resolves to null without searching", () async {
      final service = _service(files: const {});
      expect(await _resolve(service, word: ""), isNull);
    });
  });

  group("resolveAll", () {
    test("LSP hit comes first, then text hits", () async {
      final service = _service(
        location: const LspLocation(path: "/proj/b.py", line: 4, character: 0),
        files: {
          "/proj/main.py": "foo()\n",
          "/proj/c.py": "def foo():\n    pass\n",
        },
      );
      final targets = await _resolveAll(service, line: 0);
      expect(targets, hasLength(2));
      expect(targets[0].path, "/proj/b.py");
      expect(targets[0].line, 4);
      expect(targets[1].path, "/proj/c.py");
      expect(targets[1].line, 0);
    });

    test("dedupes an LSP hit also found by text search", () async {
      final service = _service(
        location:
            const LspLocation(path: "/proj/util.py", line: 0, character: 0),
        files: {
          "/proj/main.py": "foo()\n",
          "/proj/util.py": "def foo():\n    pass\n",
        },
      );
      final targets = await _resolveAll(service, line: 0);
      expect(targets, hasLength(1));
      expect(targets.single.path, "/proj/util.py");
      expect(targets.single.line, 0);
    });

    test("same-file text hits come before other files", () async {
      final service = _service(files: {
        "/proj/main.py": "def foo():\n    pass\nfoo()\n",
        "/proj/util.py": "def foo():\n    pass\n",
      });
      final targets = await _resolveAll(service, line: 2);
      expect(targets, hasLength(2));
      expect(targets[0].path, "/proj/main.py");
      expect(targets[1].path, "/proj/util.py");
    });

    test("caps the list so the picker stays tappable", () async {
      final files = <String, String>{"/proj/main.py": "foo()\n"};
      for (var i = 0; i < 10; i++) {
        files["/proj/f$i.py"] = "def foo():\n    pass\n";
      }
      final targets = await _resolveAll(_service(files: files), line: 0);
      expect(targets, hasLength(8));
      final paths = targets.map((t) => t.path).toSet();
      expect(paths, hasLength(8));
      expect(paths, contains("/proj/f0.py"));
      expect(paths, isNot(contains("/proj/f9.py")));
    });

    test("empty word and misses resolve to an empty list", () async {
      final empty = _service(files: const {});
      expect(await _resolveAll(empty, word: ""), isEmpty);
      final miss = _service(files: {
        "/proj/main.py": "foo()\n",
        "/proj/util.py": "x = 1\n",
      });
      expect(await _resolveAll(miss, line: 0), isEmpty);
    });
  });
}
