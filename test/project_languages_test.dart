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
    });

    test('returns null when ambiguous or unknown', () {
      expect(TaskDetector.detectProjectLanguage(['Makefile']), isNull);
      expect(TaskDetector.detectProjectLanguage(['main.c']), isNull);
      expect(TaskDetector.detectProjectLanguage([]), isNull);
    });
  });
}
