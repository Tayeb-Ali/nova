import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../core/models/terminal_session.dart';
import '../../core/services/terminal_service.dart';

/// Terminal: interactive PTY shell via xterm (task.md §8–§12).
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _terminalService = TerminalService();
  final _terminalController = TerminalController();

  late final Terminal _terminal;
  late final StreamSubscription<TerminalOutput> _outputSub;
  late final StreamSubscription<TerminalOutput> _exitSub;

  String? _sessionId;
  int _cols = 80;
  int _rows = 24;
  bool _creating = false;
  String? _error;
  String? _exited;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      maxLines: 4000,
      onOutput: _onOutput,
      onResize: _onResize,
      onBell: () => HapticFeedback.selectionClick(),
    );
    _outputSub = _terminalService.outputStream.listen(_onOutputData);
    _exitSub = _terminalService.exitStream.listen(_onExit);
    unawaited(_createSession());
  }

  @override
  void dispose() {
    _outputSub.cancel();
    _exitSub.cancel();
    final sessionId = _sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.close(sessionId));
    }
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final previous = _sessionId;
    setState(() {
      _creating = true;
      _error = null;
      _exited = null;
    });
    if (previous != null) {
      unawaited(_terminalService.close(previous));
    }
    _sessionId = null;
    _terminalController.clearSelection();
    try {
      final sessionId = await _terminalService.createSession(
        cwd: '',
        cols: _cols,
        rows: _rows,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _creating = false;
      });
      unawaited(_terminalService.resize(sessionId, _cols, _rows));
    } on Exception {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = 'Failed to start terminal session';
      });
    }
  }

  /// Terminal <- user input. User typed into xterm; forward to the PTY.
  void _onOutput(String data) {
    final sessionId = _sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.write(sessionId, data));
    }
  }

  /// Terminal dimension change; propagate to the PTY so apps reflow.
  void _onResize(int width, int height, int pixelWidth, int pixelHeight) {
    _cols = width;
    _rows = height;
    final sessionId = _sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.resize(sessionId, width, height));
    }
  }

  /// Terminal <- PTY output. Batched events feed the emulator.
  void _onOutputData(TerminalOutput output) {
    if (output.sessionId != _sessionId) return;
    if (!mounted) return;
    _terminal.write(output.data);
  }

  void _onExit(TerminalOutput output) {
    if (output.exitCode == null || output.sessionId != _sessionId) return;
    if (!mounted) return;
    _terminal.write('\r\n');
    setState(() {
      _exited = 'Session exited (code ${output.exitCode})';
      _sessionId = null;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _terminal.paste(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
        actions: [
          IconButton(
            tooltip: 'New session',
            onPressed: _creating ? null : _createSession,
            icon: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            tooltip: 'Paste',
            onPressed: _paste,
            icon: const Icon(Icons.content_paste_go),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _createSession,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: TerminalView(
            _terminal,
            controller: _terminalController,
            autofocus: true,
            padding: const EdgeInsets.all(8),
          ),
        ),
        if (_exited != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(_exited!)),
                  TextButton(
                    onPressed: _createSession,
                    child: const Text('New session'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}