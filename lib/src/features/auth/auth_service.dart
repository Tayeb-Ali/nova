// Optional auth backend: guest-first, nothing gated.
//
// All methods return [AuthResult] and never throw. Error messages are short
// English codes (e.g. `wrong-password`, `network-error`); user-facing Arabic
// text comes from the `auth*` entries in `lib/l10n/app_en.arb` / `app_ar.arb`.
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";

/// Outcome of an auth call. `ok` true means the operation succeeded;
/// otherwise `message` holds a short English error code.
class AuthResult {
  final bool ok;
  final String message;
  const AuthResult({required this.ok, required this.message});

  /// Success result (message defaults to `ok`).
  const AuthResult.ok([this.message = "ok"]) : ok = true;

  /// Failure result with a short English code in [message].
  const AuthResult.fail(this.message) : ok = false;
}

/// Wraps [FirebaseAuth] (+ [GoogleSignIn] for the Google flow).
///
/// Both collaborators are constructor-injectable so tests can pass fakes.
/// No method throws: every failure surfaces as `AuthResult(ok: false, ...)`.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Live auth-state stream (null = signed out / guest).
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Currently signed-in user, or null for guest.
  User? get currentUser => _auth.currentUser;

  Future<AuthResult> signUpEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final emailError = _validateEmail(cleanEmail);
    if (emailError != null) return AuthResult.fail(emailError);
    final passwordError = _validatePassword(password);
    if (passwordError != null) return AuthResult.fail(passwordError);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  Future<AuthResult> signInEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final emailError = _validateEmail(cleanEmail);
    if (emailError != null) return AuthResult.fail(emailError);
    if (password.isEmpty) return const AuthResult.fail("wrong-password");
    try {
      await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  Future<AuthResult> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return const AuthResult.fail("not-signed-in");
    try {
      await user.sendEmailVerification();
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    final emailError = _validateEmail(cleanEmail);
    if (emailError != null) return AuthResult.fail(emailError);
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  /// Google flow (google_sign_in v7): `authenticate()` then `.authentication`,
  /// credential via [GoogleAuthProvider]. Only an ID token is available in v7;
  /// that alone is sufficient for `GoogleAuthProvider.credential`.
  Future<AuthResult> signInGoogle() async {
    try {
      // Must run once before authenticate(); a repeat call is undefined, so
      // best-effort it and continue to authenticate regardless.
      try {
        await _googleSignIn.initialize();
      } catch (_) {
        // Already initialized (or init failed) — authenticate anyway.
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthResult.fail("google-no-id-token");
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return const AuthResult.ok();
    } on GoogleSignInException catch (e) {
      return AuthResult.fail(_googleCode(e.code));
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  /// X (Twitter) flow. The Twitter ClientID/Secret paste happens in the
  /// Firebase Console (see README docs in the final report); on-device this
  /// is just an OAuth provider sign-in with Arabic UI hint.
  Future<AuthResult> signInX() async {
    try {
      final provider = OAuthProvider(
        "twitter.com",
      ).setCustomParameters({"lang": "ar"});
      await _auth.signInWithProvider(provider);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  /// GitHub flow. The OAuth App callback URL is registered in the Firebase
  /// Console / GitHub (see README docs in the final report); on-device this
  /// is just an OAuth provider sign-in with identity scopes.
  Future<AuthResult> signInGitHub() async {
    try {
      final provider = OAuthProvider("github.com")
        ..addScope("read:user")
        ..addScope("user:email");
      await _auth.signInWithProvider(provider);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Google sign-out is best-effort; Firebase already signed out.
      }
      return const AuthResult.ok();
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  Future<AuthResult> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return const AuthResult.fail("not-signed-in");
    try {
      await user.delete();
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Best-effort; the Firebase user is already deleted.
      }
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_shortCode(e));
    } catch (_) {
      return const AuthResult.fail("unknown-error");
    }
  }

  // -- validation -----------------------------------------------------------

  static String? _validateEmail(String email) {
    if (email.isEmpty || !email.contains("@") || !email.contains(".")) {
      return "invalid-email";
    }
    return null;
  }

  static String? _validatePassword(String password) {
    if (password.length < 6) return "weak-password";
    return null;
  }

  // -- error mapping --------------------------------------------------------

  /// Maps [GoogleSignInExceptionCode] to the short codes used by [AuthResult].
  static String _googleCode(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return "cancelled";
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return "operation-not-allowed";
      case GoogleSignInExceptionCode.userMismatch:
        return "user-mismatch";
      case GoogleSignInExceptionCode.unknownError:
        return "unknown-error";
    }
  }

  /// Maps [FirebaseAuthException.code] to short English codes. Unmapped codes
  /// pass through unchanged (they are already short English codes).
  static String _shortCode(FirebaseAuthException e) {
    switch (e.code) {
      case "network-request-failed":
        return "network-error";
      case "email-already-in-use":
      case "account-exists-with-different-credential":
      case "credential-already-in-use":
        return "account-exists";
      case "user-cancelled":
      case "user-canceled":
        return "cancelled";
      default:
        return e.code;
    }
  }
}
