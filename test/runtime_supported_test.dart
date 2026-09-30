import 'package:flutter_test/flutter_test.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/models/runtime.dart';

void main() {
  test('fromBridge passes supported=false through', () {
    final info = RuntimeInfo.fromBridge(bridge.RuntimeInfo(
      id: 'go',
      displayName: 'Go',
      installed: false,
      supported: false,
    ));
    expect(info.isSupported, isFalse);
  });

  test('fromBridge passes supported=true through', () {
    final info = RuntimeInfo.fromBridge(bridge.RuntimeInfo(
      id: 'ruby',
      displayName: 'Ruby',
      installed: false,
      supported: true,
    ));
    expect(info.isSupported, isTrue);
  });

  test('null supported (old hosts) means supported', () {
    final info = RuntimeInfo(id: 'go', displayName: 'Go');
    expect(info.isSupported, isTrue);
  });
}
