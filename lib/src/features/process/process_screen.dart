import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/process_info.dart';
import '../../core/services/process_service.dart';

/// Process manager: running tasks list + kill + ad-hoc run (task.md §21).
class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  final _processService = ProcessService();
  final _commandController = TextEditingController();

  StreamSubscription<ProcessEvent>? _eventSub;
  List<ProcessInfo> _processes = [];
  final Map<String, StringBuffer> _outputs = {};
  bool _loading = true;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventSub = _processService.eventStream.listen(_onEvent);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _commandController.dispose();
    super.dispose();
  }

  void _onEvent(ProcessEvent event) {
    if (!mounted) return;
    setState(() {
      if (event.exited) {
        _processes.removeWhere((p) => p.pid == event.pid);
        _outputs.remove(event.pid);
        _error = null;
      } else if (event.output.isNotEmpty) {
        final buffer = _outputs.putIfAbsent(
          event.pid,
          () => StringBuffer(),
        );
        if (buffer.length > 8000) {
          buffer.clear();
        }
        buffer.write(event.output);
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final processes = await _processService.list();
      if (!mounted) return;
      setState(() {
        _processes = processes;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to list processes';
      });
    }
  }

  Future<void> _kill(String pid) async {
    try {
      await _processService.kill(pid);
      if (!mounted) return;
      setState(() {
        _processes.removeWhere((p) => p.pid == pid);
        _outputs.remove(pid);
      });
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to kill process')),
      );
    }
  }

  Future<void> _runCommand(String line) async {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    setState(() => _running = true);
    try {
      final parts = trimmed.split(RegExp(r'\s+'));
      final started = await _processService.start(
        command: parts.first,
        args: parts.skip(1).toList(),
      );
      if (!mounted) return;
      _commandController.clear();
      setState(() {
        _running = false;
        _error = null;
      });
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started ${started.pid} · $trimmed')),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _running = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start command')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRunBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildRunBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Run command… e.g. npm run dev',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: _running ? null : _runCommand,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Run',
            onPressed: (_running) ? null : () => _runCommand(_commandController.text),
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _processes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!),
        ),
      );
    }
    if (_loading && _processes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_processes.isEmpty) {
      return const Center(
        child: Text(
          'No running processes.\nStart a task to see it here.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: _processes.length,
      itemBuilder: (context, index) {
        final process = _processes[index];
        final output = _outputs[process.pid]?.toString();
        return _ProcessTile(
          process: process,
          output: output,
          onKill: () => _kill(process.pid),
        );
      },
    );
  }
}

class _ProcessTile extends StatelessWidget {
  const _ProcessTile({
    required this.process,
    this.output,
    required this.onKill,
  });

  final ProcessInfo process;
  final String? output;
  final VoidCallback onKill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        process.status == 'running'
            ? Icons.play_circle_outline
            : Icons.stop_circle_outlined,
        color: process.status == 'running'
            ? Colors.green
            : theme.disabledColor,
      ),
      title: Text(
        '${process.pid}  ·  ${process.command}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        output != null && output!.isNotEmpty
            ? output!.trim().split('\n').last
            : (process.cwd ?? 'Started by Nova'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Kill ${process.pid}',
        onPressed: onKill,
        icon: const Icon(Icons.close),
        color: theme.colorScheme.error,
      ),
    );
  }
}