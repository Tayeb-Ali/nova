import 'dart:async';
import 'dart:convert';

/// Timeout applied to every pending JSON-RPC request.
const Duration kLspRequestTimeout = Duration(seconds: 3);

/// Thrown when a JSON-RPC request does not get a response in time.
class LspTimeoutException implements Exception {
  const LspTimeoutException(this.id, this.method);

  /// The request id that timed out.
  final int id;

  /// The method that timed out.
  final String method;

  @override
  String toString() => 'LSP request "$method" (id $id) timed out after '
      '${kLspRequestTimeout.inSeconds}s';
}

/// Thrown when the server replies with a JSON-RPC `error` object.
class LspRpcException implements Exception {
  const LspRpcException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'LSP error $code: $message';
}

/// One completion item returned by `textDocument/completion`.
class LspCompletionItem {
  const LspCompletionItem({
    required this.label,
    this.kind,
    this.detail,
    this.insertText,
  });

  /// The text shown in the completion list.
  final String label;

  /// LSP `CompletionItemKind` (e.g. 3 = Function, 6 = Snippet).
  final int? kind;

  /// Secondary description shown alongside [label].
  final String? detail;

  /// Text inserted into the document on accept (falls back to the
  /// `textEdit.newText` value when present).
  final String? insertText;
}

/// One diagnostic entry inside a published document.
class LspDiagnostic {  const LspDiagnostic({
    required this.message,
    this.severity,
    required this.line,
    required this.char,
    required this.endLine,
    required this.endChar,
  });

  /// Human readable description (`Diagnostic.message`).
  final String message;

  /// LSP `DiagnosticSeverity` (1=Error, 2=Warning, 3=Information, 4=Hint).
  final int? severity;

  final int line;
  final int char;
  final int endLine;
  final int endChar;
}

/// Diagnostic batch for a single document (`text/publishDiagnostics`).
class LspDiagnostics {
  const LspDiagnostics({required this.path, this.diagnostics = const []});

  final String path;
  final List<LspDiagnostic> diagnostics;
}

/// One definition site returned by `textDocument/definition`.
///
/// LSP answers with a single Location, a list of Locations, or a list of
/// LocationLinks; the client normalizes all three to this (first hit wins).
class LspLocation {
  const LspLocation({
    required this.path,
    required this.line,
    required this.character,
  });

  /// Filesystem path decoded from the `file://` URI.
  final String path;

  /// 0-based line and character of the definition start.
  final int line;
  final int character;
}

/// One parameter of an LSP `SignatureInformation`.
///
/// `label` is already resolved: servers send either the parameter text
/// itself or a `[start, end]` offset pair into the enclosing signature
/// label, and the client normalizes both to the substring form.
class LspSignatureParameter {
  const LspSignatureParameter({required this.label, this.documentation});

  /// Parameter text (e.g. `a: int`).
  final String label;

  /// Parameter documentation, when the server sent any.
  final String? documentation;
}

/// One signature inside a `textDocument/signatureHelp` response.
class LspSignatureInformation {
  const LspSignatureInformation({
    required this.label,
    this.documentation,
    this.parameters = const [],
  });

  /// Full signature text (e.g. `foo(a: int, b: string)`).
  final String label;

  /// Signature documentation, when the server sent any.
  final String? documentation;

  /// The signature's parameters, in order.
  final List<LspSignatureParameter> parameters;
}

/// Signature help for the call site at a cursor position
/// (`textDocument/signatureHelp`).
class LspSignatureHelp {
  const LspSignatureHelp({
    required this.signatures,
    this.activeSignature,
    this.activeParameter,
  });

  /// Available overloads; the list is never empty.
  final List<LspSignatureInformation> signatures;

  /// Index into [signatures] of the active overload, when reported.
  final int? activeSignature;

  /// Index of the active parameter within the active signature, when
  /// reported.
  final int? activeParameter;
}

/// Wire-level transport for JSON-RPC messages.
///
/// The transport owns framing and the connection. A real stdio-backed
/// implementation (spawning the language server over a native bridge) will
/// provide this later; the client only depends on this interface.
abstract class LspTransport {
  /// Complete JSON-RPC messages, framing already decoded, one per event.
  Stream<String> get incoming;

  /// Send one JSON-RPC message (the transport frames it on the wire).
  void send(String message);

  /// Bring the connection up before the first message is exchanged.
  Future<void> start();

  /// Tear the connection down.
  Future<void> stop();
}

/// No-op transport used for tests and placeholder wiring.
class NullTransport implements LspTransport {
  @override
  Stream<String> get incoming => const Stream<String>.empty();

  @override
  void send(String message) {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

/// Minimal JSON-RPC 2.0 LSP client running over an [LspTransport].
class LspClient {
  LspClient(this._transport) {
    // Subscribe eagerly so responses are handled even if the transport was
    // already started (or in tests, fed before `initialize` is called).
    _incomingSub = _transport.incoming.listen(_dispatch);
  }

  final LspTransport _transport;

  final Map<Object, Completer<Object?>> _pending = <Object, Completer<Object?>>{};
  final Map<String, int> _versions = <String, int>{};
  final StreamController<LspDiagnostics> _diagnosticsController =
      StreamController<LspDiagnostics>.broadcast();

  StreamSubscription<String>? _incomingSub;
  int _nextId = 1;

  /// Diagnostics pushed by the server via `text/publishDiagnostics`.
  Stream<LspDiagnostics> get diagnosticsStream => _diagnosticsController.stream;

  /// Convert a filesystem [path] into an LSP `file://` URI.
  static String uriFor(String path) =>
      path.startsWith('file://') ? path : 'file://$path';

  /// Start the transport and perform the LSP initialize handshake.
  Future<void> initialize(String rootUri) async {
    await _transport.start();
    await _request('initialize', <String, dynamic>{
      'processId': null,
      'rootUri': rootUri,
      'capabilities': <String, dynamic>{},
    });
    _notify('initialized', const <String, dynamic>{});
  }

  /// Tell the server a document was opened.
  void didOpen(String path, String language) {
    _notify('textDocument/didOpen', <String, dynamic>{
      'textDocument': <String, dynamic>{
        'uri': uriFor(path),
        'languageId': language,
        'version': _bumpVersion(path),
        'text': '',
      },
    });
  }

  /// Tell the server the document content changed.
  void didChange(String path, String text) {
    _notify('textDocument/didChange', <String, dynamic>{
      'textDocument': <String, dynamic>{
        'uri': uriFor(path),
        'version': _bumpVersion(path),
      },
      'contentChanges': <Map<String, dynamic>>[
        <String, dynamic>{'text': text},
      ],
    });
  }

  /// Tell the server the document was closed.
  void didClose(String path) {
    _notify('textDocument/didClose', <String, dynamic>{
      'textDocument': <String, dynamic>{'uri': uriFor(path)},
    });
    _versions.remove(path);
  }

  /// Request completion items at [line]/[char] (0-based).
  Future<List<LspCompletionItem>> completion(
    String path,
    int line,
    int char,
  ) async {
    final Object? result = await _request('textDocument/completion',
        <String, dynamic>{
      'textDocument': <String, dynamic>{'uri': uriFor(path)},
      'position': <String, dynamic>{'line': line, 'character': char},
    });
    return _parseCompletion(result);
  }

  /// Request the definition site(s) of the symbol at [line]/[char]
  /// (0-based). Returns the first location, or null when the server
  /// answers empty (or the request fails — callers treat that as
  /// "fall back to text search", never as an editing failure).
  Future<LspLocation?> definition(
    String path,
    int line,
    int char,
  ) async {
    try {
      final Object? result = await _request('textDocument/definition',
          <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uriFor(path)},
        'position': <String, dynamic>{'line': line, 'character': char},
      });
      return _parseDefinition(result);
    } catch (_) {
      return null;
    }
  }

  /// Request signature help for the call site at [line]/[char]
  /// (0-based). Returns the parsed overloads, or null when the server
  /// answers empty, the payload is malformed, or the request fails —
  /// callers treat that as "no hint", never as an editing failure.
  Future<LspSignatureHelp?> signatureHelp(
    String path,
    int line,
    int char,
  ) async {
    try {
      final Object? result = await _request('textDocument/signatureHelp',
          <String, dynamic>{
        'textDocument': <String, dynamic>{'uri': uriFor(path)},
        'position': <String, dynamic>{'line': line, 'character': char},
      });
      return _parseSignatureHelp(result);
    } catch (_) {
      return null;
    }
  }

  /// Shut the server down and stop the transport.
  Future<void> shutdown() async {
    await _request('shutdown', null);
    _notify('exit', null);
    await _incomingSub?.cancel();
    await _transport.stop();
  }

  int _bumpVersion(String path) {
    final int next = (_versions[path] ?? 0) + 1;
    _versions[path] = next;
    return next;
  }

  void _notify(String method, Object? params) {
    _transport.send(jsonEncode(<String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'params': params ?? <String, dynamic>{},
    }));
  }

  Future<Object?> _request(String method, Object? params) async {
    final int id = _nextId++;
    final Completer<Object?> completer = Completer<Object?>();
    _pending[id] = completer;
    _transport.send(jsonEncode(<String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params ?? <String, dynamic>{},
    }));
    try {
      return await completer.future.timeout(kLspRequestTimeout);
    } on TimeoutException {
      _pending.remove(id);
      throw LspTimeoutException(id, method);
    }
  }

  void _dispatch(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    final Object? id = decoded['id'];
    if (id != null) {
      final Completer<Object?>? completer = _pending.remove(id);
      if (completer == null) return;
      final Object? error = decoded['error'];
      if (error != null) {
        completer.completeError(_rpcError(error));
      } else {
        completer.complete(decoded['result']);
      }
      return;
    }

    if (decoded['method'] == 'text/publishDiagnostics') {
      _handlePublishDiagnostics(decoded['params']);
    }
  }

  LspRpcException _rpcError(Object? error) {
    if (error is! Map<String, dynamic>) {
      return const LspRpcException(-1, 'unknown error');
    }
    final int code = error['code'] is int ? error['code'] as int : -1;
    final String message =
        error['message'] is String ? error['message'] as String : 'unknown error';
    return LspRpcException(code, message);
  }

  void _handlePublishDiagnostics(Object? params) {
    if (params is! Map<String, dynamic>) return;
    final Object? uri = params['uri'];
    if (uri is! String) return;
    final Object? rawList = params['diagnostics'];
    if (rawList is! List) return;

    final List<LspDiagnostic> diagnostics = <LspDiagnostic>[];
    for (final Object? raw in rawList) {
      final LspDiagnostic? diagnostic = _parseDiagnostic(raw);
      if (diagnostic != null) diagnostics.add(diagnostic);
    }
    final String path =
        uri.startsWith('file://') ? uri.substring('file://'.length) : uri;
    _diagnosticsController.add(
      LspDiagnostics(path: path, diagnostics: List.unmodifiable(diagnostics)),
    );
  }

  LspDiagnostic? _parseDiagnostic(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? range = raw['range'];
    if (range is! Map<String, dynamic>) return null;
    final Object? start = range['start'];
    final Object? end = range['end'];
    if (start is! Map<String, dynamic> || end is! Map<String, dynamic>) {
      return null;
    }
    final Object? message = raw['message'];
    return LspDiagnostic(
      message: message is String ? message : '',
      severity: raw['severity'] is int ? raw['severity'] as int : null,
      line: start['line'] is int ? start['line'] as int : 0,
      char: start['character'] is int ? start['character'] as int : 0,
      endLine: end['line'] is int ? end['line'] as int : 0,
      endChar: end['character'] is int ? end['character'] as int : 0,
    );
  }

  List<LspCompletionItem> _parseCompletion(Object? result) {    if (result is List) {
      return _itemsFromList(result);
    }
    if (result is Map<String, dynamic>) {
      final Object? items = result['items'];
      if (items is List) return _itemsFromList(items);
    }
    return const <LspCompletionItem>[];
  }

  List<LspCompletionItem> _itemsFromList(List<Object?> items) {
    final List<LspCompletionItem> parsed = <LspCompletionItem>[];
    for (final Object? item in items) {
      if (item is Map<String, dynamic>) parsed.add(_parseCompletionItem(item));
    }
    return List.unmodifiable(parsed);
  }

  LspCompletionItem _parseCompletionItem(Map<String, dynamic> item) {
    String? insertText;
    final Object? textEdit = item['textEdit'];
    if (textEdit is Map<String, dynamic> && textEdit['newText'] is String) {
      insertText = textEdit['newText'] as String;
    } else if (item['insertText'] is String) {
      insertText = item['insertText'] as String;
    }
    return LspCompletionItem(
      label: item['label'] is String ? item['label'] as String : '',
      kind: item['kind'] is int ? item['kind'] as int : null,
      detail: item['detail'] is String ? item['detail'] as String : null,
      insertText: insertText,
    );
  }

  /// Normalizes a `textDocument/definition` result to the first location.
  /// Accepts a single Location, a list of Locations, or a list of
  /// LocationLinks (using `targetUri`/`targetRange`). Anything else —
  /// including an empty list — yields null.
  LspLocation? _parseDefinition(Object? result) {
    final List<Object?> candidates;
    if (result is List) {
      candidates = result;
    } else if (result is Map<String, dynamic>) {
      candidates = <Object?>[result];
    } else {
      return null;
    }
    for (final Object? candidate in candidates) {
      final LspLocation? location = _parseLocation(candidate);
      if (location != null) return location;
    }
    return null;
  }

  LspLocation? _parseLocation(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    // LocationLink carries targetUri/targetRange instead of uri/range.
    final Object? uri = raw['uri'] ?? raw['targetUri'];
    final Object? range = raw['range'] ?? raw['targetRange'];
    if (uri is! String || range is! Map<String, dynamic>) return null;
    final Object? start = range['start'];
    if (start is! Map<String, dynamic>) return null;
    final Object? line = start['line'];
    final Object? character = start['character'];
    if (line is! int || character is! int) return null;
    return LspLocation(
      path: uri.startsWith('file://')
          ? uri.substring('file://'.length)
          : uri,
      line: line,
      character: character,
    );
  }

  /// Normalizes a `textDocument/signatureHelp` result. Anything but a map
  /// with a non-empty `signatures` list — including a list with no valid
  /// signature — yields null.
  LspSignatureHelp? _parseSignatureHelp(Object? result) {
    try {
      if (result is! Map<String, dynamic>) return null;
      final Object? rawSignatures = result['signatures'];
      if (rawSignatures is! List || rawSignatures.isEmpty) return null;
      final List<LspSignatureInformation> signatures =
          <LspSignatureInformation>[];
      for (final Object? raw in rawSignatures) {
        final LspSignatureInformation? signature = _parseSignature(raw);
        if (signature != null) signatures.add(signature);
      }
      if (signatures.isEmpty) return null;
      return LspSignatureHelp(
        signatures: List.unmodifiable(signatures),
        activeSignature: result['activeSignature'] is int
            ? result['activeSignature'] as int
            : null,
        activeParameter: result['activeParameter'] is int
            ? result['activeParameter'] as int
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  LspSignatureInformation? _parseSignature(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? label = raw['label'];
    if (label is! String) return null;
    final List<LspSignatureParameter> parameters = <LspSignatureParameter>[];
    final Object? rawParameters = raw['parameters'];
    if (rawParameters is List) {
      for (final Object? parameter in rawParameters) {
        final LspSignatureParameter? parsed =
            _parseSignatureParameter(parameter, label);
        if (parsed != null) parameters.add(parsed);
      }
    }
    return LspSignatureInformation(
      label: label,
      documentation: _parseSignatureDoc(raw['documentation']),
      parameters: List.unmodifiable(parameters),
    );
  }

  LspSignatureParameter? _parseSignatureParameter(
    Object? raw,
    String signatureLabel,
  ) {
    if (raw is! Map<String, dynamic>) return null;
    final String? label =
        _resolveParameterLabel(raw['label'], signatureLabel);
    if (label == null) return null;
    return LspSignatureParameter(
      label: label,
      documentation: _parseSignatureDoc(raw['documentation']),
    );
  }

  /// Resolves an LSP parameter label: either the literal text or a
  /// `[start, end]` offset pair into [signatureLabel]. Out-of-range
  /// offsets yield null (the parameter is skipped).
  String? _resolveParameterLabel(Object? label, String signatureLabel) {
    if (label is String) return label;
    if (label is List && label.length == 2) {
      final Object? start = label[0];
      final Object? end = label[1];
      if (start is int && end is int && start >= 0 && start <= end &&
          end <= signatureLabel.length) {
        return signatureLabel.substring(start, end);
      }
    }
    return null;
  }

  /// Documentation is either a plain string or a `MarkupContent` map
  /// (`{'kind': ..., 'value': ...}`); anything else yields null.
  String? _parseSignatureDoc(Object? raw) {
    if (raw is String) return raw;
    if (raw is Map<String, dynamic> && raw['value'] is String) {
      return raw['value'] as String;
    }
    return null;
  }
}