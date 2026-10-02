import 'dart:async';
import 'dart:io';

import '../app_config.dart';

/// Reachability of one distribution endpoint.
enum RepoEndpointState { ok, unreachable }

/// Probe result for a single distribution source URL.
class RepoEndpointReport {
  const RepoEndpointReport({
    required this.name,
    required this.url,
    required this.state,
    this.detail,
  });

  final String name;
  final String url;
  final RepoEndpointState state;
  final String? detail;

  bool get ok => state == RepoEndpointState.ok;
}

/// Probes the binary distribution sources (apt repo + bootstrap hosts).
///
/// Pure Dart over [HttpClient] so it works before the bootstrap exists and
/// without any bridge call. The fetcher is injectable for unit tests.
/// URLs mirror the flavor BuildConfig fields (see [AppConfig]); the Kotlin
/// installer remains the only downloader.
class RepoHealthService {
  RepoHealthService({
    Future<int> Function(Uri uri, Duration timeout)? fetchStatus,
    List<({String name, String url})>? endpoints,
  })  : _fetchStatus = fetchStatus ?? _headStatus,
        _endpoints = endpoints ?? _defaultEndpoints;

  final Future<int> Function(Uri uri, Duration timeout) _fetchStatus;
  final List<({String name, String url})> _endpoints;

  static const Duration probeTimeout = Duration(seconds: 10);

  static final List<({String name, String url})> _defaultEndpoints = [
    (name: 'apt', url: AppConfig.repoUrl),
    (name: 'bootstrap-slim', url: AppConfig.bootstrapSlimBaseUrl),
    (name: 'bootstrap-full', url: AppConfig.bootstrapFullBaseUrl),
  ];

  /// HEAD the endpoint (fall back to ranged GET); any 2xx/3xx counts as
  /// reachable. Never throws — failures become [RepoEndpointState.unreachable].
  Future<List<RepoEndpointReport>> checkAll({
    Duration timeout = probeTimeout,
  }) async {
    final List<RepoEndpointReport> out = [];
    for (final ep in _endpoints) {
      out.add(await _checkOne(ep.name, ep.url, timeout));
    }
    return out;
  }

  Future<RepoEndpointReport> _checkOne(
    String name,
    String url,
    Duration timeout,
  ) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return RepoEndpointReport(
        name: name,
        url: url,
        state: RepoEndpointState.unreachable,
        detail: 'bad url: $e',
      );
    }
    try {
      final int code = await _fetchStatus(uri, timeout);
      if (code >= 200 && code < 400) {
        return RepoEndpointReport(
          name: name,
          url: url,
          state: RepoEndpointState.ok,
          detail: 'HTTP $code',
        );
      }
      return RepoEndpointReport(
        name: name,
        url: url,
        state: RepoEndpointState.unreachable,
        detail: 'HTTP $code',
      );
    } on TimeoutException {
      return RepoEndpointReport(
        name: name,
        url: url,
        state: RepoEndpointState.unreachable,
        detail: 'timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      return RepoEndpointReport(
        name: name,
        url: url,
        state: RepoEndpointState.unreachable,
        detail: '$e',
      );
    }
  }

  static Future<int> _headStatus(Uri uri, Duration timeout) async {
    final HttpClient client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      HttpClientResponse res;
      try {
        final HttpClientRequest req = await client.headUrl(uri);
        res = await req.close().timeout(timeout);
      } catch (_) {
        // Some static hosts reject HEAD; retry with a 1-byte ranged GET.
        final HttpClientRequest req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
        res = await req.close().timeout(timeout);
      }
      final int code = res.statusCode;
      await res.drain<void>();
      return code;
    } finally {
      client.close(force: true);
    }
  }
}
