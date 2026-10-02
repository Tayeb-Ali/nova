import 'package:flutter_test/flutter_test.dart';

import 'package:nova/src/features/auth/auth_service.dart';

/// Pure [AuthResult] contract tests. The live [AuthService] methods need a
/// configured Firebase app (unavailable in unit tests), so this file pins the
/// result type every method returns: `ok` true on success, otherwise a short
/// English error code in [message] — and the service itself never throws.
void main() {
  group('AuthResult', () {
    test('ok defaults to message "ok"', () {
      const result = AuthResult.ok();
      expect(result.ok, isTrue);
      expect(result.message, 'ok');
    });

    test('ok keeps a custom message', () {
      const result = AuthResult.ok('created');
      expect(result.ok, isTrue);
      expect(result.message, 'created');
    });

    test('fail carries the short error code', () {
      const codes = <String>[
        'invalid-email',
        'weak-password',
        'wrong-password',
        'network-error',
        'account-exists',
        'cancelled',
        'not-signed-in',
        'unknown-error',
      ];
      for (final code in codes) {
        final result = AuthResult.fail(code);
        expect(result.ok, isFalse);
        expect(result.message, code);
      }
    });
  });
}
