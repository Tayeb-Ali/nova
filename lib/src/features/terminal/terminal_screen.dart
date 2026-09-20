import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
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

/// Per-tab PTY state. Each tab owns its xterm [Terminal] (scrollback +
/// emulator state) and its own [TerminalController] (per-view selection),
/// plus the native session id and per-tab error/exited banners.
class _TerminalTab {
  _TerminalTab({
    required this.title,
    required this.terminal,
    required this.controller,
  });

  final String title;
  final Terminal terminal;
  final TerminalController controller;
  String? sessionId;
  bool creating = true;
  String? error;
  String? exited;
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _terminalService = TerminalService();
  final List<_TerminalTab> _tabs = [];

  late final StreamSubscription<TerminalOutput> _outputSub;
  late final StreamSubscription<TerminalOutput> _exitSub;

  static const int _maxTabs = 5;

  int _activeIndex = 0;
  int _nextNumber = 1;
  int _cols = 80;
  int _rows = 24;

  _TerminalTab? get _activeTab =>
      _tabs.isEmpty ? null : _tabs[_activeIndex.clamp(0, _tabs.length - 1)];

  @override
  void initState() {
    super.initState();
    _outputSub = _terminalService.outputStream.listen(_onOutputData);
    _exitSub = _terminalService.exitStream.listen(_onExit);
    _addTab();
  }

  @override
  void dispose() {
    _outputSub.cancel();
    _exitSub.cancel();
    for (final tab in _tabs) {
      final sessionId = tab.sessionId;
      tab.sessionId = null;
      if (sessionId != null) {
        unawaited(_terminalService.close(sessionId));
      }
      tab.controller.dispose();
    }
    super.dispose();
  }

  void _addTab() {
    if (_tabs.length >= _maxTabs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 5 terminal tabs reached')),
      );
      return;
    }
    late final _TerminalTab tab;
    final terminal = Terminal(
      maxLines: 4000,
      onOutput: (data) => _onTabInput(tab, data),
      onResize: (width, height, pixelWidth, pixelHeight) =>
          _onTabResize(tab, width, height),
      onBell: () => HapticFeedback.selectionClick(),
    );
    tab = _TerminalTab(
      title: 'Terminal ${_nextNumber++}',
      terminal: terminal,
      controller: TerminalController(),
    );
    setState(() {
      _tabs.add(tab);
      _activeIndex = _tabs.length - 1;
    });
    unawaited(_createSessionFor(tab));
  }

  Future<void> _createSessionFor(_TerminalTab tab) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      tab.creating = true;
      tab.error = null;
      tab.exited = null;
    });
    tab.controller.clearSelection();
    try {
      final sessionId = await _terminalService.createSession(
        cwd: '',
        cols: _cols,
        rows: _rows,
      );
      if (!mounted) return;
      // Tab may have been closed while the session was being created.
      if (!_tabs.contains(tab)) {
        unawaited(_terminalService.close(sessionId));
        return;
      }
      setState(() {
        tab.sessionId = sessionId;
        tab.creating = false;
      });
      unawaited(_terminalService.resize(sessionId, _cols, _rows));
    } on Exception {
      if (!mounted) return;
      if (!_tabs.contains(tab)) return;
      setState(() {
        tab.creating = false;
        tab.error = l10n.terminalStartFailed;
      });
    }
  }

  void _switchTo(int index) {
    if (index == _activeIndex) return;
    setState(() {
      _activeIndex = index;
    });
    final tab = _activeTab;
    final sessionId = tab?.sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.resize(sessionId, _cols, _rows));
    }
  }

  void _closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final tab = _tabs[index];
    final sessionId = tab.sessionId;
    tab.sessionId = null;
    if (sessionId != null) {
      unawaited(_terminalService.close(sessionId));
    }
    tab.controller.dispose();
    setState(() {
      _tabs.removeAt(index);
      if (_tabs.isEmpty) {
        _activeIndex = 0;
      } else if (_activeIndex >= _tabs.length) {
        _activeIndex = _tabs.length - 1;
      } else if (index < _activeIndex) {
        _activeIndex -= 1;
      }
    });
    if (_tabs.isEmpty) {
      _addTab();
      return;
    }
    final active = _activeTab;
    final activeSession = active?.sessionId;
    if (activeSession != null) {
      unawaited(_terminalService.resize(activeSession, _cols, _rows));
    }
  }

  /// Terminal <- user input. User typed into xterm; forward to the PTY.
  void _onTabInput(_TerminalTab tab, String data) {
    final sessionId = tab.sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.write(sessionId, data));
    }
  }

  /// Terminal dimension change; propagate to the PTY so apps reflow.
  void _onTabResize(_TerminalTab tab, int width, int height) {
    _cols = width;
    _rows = height;
    final sessionId = tab.sessionId;
    if (sessionId != null) {
      unawaited(_terminalService.resize(sessionId, width, height));
    }
  }

  /// Terminal <- PTY output. Batched events feed the emulator.
  void _onOutputData(TerminalOutput output) {
    if (!mounted) return;
    for (final tab in _tabs) {
      if (tab.sessionId != null && output.sessionId == tab.sessionId) {
        tab.terminal.write(output.data);
        return;
      }
    }
  }

  void _onExit(TerminalOutput output) {
    final int? code = output.exitCode;
    if (code == null) return;
    if (!mounted) return;
    for (final tab in _tabs) {
      if (tab.sessionId != null && output.sessionId == tab.sessionId) {
        tab.terminal.write('\r\n');
        setState(() {
          tab.exited = AppLocalizations.of(context).terminalSessionExited(code);
          tab.sessionId = null;
        });
        return;
      }
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _activeTab?.terminal.paste(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _activeTab?.creating ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).terminalTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).terminalNewSession,
            onPressed: creating ? null : _addTab,
            icon: creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).terminalPaste,
            onPressed: _paste,
            icon: const Icon(Icons.content_paste_go),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Slim tab strip in the editor tabs language: 4px chips with a 2px
  /// primary underline under the active tab, x to close any tab, + to add.
  Widget _buildTabStrip() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _tabs.length; i++) _tabChip(i),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: IconButton(
                tooltip: 'Add terminal',
                visualDensity: VisualDensity.compact,
                onPressed: _tabs.length >= _maxTabs ? null : _addTab,
                icon: const Icon(Icons.add, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(int index) {
    final tab = _tabs[index];
    final selected = index == _activeIndex;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _switchTo(index),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.surfaceContainerHigh
                    : scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => _closeTab(index),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Active tab 2px primary underline (DESIGN.md tabs language).
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 2),
            color: selected ? scheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  /// Compact accessory bar with keys missing from mobile soft keyboards
  /// (Tab/Esc/Ctrl/arrows). Sends raw bytes via [_onTabInput] like xterm input.
  Widget _buildAccessoryBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _accessoryTextKey(l10n.terminalKeyTab, '\t'),
            _accessoryTextKey(l10n.terminalKeyEsc, '\x1b'),
            _accessoryTextKey('^C', '\x03'),
            _accessoryIconKey(
              Icons.keyboard_arrow_up,
              l10n.terminalKeyUp,
              '\x1b[A',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_down,
              l10n.terminalKeyDown,
              '\x1b[B',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_left,
              l10n.terminalKeyLeft,
              '\x1b[D',
            ),
            _accessoryIconKey(
              Icons.keyboard_arrow_right,
              l10n.terminalKeyRight,
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
          onPressed: () {
            final tab = _activeTab;
            if (tab != null) _onTabInput(tab, data);
          },
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
          onPressed: () {
            final tab = _activeTab;
            if (tab != null) _onTabInput(tab, data);
          },
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
    final tab = _activeTab;
    if (tab == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildTabStrip(),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(child: _buildActiveTabBody(tab)),
      ],
    );
  }

  Widget _buildActiveTabBody(_TerminalTab tab) {
    if (tab.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 8),
            Text(tab.error!),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: tab.creating ? null : () => _createSessionFor(tab),
              child: Text(AppLocalizations.of(context).actionRetry),
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
                  key: ValueKey(tab),
                  tab.terminal,
                  controller: tab.controller,
                  autofocus: true,
                  padding: const EdgeInsets.all(8),
                  theme: Theme.of(context).brightness == Brightness.dark
                      ? TerminalThemes.defaultTheme
                      : _lightTerminalTheme,
                ),
              ),
              if (tab.exited != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(tab.exited!)),
                        TextButton(
                          onPressed: tab.creating
                              ? null
                              : () => _createSessionFor(tab),
                          child: Text(
                            AppLocalizations.of(context).terminalNewSession,
                          ),
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
