import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../bridge/generated/ide_api.g.dart';
import '../bridge/native_bridge.dart';

/// Bootstrap/setup orchestration (task.md §6 §31).
class SetupService {
  Future<SetupStatus> getStatus() => NativeBridge.setup.getStatus();

  Future<void> startSetup() => NativeBridge.setup.startSetup();

  /// Persist the bootstrap variant ("slim" or "full"). The Kotlin installer
  /// reads the same key from FlutterSharedPreferences, so no bridge change
  /// is needed to pass the choice across.
  Future<void> setBootstrapVariant(String variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.bootstrapVariantKey, variant);
  }

  Future<String> getBootstrapVariant() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConfig.bootstrapVariantKey);
    if (stored == AppConfig.bootstrapVariantFull) {
      return AppConfig.bootstrapVariantFull;
    }
    return AppConfig.bootstrapVariantSlim;
  }
}