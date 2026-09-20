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

/// Light terminal palette mirroring VSCode Light+; dark mode keeps
/// xterm's default theme.
const _lightTerminalTheme = TerminalTheme(
  cursor: Color(0xFF000000),
  selection: Color(0xFFADD6FF),
  foreground: Color(0xFF000000),
  background: Color(0xFFFFFFFF),
  black: Color(0xFF000000),
  red: Color(0xFFCD3131),
  green: Color(0xFF00BC00),
  yellow: Color(0xFF949800),
  blue: Color(0xFF0451A5),
  magenta: Color(0xFFBC05BC),
  cyan: Color(0xFF0598BC),
  white: Color(0xFF555555),
  brightBlack: Color(0xFF666666),
  brightRed: Color(0xFFCD3131),
  brightGreen: Color(0xFF14CE14),
  brightYellow: Color(0xFFB5BA00),
  brightBlue: Color(0xFF0451A5),
  brightMagenta: Color(0xFFBC05BC),
  brightCyan: Color(0xFF0598BC),
  brightWhite: Color(0xFFA5A5A5),
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: Color(0xFF000000),
);

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

  /// Compact accessory bar with keys missing from mobile soft keyboards
  /// (Tab/Esc/Ctrl/arrows). Sends raw bytes via [_onOutput] like xterm input.
  Widget _buildAccessoryBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _accessoryTextKey('Tab', '\t'),
            _accessoryTextKey('Esc', '\x1b'),
            _accessoryTextKey('^C', '\x03'),
            _accessoryIconKey(
              Icons.keyboard_arrow_up,
              'Up',
              '\x1b[A',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_down,
              'Down',
              '\x1b[B',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_left,
              'Left',
              '\x1b[D',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_right,
              'Right',
              '\x1b[C',
            ),
            _accessoryTextKey('|', '|'),
            _accessoryTextKey('~', '~'),
            _accessoryTextKey('/', '/'),
          ],
        ),
      ),
    );
  }

  /// Small filled-tonal button (height ~36) showing a short text label.
  Widget _accessoryTextKey(String label, String data) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        height: 36,
        child: FilledButton.tonal(
          onPressed: () => _onOutput(data),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  /// Small filled-tonal button (height ~36) showing an arrow icon.
  Widget _accessoryIconKey(IconData icon, String tooltip, String data) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        height: 36,
        child: FilledButton.tonal(
          onPressed: () => _onOutput(data),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Icon(icon, size: 18, semanticLabel: tooltip),
        ),
      ),
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
    return Column(
      children: [
        _buildAccessoryBar(),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: TerminalView(
                  _terminal,
                  controller: _terminalController,
                  autofocus: true,
                  padding: const EdgeInsets.all(8),
                  theme: Theme.of(context).brightness == Brightness.dark
                      ? TerminalThemes.defaultTheme
                      : _lightTerminalTheme,
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
          ),
        ),
      ],
    );
  }
}