import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/run/termux_installer.dart';

void main() {
  test('Termux sources point at official builds', () {
    expect(TermuxSources.fdroidApkUrl, startsWith('https://f-droid.org/'));
    expect(TermuxSources.fdroidApkUrl, endsWith('.apk'));
    expect(TermuxSources.fdroidPage, contains('f-droid.org'));
    expect(TermuxSources.githubReleases, contains('github.com/termux'));
    expect(TermuxSources.apkFileName, endsWith('.apk'));
  });
}
