import '../bridge/generated/ide_api.g.dart';
import '../bridge/native_bridge.dart';

/// Bootstrap/setup orchestration (task.md §6 §31).
class SetupService {
  Future<SetupStatus> getStatus() => NativeBridge.setup.getStatus();

  Future<void> startSetup() => NativeBridge.setup.startSetup();
}