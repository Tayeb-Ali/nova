import '../bridge/events_bus.dart';
import '../bridge/native_bridge.dart';

/// Local web server preview (task.md §22).
class WebPreviewService {
  Stream<String?> get urlStream {
    return IdeEventBus.instance.stream
        .where((e) => e is Map && e['event'] == 'serverDetected')
        .map((e) => (e as Map)['url'] as String?);
  }

  Future<String?> get previewUrl async {
    return NativeBridge.webPreview.previewUrl();
  }
}