import 'package:flutter/services.dart';

import '../app_config.dart';
import 'generated/ide_api.g.dart';

/// Type-safe access to the native (Kotlin) IdeBridge layer (task.md §27).
/// All heavy work happens on the Android side; Flutter only orchestrates.
abstract final class NativeBridge {
  static final SetupApi setup = SetupApi();
  static final RuntimeApi runtime = RuntimeApi();
  static final TerminalApi terminal = TerminalApi();
  static final ProcessApi process = ProcessApi();
  static final ProjectApi project = ProjectApi();
  static final FileApi files = FileApi();
  static final GitApi git = GitApi();
  static final WebPreviewApi webPreview = WebPreviewApi();

  static const EventChannel events = EventChannel(AppConfig.eventsChannel);
}