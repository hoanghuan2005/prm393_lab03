import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/describe_error.dart';
import '../core/errors/firebase_error_mapper.dart' show signInCancelled;
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import '../services/pending_writes.dart';
import '../services/user_service.dart';
import 'error_reporting.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ViewModel managing Authentication state & Google Sign-In
class AuthViewModel extends ChangeNotifier with ErrorReporting {
  final AuthService authService;
  final UserService userService;
  final BudgetService budgetService;
  final AppAnalyticsService analyticsService;
  @override
  final CrashlyticsService crashlyticsService;

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  /// Increments on every auth event so a slow setup for an old user cannot win
  int _authEvent = 0;

  AuthViewModel({
    required this.authService,
    required this.userService,
    required this.budgetService,
    required this.analyticsService,
    required this.crashlyticsService,
  }) {
    _init();
  }

  User? get user => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _currentUser != null;

  /// Guest account; false once a guest links Google / Facebook / GitHub.
  bool get isAnonymous => _currentUser?.isAnonymous ?? false;
  bool get requiresEmailVerification =>
      _currentUser != null &&
      !isAnonymous &&
      _currentUser!.providerData.any((info) => info.providerId == 'password') &&
      !_currentUser!.emailVerified;
  String? get errorMessage => _errorMessage;

  String get displayName => authService.displayName;

  /// uid handed to every user-data ViewModel; null until the user documents are ready
  String? get userId =>
      _status == AuthStatus.authenticated ? _currentUser?.uid : null;

  Future<bool> reloadEmailVerification() async {
    try {
      final user = await authService.reloadCurrentUser();
      if (user == null) return false;
      _currentUser = user;
      notifyListeners();
      return user.emailVerified;
    } catch (e, stack) {
      _errorMessage = 'Không thể kiểm tra trạng thái email xác minh.';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'Email verification reload error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendEmailVerification() async {
    try {
      await authService.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e, stack) {
      _setAuthError(e, stack, reason: 'Email verification resend error');
      return false;
    } catch (e, stack) {
      _setUnexpectedAuthError(e, stack, 'Không thể gửi lại email xác minh.');
      return false;
    }
  }

  void _init() {
    // userChanges emits the current user right away (AuthGate shows loading until then),
    // and also on link / unlink / token refresh, unlike authStateChanges
    _authSubscription = authService.userChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    // Same account (link, unlink, profile or token change): refresh the user only, so
    // sign-in work does not run again and the uid handed to other ViewModels stays the same
    if (user != null && _currentUser != null && user.uid == _currentUser!.uid) {
      _currentUser = user;
      notifyListeners();
      return;
    }
    final event = ++_authEvent;
    // Firestore holds another account's queued writes until that account signs in again
    if (user?.uid != _currentUser?.uid) PendingWrites.instance.reset();
    _currentUser = user;

    if (user == null) {
      unawaited(analyticsService.setUserId(null));
      unawaited(crashlyticsService.setUserId(''));
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();
    unawaited(analyticsService.setUserId(user.uid));
    unawaited(crashlyticsService.setUserId(user.uid));
    if (event != _authEvent) return;
    _status = AuthStatus.authenticated;
    notifyListeners();
    unawaited(
      _prepareUserData(user).catchError((Object error, StackTrace stack) async {
        await crashlyticsService.recordHandledError(
          error,
          stack,
          reason: 'User data preparation failed',
        );
      }),
    );
  }

  /// users/{uid} + default budget groups. Failures are logged and never block sign-in.
  Future<void> _prepareUserData(User user) async {
    try {
      await userService.ensureUserDocument(
        user.uid,
        displayName: user.displayName,
        email: user.email,
        isAnonymous: user.isAnonymous,
      );
    } catch (e, stack) {
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'ensureUserDocument failed',
      );
    }
    try {
      await budgetService.ensureDefaultGroups(user.uid);
    } catch (e, stack) {
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'ensureDefaultGroups failed',
      );
    }
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await authService.signInWithGoogle();
      if (credential == null) {
        // User cancelled Google account picker
        _status = AuthStatus.unauthenticated;
        _errorMessage = signInCancelled.messageVi;
        notifyListeners();
        return false;
      }

      await _logLogin('google');
      return true;
    } on UnsupportedError {
      _status = AuthStatus.error;
      _errorMessage =
          'Đăng nhập Google chưa hỗ trợ trên Windows. Hãy dùng chế độ Khách.';
      notifyListeners();
      return false;
    } catch (e, stack) {
      _onSignInFailed(e, stack, method: 'google');
      return false;
    }
  }

  /// Facebook cancellation is silent; user setup accepts a null email.
  Future<bool> signInWithFacebook() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await authService.signInWithFacebook();
      if (credential == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      await _logLogin('facebook');
      return true;
    } on UnsupportedError {
      _status = AuthStatus.error;
      _errorMessage = 'Facebook chưa hỗ trợ trên thiết bị này. Hãy chọn cách đăng nhập khác.';
      notifyListeners();
      return false;
    } catch (e, stack) {
      if (e is AppException && e.code == signInCancelled.code) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _onSignInFailed(e, stack, method: 'facebook');
      return false;
    }
  }

  /// Sign in with GitHub
  Future<bool> signInWithGithub() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await authService.signInWithGithub();
      if (credential == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      await _logLogin('github');
      return true;
    } catch (e, stack) {
      _onSignInFailed(e, stack, method: 'github');
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signInWithEmail(email: email, password: password);
      await analyticsService.logLogin(method: 'email');
      return true;
    } on FirebaseAuthException catch (e, stack) {
      _setAuthError(e, stack, reason: 'Email sign-in error');
      return false;
    } catch (e, stack) {
      _setUnexpectedAuthError(e, stack, 'Đăng nhập thất bại.');
      return false;
    }
  }

  Future<bool> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.createAccount(
        displayName: displayName,
        email: email,
        password: password,
      );
      await analyticsService.logLogin(method: 'email');
      return true;
    } on FirebaseAuthException catch (e, stack) {
      _setAuthError(e, stack, reason: 'Email account creation error');
      return false;
    } catch (e, stack) {
      _setUnexpectedAuthError(e, stack, 'Tạo tài khoản thất bại.');
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e, stack) {
      _setAuthError(e, stack, reason: 'Password reset error');
      return false;
    } catch (e, stack) {
      _setUnexpectedAuthError(
        e,
        stack,
        'Không thể gửi email đặt lại mật khẩu.',
      );
      return false;
    }
  }

  void _setAuthError(
    FirebaseAuthException error,
    StackTrace stack, {
    required String reason,
  }) {
    _status = AuthStatus.error;
    _errorMessage = switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email hoặc mật khẩu không đúng.',
      'email-already-in-use' => 'Email này đã được đăng ký.',
      'invalid-email' => 'Email chưa đúng định dạng.',
      'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
      'too-many-requests' => 'Bạn thử quá nhiều lần. Hãy thử lại sau.',
      _ => error.message ?? 'Có lỗi xác thực. Vui lòng thử lại.',
    };
    unawaited(
      crashlyticsService.recordHandledError(error, stack, reason: reason),
    );
    notifyListeners();
  }

  void _setUnexpectedAuthError(Object error, StackTrace stack, String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    unawaited(
      crashlyticsService.recordHandledError(
        error,
        stack,
        reason: 'Unexpected email auth error',
      ),
    );
    notifyListeners();
  }

  /// Guest / Anonymous sign in for quick testing
  Future<bool> signInAnonymously() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signInAnonymously();
      await _logLogin('guest');
      return true;
    } catch (e, stack) {
      _onSignInFailed(e, stack, method: 'guest');
      return false;
    }
  }

  /// Analytics failures never fail a sign-in that already succeeded
  Future<void> _logLogin(String method) async {
    try {
      await analyticsService.logLogin(method: method);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics login error: ${describeError(e)}');
    }
  }

  /// Cancelling is not an error; Crashlytics only gets errors without their own message
  void _onSignInFailed(Object e, StackTrace stack, {required String method}) {
    _errorMessage = messageFor(
      e,
      stack,
      reason: '$method sign-in error',
      customKeys: {'auth_method': method},
    );
    _status = e is AppException && e.code == signInCancelled.code
        ? AuthStatus.unauthenticated
        : AuthStatus.error;
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await analyticsService.logLogout();
      await authService.signOut();
      _status = AuthStatus.unauthenticated;
    } catch (e, stack) {
      _status = AuthStatus.error;
      _errorMessage = 'Đăng xuất thất bại: $e';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'Sign-out error',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
