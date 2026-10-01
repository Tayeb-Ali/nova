import 'dart:async';
import 'dart:convert';

import '../../core/services/process_service.dart';
import 'lsp_client.dart';

/// [LspTransport] over a managed process with piped stdio.
///
/// Spawns the server via [ProcessService] with `mergeStderr: false` so
/// stdout stays clean LSP JSON-RPC (framed with `Content-Length` headers).
/// Server stdout arrives through [ProcessService.eventStream] (filtered by
/// pid); stdin writes are base64-encoded and chunked at 32KB per Pigeon call.
class ProcessTransport implements LspTransport {
  ProcessTransport({
    required this.command,
    required this.args,
    required this.cwd,
    Map<String, String>? environment,
    ProcessService? processes,
    Stream<ProcessEvent>? events,
  })  : _environment = environment ?? const {},
        _processes = processes ?? ProcessService(),
        _eventsOverride = events;

  /// Max base64 payload per `writeProcessStdin` call.
  static const int kWriteChunkSize = 32 * 1024;

  final String command;
  final List<String> args;
  final String cwd;
  final Map<String, String> _environment;
  final ProcessService _processes;
  final Stream<ProcessEvent>? _eventsOverride;

  /// Event source: injected override in tests, live bus stream on device.
  Stream<ProcessEvent> get _events =>
      _eventsOverride ?? _processes.eventStream;

  final StreamController<String> _incomingController =
      StreamController<String>.broadcast();
  StreamSubscription<ProcessEvent>? _eventSub;
  String? _pid;
  final StringBuffer _buffer = StringBuffer();
  int? _pendingLength;

  @override
  Stream<String> get incoming => _incomingController.stream;

  @override
  Future<void> start() async {
    final info = await _processes.start(
      command: command,
      args: args,
      cwd: cwd,
      environment: _environment,
      mergeStderr: false,
    );
    _pid = info.pid;
    _eventSub = _events
        .where((e) => e.pid == _pid && !e.exited && e.output.isNotEmpty)
        .listen(_onChunk);
  }

  @override
  void send(String message) {
    final pid = _pid;
    if (pid == null) return;
    final framed = 'Content-Length: ${message.length}\r\n\r\n$message';
    final encoded = base64Encode(utf8.encode(framed));
    for (var i = 0; i < encoded.length; i += kWriteChunkSize) {
      final end = (i + kWriteChunkSize < encoded.length)
          ? i + kWriteChunkSize
          : encoded.length;
      // Fire-and-forget: ordering is preserved per Pigeon channel and the
      // server only reacts to complete framed messages.
      unawaited(_processes.writeStdin(pid, encoded.substring(i, end)));
    }
  }

  @override
  Future<void> stop() async {
    await _eventSub?.cancel();
    _eventSub = null;
    final pid = _pid;
    _pid = null;
    if (pid != null) {
      try {
        await _processes.kill(pid);
      } catch (_) {
        // Best effort: the server may already be gone.
      }
    }
    await _incomingController.close();
  }

  void _onChunk(ProcessEvent event) {
    _buffer.write(event.output);
    while (true) {
      if (_pendingLength == null) {
        final text = _buffer.toString();
        final headerEnd = text.indexOf('\r\n\r\n');
        if (headerEnd < 0) return;
        final headers = text.substring(0, headerEnd);
        final match = RegExp(r'Content-Length:\s*(\d+)', caseSensitive: false)
            .firstMatch(headers);
        if (match == null) {
          // Not an LSP frame (stray log line): drop the header block.
          _buffer.clear();
          _buffer.write(text.substring(headerEnd + 4));
          continue;
        }
        _pendingLength = int.parse(match.group(1)!);
        final rest = text.substring(headerEnd + 4);
        _buffer.clear();
        _buffer.write(rest);
      }
      final text = _buffer.toString();
      final length = _pendingLength!;
      if (text.length < length) return;
      _pendingLength = null;
      final message = text.substring(0, length);
      _buffer.clear();
      _buffer.write(text.substring(length));
      if (!_incomingController.isClosed) {
        _incomingController.add(message);
      }
    }
  }
}
