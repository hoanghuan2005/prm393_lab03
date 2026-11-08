import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in Google account, without any Firebase type leaking to the UI.
class AdminAccount {
  final String uid;
  final String? email;
  final String? displayName;

  const AdminAccount({required this.uid, this.email, this.displayName});

  String get label => displayName ?? email ?? uid;
}

enum SignInFailure {
  cancelled,
  popupBlocked,
  network,
  unauthorizedDomain,

  /// Email / password: wrong email or password, or no such account
  wrongCredentials,

  /// Email / password: too many failed attempts, Firebase blocks for a while
  tooManyAttempts,
  unknown,
}

class SignInException implements Exception {
  final SignInFailure failure;
  final String? code;

  const SignInException(this.failure, [this.code]);

  @override
  String toString() => 'SignInException($failure, $code)';
}

abstract class AdminAuthService {
  Stream<AdminAccount?> authStateChanges();

  /// Google Sign-In in a popup. Throws [SignInException].
  Future<void> signInWithGoogle();

  /// Email / password account (e.g. the team's shared admin). Throws [SignInException].
  Future<void> signInWithEmail(String email, String password);

  Future<void> signOut();

  /// Firebase ID token of the current account, for the optional push server
  Future<String?> idToken();
}

class FirebaseAdminAuthService implements AdminAuthService {
  final FirebaseAuth _auth;

  FirebaseAdminAuthService([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<AdminAccount?> authStateChanges() => _auth.authStateChanges().map(
    (u) => u == null
        ? null
        : AdminAccount(uid: u.uid, email: u.email, displayName: u.displayName),
  );

  @override
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    // A popup, not a redirect: a redirect breaks on Hosting when the site
    // domain (web.app) differs from authDomain (firebaseapp.com)
    try {
      await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      throw SignInException(switch (e.code) {
        'popup-closed-by-user' ||
        'cancelled-popup-request' ||
        'user-cancelled' => SignInFailure.cancelled,
        'popup-blocked' => SignInFailure.popupBlocked,
        'network-request-failed' => SignInFailure.network,
        'unauthorized-domain' => SignInFailure.unauthorizedDomain,
        _ => SignInFailure.unknown,
      }, e.code);
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw SignInException(switch (e.code) {
        'invalid-credential' ||
        'invalid-email' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' => SignInFailure.wrongCredentials,
        'too-many-requests' => SignInFailure.tooManyAttempts,
        'network-request-failed' => SignInFailure.network,
        _ => SignInFailure.unknown,
      }, e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();
}
