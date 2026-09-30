import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/models/runtime.dart';

RuntimeInfo _info(String id) =>
    RuntimeInfo(id: id, displayName: id, installed: true);

void main() {
  group('RuntimeInfo packs', () {
    test('nova-* ids are packs, others are not', () {
      for (final id in [
        'nova-web',
        'nova-systems',
        'nova-jvm',
        'nova-python',
        'nova-dart',
      ]) {
        expect(_info(id).isPack, isTrue, reason: id);
        expect(_info(id).displayDescription, isNotEmpty, reason: id);
      }
      for (final id in ['node', 'go', 'git', 'php']) {
        expect(_info(id).isPack, isFalse, reason: id);
      }
    });
  });

  group('RuntimeType new languages', () {
    test('fromId maps every new language', () {
      expect(RuntimeType.fromId('go'), RuntimeType.go);
      expect(RuntimeType.fromId('rust'), RuntimeType.rust);
      expect(RuntimeType.fromId('ruby'), RuntimeType.ruby);
      expect(RuntimeType.fromId('java'), RuntimeType.java);
      expect(RuntimeType.fromId('kotlin'), RuntimeType.kotlin);
      expect(RuntimeType.fromId('dart'), RuntimeType.dart);
    });

    test('new languages grouped under languages with icons', () {
      for (final t in [
        RuntimeType.go,
        RuntimeType.rust,
        RuntimeType.ruby,
        RuntimeType.java,
        RuntimeType.kotlin,
        RuntimeType.dart,
      ]) {
        expect(t.isLanguage, isTrue);
        expect(t.description, isNotEmpty);
      }
      expect(RuntimeType.git.isLanguage, isFalse);
      expect(RuntimeType.composer.isLanguage, isFalse);
    });
  });
}
