import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/platform_support.dart';

/// Service abstraction for Authentication
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn? _injectedGoogleSignIn;

  /// Created on first use, i.e. only on Android/iOS: the web uses Firebase's popup, and
  /// creating google_sign_in_web without a client-id meta tag fails an assertion on start.
  late final GoogleSignIn _googleSignIn =
      _injectedGoogleSignIn ?? GoogleSignIn();

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _injectedGoogleSignIn = googleSignIn;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// User ID or null
  String? get currentUserId => _auth.currentUser?.uid;

  /// User display name or email
  String get displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email ??
      'Người dùng';

  /// Sign in with Google
  /// Mobile: native google_sign_in. Web: Firebase popup. Windows: unsupported.
  Future<UserCredential?> signInWithGoogle() async {
    if (!PlatformSupport.supportsGoogleSignIn) {
      throw UnsupportedError(
        'Google Sign-In is not available on this platform',
      );
    }
    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user cancelled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService GoogleSignIn Error: $e');
      rethrow;
    }
  }

  /// Sign in with GitHub using Firebase Auth OAuth Provider
  Future<UserCredential?> signInWithGithub() async {
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');

      if (kIsWeb) {
        return await _auth.signInWithPopup(githubProvider);
      } else {
        return await _auth.signInWithProvider(githubProvider);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService GitHub FirebaseAuthException: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthService GitHub Error: $e');
      rethrow;
    }
  }

  /// Sign in with an email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a Firebase account with an email, password and display name.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.reload();
    await credential.user?.sendEmailVerification();
    return credential;
  }

  /// Send Firebase's password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign in anonymously for test / guest mode
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        if (PlatformSupport.isMobile) _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      debugPrint('AuthService signOut error: $e');
      await _auth.signOut();
    }
  }
}
