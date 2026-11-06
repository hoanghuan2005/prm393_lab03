import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/describe_error.dart';
import '../firebase/platform_support.dart';
import 'service_guard.dart';

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

  /// Also emits on link / unlink and profile changes, unlike [authStateChanges]
  Stream<User?> get userChanges => _auth.userChanges();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// User ID or null
  String? get currentUserId => _auth.currentUser?.uid;

  /// User display name or email
  String get displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email ??
      'Người dùng';

  /// Provider ids of the current user ('google.com', 'github.com', ...); empty for guests
  Set<String> get linkedProviderIds => {
    for (final info in _auth.currentUser?.providerData ?? const <UserInfo>[])
      info.providerId,
  };

  /// Sign in with Google; failures are thrown as AppException
  /// Mobile: native google_sign_in. Web: Firebase popup. Windows: unsupported.
  Future<UserCredential?> signInWithGoogle() async {
    if (!PlatformSupport.supportsGoogleSignIn) {
      throw UnsupportedError(
        'Google Sign-In is not available on this platform',
      );
    }
    return guard(() async {
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
        // Code only: some auth messages carry the email
        debugPrint('AuthService Google FirebaseAuthException: ${e.code}');
        rethrow;
      } catch (e) {
        debugPrint('AuthService GoogleSignIn Error: ${describeError(e)}');
        rethrow;
      }
    });
  }

  /// Sign in with GitHub using Firebase Auth OAuth Provider; throws AppException
  Future<UserCredential?> signInWithGithub() async {
    return guard(() async {
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
        debugPrint('AuthService GitHub FirebaseAuthException: ${e.code}');
        rethrow;
      } catch (e) {
        debugPrint('AuthService GitHub Error: ${describeError(e)}');
        rethrow;
      }
    });
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

  /// Create an email account and send Firebase's verification link.
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

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  /// Links Google to the current user; null when the account picker is cancelled.
  /// Throws UnsupportedError where Google Sign-In is unavailable, AppException otherwise.
  Future<UserCredential?> linkGoogle() async {
    if (!PlatformSupport.supportsGoogleSignIn) {
      throw UnsupportedError(
        'Google Sign-In is not available on this platform',
      );
    }
    return guard(() async {
      final user = _requireUser();
      try {
        final UserCredential result;
        if (kIsWeb) {
          result = await user.linkWithPopup(GoogleAuthProvider());
        } else {
          final credential = await _googleCredential();
          if (credential == null) return null;
          result = await user.linkWithCredential(credential);
        }
        await _reloadQuietly(user);
        return result;
      } on FirebaseAuthException catch (e) {
        debugPrint('AuthService link Google FirebaseAuthException: ${e.code}');
        rethrow;
      } catch (e) {
        debugPrint('AuthService link Google error: ${describeError(e)}');
        rethrow;
      }
    });
  }

  /// Links GitHub to the current user; throws AppException
  Future<UserCredential?> linkGithub() async {
    return guard(() async {
      final user = _requireUser();
      try {
        final provider = _githubProvider();
        final result = kIsWeb
            ? await user.linkWithPopup(provider)
            : await user.linkWithProvider(provider);
        await _reloadQuietly(user);
        return result;
      } on FirebaseAuthException catch (e) {
        debugPrint('AuthService link GitHub FirebaseAuthException: ${e.code}');
        rethrow;
      } catch (e) {
        debugPrint('AuthService link GitHub error: ${describeError(e)}');
        rethrow;
      }
    });
  }

  /// Removes [providerId] from the current user; the last remaining one is kept
  Future<void> unlink(String providerId) async {
    final linked = linkedProviderIds;
    if (linked.length <= 1 && linked.contains(providerId)) {
      throw lastProvider;
    }
    await guard(() async {
      final user = _requireUser();
      await user.unlink(providerId);
      // Forget the cached Google account so the next link asks again
      if (providerId == GoogleAuthProvider.PROVIDER_ID &&
          PlatformSupport.isMobile) {
        await _signOutGoogleQuietly();
      }
      await _reloadQuietly(user);
    });
  }

  /// Thrown by [unlink] for the only sign-in method left
  static const lastProvider = AppException(
    'last-provider',
    'Phải giữ ít nhất một cách đăng nhập.',
  );

  /// Refreshes providerData after link / unlink. The change is already saved on
  /// Firebase, so a failed reload must not turn it into an error.
  Future<void> _reloadQuietly(User user) async {
    try {
      await user.reload();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService reload error: ${describeError(e)}');
      }
    }
  }

  /// Runs after Firebase already unlinked Google, so a failure must not undo that result
  Future<void> _signOutGoogleQuietly() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService Google signOut error: ${describeError(e)}');
      }
    }
  }

  /// Thrown inside guard(); flutterfire uses the same code when nobody is signed in
  User _requireUser() =>
      _auth.currentUser ??
      (throw FirebaseAuthException(code: 'no-current-user'));

  /// Google credential from the native account picker; null when cancelled
  Future<OAuthCredential?> _googleCredential() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  GithubAuthProvider _githubProvider() => GithubAuthProvider()
    ..addScope('read:user')
    ..addScope('user:email');

  /// Sign in anonymously for test / guest mode; throws AppException
  Future<UserCredential> signInAnonymously() =>
      guard(() => _auth.signInAnonymously());

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        if (PlatformSupport.isMobile) _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      debugPrint('AuthService signOut error: ${describeError(e)}');
      await _auth.signOut();
    }
  }
}
