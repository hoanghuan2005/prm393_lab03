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
