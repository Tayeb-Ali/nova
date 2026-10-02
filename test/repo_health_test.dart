import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/core/services/repo_health_service.dart';

void main() {
  test('ok on 2xx/3xx for every endpoint', () async {
    final service = RepoHealthService(
      fetchStatus: (_, _) async => 200,
    );
    final reports = await service.checkAll();
    expect(reports, hasLength(3));
    expect(reports.every((r) => r.ok), isTrue);
  });

  test('unreachable on 5xx with HTTP detail', () async {
    final service = RepoHealthService(
      fetchStatus: (_, _) async => 500,
    );
    final reports = await service.checkAll();
    expect(reports.every((r) => !r.ok), isTrue);
    expect(reports.first.detail, contains('500'));
  });

  test('unreachable on timeout and on throw, never throws itself', () async {
    var calls = 0;
    final service = RepoHealthService(
      fetchStatus: (_, _) async {
        calls++;
        if (calls.isOdd) {
          throw TimeoutException('slow');
        }
        throw const SocketExceptionTest('no route');
      },
    );
    final reports = await service.checkAll();
    expect(reports, hasLength(3));
    expect(reports.every((r) => !r.ok), isTrue);
    expect(reports.first.detail, contains('timed out'));
  });

  test('fetch failure is reported unreachable, not thrown', () async {
    final service = RepoHealthService(
      fetchStatus: (_, _) async => throw const FormatException('bad'),
    );
    final reports = await service.checkAll();
    expect(reports, hasLength(3));
    expect(reports.every((r) => !r.ok), isTrue);
  });
}

/// Stand-in for dart:io SocketException (unavailable in some test contexts
/// without importing dart:io); the service treats any throw as unreachable.
class SocketExceptionTest implements Exception {
  const SocketExceptionTest(this.message);
  final String message;

  @override
  String toString() => 'SocketException: $message';
}
