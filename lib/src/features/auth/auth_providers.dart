// Riverpod providers for the optional auth system.
//
// Style follows `settings_store.dart` (Riverpod 3, `legacy.dart` for the
// StateNotifier-based store; plain `flutter_riverpod` for these simple
// value/stream providers). Guest-first: no route guards anywhere.
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "auth_service.dart";

/// Shared backend; override in tests with a fake [FirebaseAuth].
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(),
);

/// Live Firebase auth state (null = guest / signed out).
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Currently signed-in user, or null for guest (and while loading/error).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authStateChangesProvider).value,
);

/// True when a user is signed in; false for guest.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
);
