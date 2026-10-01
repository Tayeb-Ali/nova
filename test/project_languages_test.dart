import 'package:nova/src/core/models/project.dart';
import 'package:nova/src/core/services/project_service.dart';
import 'package:nova/src/features/editor/editor_engine.dart';
import 'package:nova/src/features/workspace/task_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('languageForPath', () {
    test('maps new extensions', () {
      expect(EditorTabModel.languageForPath('a.ts'), 'typescript');
      expect(EditorTabModel.languageForPath('A.TSX'), 'typescript');
      expect(EditorTabModel.languageForPath('Main.java'), 'java');
      expect(EditorTabModel.languageForPath('App.kt'), 'kotlin');
      expect(EditorTabModel.languageForPath('main.go'), 'go');
      expect(EditorTabModel.languageForPath('lib.rs'), 'rust');
      expect(EditorTabModel.languageForPath('main.c'), 'c');
      expect(EditorTabModel.languageForPath('a.cpp'), 'cpp');
      expect(EditorTabModel.languageForPath('P.cs'), 'csharp');
      expect(EditorTabModel.languageForPath('A.swift'), 'swift');
      expect(EditorTabModel.languageForPath('a.rb'), 'ruby');
      expect(EditorTabModel.languageForPath('q.sql'), 'sql');
      expect(EditorTabModel.languageForPath('a.css'), 'css');
      expect(EditorTabModel.languageForPath('a.xml'), 'xml');
      expect(EditorTabModel.languageForPath('index.html'), 'xml');
      expect(EditorTabModel.languageForPath('a.yaml'), 'yaml');
      expect(EditorTabModel.languageForPath('run.sh'), 'shell');
      expect(EditorTabModel.languageForPath('x.gradle'), 'gradle');
    });

    test('maps extensionless project files', () {
      expect(EditorTabModel.languageForPath('Dockerfile'), 'dockerfile');
      expect(EditorTabModel.languageForPath('Makefile'), 'makefile');
      expect(EditorTabModel.languageForPath('Gemfile'), 'ruby');
    });

    test('keeps old mappings and plaintext fallback', () {
      expect(EditorTabModel.languageForPath('a.py'), 'python');
      expect(EditorTabModel.languageForPath('a.js'), 'javascript');
      expect(EditorTabModel.languageForPath('notes.txt'), 'plaintext');
      expect(EditorTabModel.languageForPath('noext'), 'plaintext');
    });
  });

  group('detectProjectLanguage', () {
    test('detects from marker files in priority order', () {
      expect(
        TaskDetector.detectProjectLanguage(['pubspec.yaml', 'README.md']),
        'dart',
      );
      expect(
        TaskDetector.detectProjectLanguage(['package.json']),
        'node',
      );
      expect(
        TaskDetector.detectProjectLanguage(['Cargo.toml']),
        'rust',
      );
      expect(
        TaskDetector.detectProjectLanguage(['go.mod']),
        'go',
      );
      expect(
        TaskDetector.detectProjectLanguage(['composer.json']),
        'php',
      );
      expect(
        TaskDetector.detectProjectLanguage(['requirements.txt']),
        'python',
      );
      expect(
        TaskDetector.detectProjectLanguage(['App.sln']),
        'csharp',
      );
      expect(
        TaskDetector.detectProjectLanguage(['build.gradle.kts']),
        'java',
      );
      expect(
        TaskDetector.detectProjectLanguage(['Package.swift']),
        'swift',
      );
      expect(
        TaskDetector.detectProjectLanguage(['CMakeLists.txt']),
        'cpp',
      );
      expect(
        TaskDetector.detectProjectLanguage(['Main.kt']),
        'kotlin',
      );
      expect(
        TaskDetector.detectProjectLanguage(['main.rb']),
        'ruby',
      );
      expect(
        TaskDetector.detectProjectLanguage(['main.c']),
        'c',
      );
    });

    test('detects single-file entry points without a manifest', () {
      expect(TaskDetector.detectProjectLanguage(['main.py']), 'python');
      expect(TaskDetector.detectProjectLanguage(['index.js']), 'node');
      expect(TaskDetector.detectProjectLanguage(['index.php']), 'php');
      expect(TaskDetector.detectProjectLanguage(['Main.java']), 'java');
      expect(TaskDetector.detectProjectLanguage(['main.go']), 'go');
      expect(TaskDetector.detectProjectLanguage(['main.rs']), 'rust');
      expect(TaskDetector.detectProjectLanguage(['main.dart']), 'dart');
      expect(TaskDetector.detectProjectLanguage(['main.cpp']), 'cpp');
    });

    test('manifests win over single-file fallbacks', () {
      expect(
        TaskDetector.detectProjectLanguage(['main.c', 'CMakeLists.txt']),
        'cpp',
      );
      expect(
        TaskDetector.detectProjectLanguage(['main.py', 'requirements.txt']),
        'python',
      );
    });

    test('returns null when ambiguous or unknown', () {
      expect(TaskDetector.detectProjectLanguage(['Makefile']), isNull);
      expect(TaskDetector.detectProjectLanguage(['README.md', '.gitignore']), isNull);
      expect(TaskDetector.detectProjectLanguage([]), isNull);
    });
  });

  group('detect entry points', () {
    Future<List<String>> commandsFor(List<String> files) async {
      final detector = TaskDetector(_FilesService(files));
      const project = ProjectInfo(
        name: "t",
        path: "/data/t",
        language: "general",
      );
      final tasks = await detector.detect(project);
      return [for (final t in tasks) "${t.command} ${t.args ?? ""}".trim()];
    }

    test('go/rust/ruby/dart entry points', () async {
      expect(await commandsFor(["go.mod", "main.go"]), ["go run ."]);
      expect(await commandsFor(["Cargo.toml"]), ["cargo run"]);
      expect(await commandsFor(["main.rb"]), ["ruby main.rb"]);
      expect(await commandsFor(["pubspec.yaml", "main.dart"]), ["dart main.dart"]);
    });

    test('cmake/swift/dotnet markers add build tasks', () async {
      expect(
        await commandsFor(["CMakeLists.txt", "main.cpp"]),
        [
          'sh -c "clang++ main.cpp -o app && ./app"',
          'sh -c "cmake -S . -B build && cmake --build build"',
        ],
      );
      expect(await commandsFor(["Package.swift"]), ["swift run"]);
      expect(await commandsFor(["App.sln"]), ["dotnet run"]);
      expect(await commandsFor(["lib.csproj"]), ["dotnet run"]);
    });

    test('java/kotlin single files use shell wrappers', () async {
      expect(
        await commandsFor(["Main.java"]),
        ['sh -c "javac Main.java && java Main"'],
      );
      expect(
        await commandsFor(["Main.kt"]),
        ['sh -c "kotlinc Main.kt -include-runtime -d app.jar && java -jar app.jar"'],
      );
    });
  });
}

class _FilesService extends ProjectService {
  _FilesService(this.files);

  final List<String> files;

  @override
  Future<List<ProjectInfo>> listProjects() async => const [];

  @override
  Future<void> openProject(String path) async {}

  @override
  Future<List<FileEntry>> listFiles(String path) async => [
        for (final f in files)
          FileEntry(name: f, path: "/data/t/$f", isDirectory: false),
      ];

  @override
  Future<String> readFile(String path) async => "";

  @override
  Future<void> writeFile(String path, String content) async {}
}
