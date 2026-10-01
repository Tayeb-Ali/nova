import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nova/src/core/services/app_info_service.dart';

void main() {
  setUp(AppInfo.debugReset);
  tearDown(AppInfo.debugReset);

  test('starts unloaded with empty values', () {
    expect(AppInfo.isLoaded, isFalse);
    expect(AppInfo.version, '');
    expect(AppInfo.buildNumber, '');
  });

  test('picks up the platform package values when available', () async {
    PackageInfo.setMockInitialValues(
      appName: 'nova',
      packageName: 'sd.adaa.codeide',
      version: '9.9.9',
      buildNumber: '42',
      buildSignature: '',
    );
    await AppInfo.load();
    expect(AppInfo.isLoaded, isTrue);
    expect(AppInfo.version, '9.9.9');
    expect(AppInfo.buildNumber, '42');
  });
}
