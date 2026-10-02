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

  test('definition sends the request and parses a single Location', () async {
    final transport = FakeTransport(
      cannedResult: <String, dynamic>{
        'uri': 'file:///proj/lib/util.dart',
        'range': <String, dynamic>{
          'start': <String, dynamic>{'line': 12, 'character': 6},
          'end': <String, dynamic>{'line': 12, 'character': 10},
        },
      },
    );
    final client = LspClient(transport);

    final LspLocation? location = await client.definition(
      '/proj/lib/main.dart',
      3,
      7,
    );

    final Map<String, dynamic> request =
        jsonDecode(transport.sent.single) as Map<String, dynamic>;
    expect(request['method'], 'textDocument/definition');
    final Map<String, dynamic> params =
        request['params'] as Map<String, dynamic>;
    expect(params['textDocument']['uri'], 'file:///proj/lib/main.dart');
    expect(params['position'], <String, dynamic>{'line': 3, 'character': 7});

    expect(location, isNotNull);
    expect(location!.path, '/proj/lib/util.dart');
    expect(location.line, 12);
    expect(location.character, 6);
  });

  test('definition takes the first of a Location list', () async {
    Map<String, dynamic> loc(String uri, int line) => <String, dynamic>{
          'uri': uri,
          'range': <String, dynamic>{
            'start': <String, dynamic>{'line': line, 'character': 0},
            'end': <String, dynamic>{'line': line, 'character': 1},
          },
        };
    final transport = FakeTransport(
      cannedResult: <String, dynamic>{
        'items': <Map<String, dynamic>>[],
      },
    );
    // FakeTransport only serves one canned result; feed a list manually.
    final client = LspClient(transport);
    final Future<LspLocation?> pending = client.definition('a.dart', 0, 0);
    transport.serverSends(<String, dynamic>{
      'jsonrpc': '2.0',
      'id': 1,
      'result': <Map<String, dynamic>>[
        loc('file:///b.dart', 4),
        loc('file:///c.dart', 9),
      ],
    });
    expect((await pending)!.path, '/b.dart');
  });

  test('definition understands LocationLink targets', () async {
    final transport = FakeTransport();
    final client = LspClient(transport);
    final Future<LspLocation?> pending = client.definition('a.dart', 0, 0);
    transport.serverSends(<String, dynamic>{
      'jsonrpc': '2.0',
      'id': 1,
      'result': <Map<String, dynamic>>[
        <String, dynamic>{
          'originSelectionRange': <String, dynamic>{
            'start': <String, dynamic>{'line': 1, 'character': 1},
            'end': <String, dynamic>{'line': 1, 'character': 2},
          },
          'targetUri': 'file:///proj/x.dart',
          'targetRange': <String, dynamic>{
            'start': <String, dynamic>{'line': 7, 'character': 3},
            'end': <String, dynamic>{'line': 7, 'character': 4},
          },
        },
      ],
    });
    final LspLocation? location = await pending;
    expect(location, isNotNull);
    expect(location!.path, '/proj/x.dart');
    expect(location.line, 7);
  });

  test('definition returns null on empty or malformed results', () async {
    final List<Object?> results = <Object?>[
      null,
      <Object?>[],
      <String, dynamic>{'uri': 'file:///x.dart'},
      <String, dynamic>{
        'uri': 'file:///x.dart',
        'range': <String, dynamic>{},
      },
    ];
    for (final Object? result in results) {
      final transport = FakeTransport();
      final client = LspClient(transport);
      final Future<LspLocation?> pending = client.definition('a.dart', 0, 0);
      // Queued before the transport's own canned `{}` microtask reply, so
      // the malformed payload always wins the race deterministically.
      transport.serverSends(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'result': result,
      });
      expect(await pending, isNull);
    }
  });
}
