import '../bridge/native_bridge.dart';
import '../models/runtime.dart';

/// Runtime install/query through the embedded apt environment (task.md §13–§17).
class RuntimeService {
  Future<List<RuntimeInfo>> getRuntimes() async {
    final list = await NativeBridge.runtime.getRuntimes();
    return list.map(RuntimeInfo.fromBridge).toList();
  }

  Future<RuntimeInfo> getRuntime(String id) async {
    final info = await NativeBridge.runtime.getRuntime(id);
    return RuntimeInfo.fromBridge(info);
  }

  Future<void> install(String id) => NativeBridge.runtime.installRuntime(id);

  Future<void> uninstall(String id) => NativeBridge.runtime.uninstallRuntime(id);

  Future<void> update(String id) => NativeBridge.runtime.updateRuntime(id);
}