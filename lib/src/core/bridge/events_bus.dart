import 'dart:async';

import 'native_bridge.dart';

/// A single shared subscription to the native `sd.adaa.nova/events` channel,
/// fanning out to every consumer.
///
/// Flutter's EventChannel supports effectively one active listener per channel
/// name. When multiple widgets/services call
/// `NativeBridge.events.receiveBroadcastStream()` independently, the newest
/// subscription replaces the platform handler and the native side only keeps
/// one `EventSink`; a `cancel` from any disposing screen sets that sink to
/// null and silently drops events for everyone else. That produced the
/// "install starts then stalls" symptom: runtime progress events never reached
/// the runtime screen. Centralizing the subscription in this bus makes exactly
/// one native `onListen`/`onCancel` pair that lives as long as the process.
class IdeEventBus {
  IdeEventBus._();

  static final IdeEventBus instance = IdeEventBus._();

  late final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  StreamSubscription<dynamic>? _nativeSub;

  /// Broadcast stream of raw native events (each is a [Map]).
  Stream<dynamic> get stream {
    _ensureNativeSubscription();
    return _controller.stream;
  }

  void _ensureNativeSubscription() {
    if (_nativeSub != null) return;
    _nativeSub = NativeBridge.events.receiveBroadcastStream().listen(
      (event) {
        _controller.add(event);
      },
      onError: (Object _) {
        // Events channel errors are non-fatal; keep the stream open.
      },
    );
  }
}