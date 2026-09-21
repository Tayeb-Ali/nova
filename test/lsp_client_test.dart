import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova/src/features/lsp/lsp_client.dart';

/// Test transport: records sent messages and auto-replies to every request
/// with [cannedResult], so the client's pending completers resolve.
class FakeTransport implements LspTransport {
  FakeTransport({this.cannedResult = const <String, dynamic>{}});

  final Map<String, dynamic> cannedResult;
  final List<String> sent = <String>[];
  final StreamController<String> _incoming = StreamController<String>();
  bool started = false;
  bool stopped = false;

  @override
  Stream<String> get incoming => _incoming.stream;

  @override
  void send(String message) {
    sent.add(message);
    final Map<String, dynamic> decoded =
        jsonDecode(message) as Map<String, dynamic>;
    final Object? id = decoded['id'];
    if (id == null) return;
    // Reply after the current sync stack completes so the pending completer
    // is registered before the response arrives.
    scheduleMicrotask(() {
      _incoming.add(
        jsonEncode(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': cannedResult,
        }),
      );
    });
  }

  /// Push a message as if the server had sent it.
  void serverSends(Map<String, dynamic> message) {
    _incoming.add(jsonEncode(message));
  }

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

void main() {
  test(
    'sends a framed completion request and parses the canned result',
    () async {
      final transport = FakeTransport(
        cannedResult: <String, dynamic>{
          'isIncomplete': false,
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'label': 'foo',
              'kind': 3,
              'detail': 'Widget',
              'insertText': 'foo()',
            },
          ],
        },
      );
      final client = LspClient(transport);

      final List<LspCompletionItem> items = await client.completion(
        'lib/main.dart',
        3,
        7,
      );

      expect(transport.sent, hasLength(1));
      final Map<String, dynamic> request =
          jsonDecode(transport.sent.single) as Map<String, dynamic>;
      expect(request['jsonrpc'], '2.0');
      expect(request['id'], 1);
      expect(request['method'], 'textDocument/completion');
      final Map<String, dynamic> params =
          request['params'] as Map<String, dynamic>;
      expect(params['textDocument']['uri'], 'file://lib/main.dart');
      expect(params['position'], <String, dynamic>{'line': 3, 'character': 7});

      expect(items, hasLength(1));
      expect(items.single.label, 'foo');
      expect(items.single.kind, 3);
      expect(items.single.detail, 'Widget');
      expect(items.single.insertText, 'foo()');
    },
  );

  test(
    'surfaces publishDiagnostics notifications on diagnosticsStream',
    () async {
      final transport = FakeTransport();
      final client = LspClient(transport);

      final Future<LspDiagnostics> first = client.diagnosticsStream.first;
      transport.serverSends(<String, dynamic>{
        'jsonrpc': '2.0',
        'method': 'text/publishDiagnostics',
        'params': <String, dynamic>{
          'uri': 'file:///home/nova/projects/app/lib/main.dart',
          'diagnostics': <Map<String, dynamic>>[
            <String, dynamic>{
              'range': <String, dynamic>{
                'start': <String, dynamic>{'line': 1, 'character': 2},
                'end': <String, dynamic>{'line': 1, 'character': 8},
              },
              'severity': 1,
              'message': 'undefined name',
            },
          ],
        },
      });

      final LspDiagnostics diagnostics = await first;
      expect(diagnostics.path, '/home/nova/projects/app/lib/main.dart');
      expect(diagnostics.diagnostics, hasLength(1));
      expect(diagnostics.diagnostics.single.message, 'undefined name');
      expect(diagnostics.diagnostics.single.severity, 1);
      expect(diagnostics.diagnostics.single.line, 1);
      expect(diagnostics.diagnostics.single.char, 2);
      expect(diagnostics.diagnostics.single.endLine, 1);
      expect(diagnostics.diagnostics.single.endChar, 8);
      expect(transport.started, isFalse);
    },
  );
}
