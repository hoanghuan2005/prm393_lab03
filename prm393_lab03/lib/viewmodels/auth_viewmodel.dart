import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import '../services/pending_writes.dart';
import '../services/user_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ViewModel managing Authentication state & Google Sign-In
class AuthViewModel extends ChangeNotifier {
  final AuthService authService;
  final UserService userService;
  final BudgetService budgetService;
  final AppAnalyticsService analyticsService;
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
  String? get errorMessage => _errorMessage;
  String get displayName => authService.displayName;

  /// uid handed to every user-data ViewModel; null until the user documents are ready
  String? get userId =>
      _status == AuthStatus.authenticated ? _currentUser?.uid : null;

  void _init() {
    // authStateChanges emits the current user right away; AuthGate shows loading until then
    _authSubscription = authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
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
    await _prepareUserData(user);

    if (event != _authEvent) return;
    _status = AuthStatus.authenticated;
    notifyListeners();
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
        _errorMessage = 'Bạn đã hủy đăng nhập Google.';
        notifyListeners();
        return false;
      }

      await analyticsService.logLogin(method: 'google');
      return true;
    } on UnsupportedError {
      _status = AuthStatus.error;
      _errorMessage =
          'Đăng nhập Google chưa hỗ trợ trên Windows. Hãy dùng chế độ Khách.';
      notifyListeners();
      return false;
    } catch (e, stack) {
      _status = AuthStatus.error;
      _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'Google sign-in error',
      );
      notifyListeners();
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

      await analyticsService.logLogin(method: 'github');
      return true;
    } on FirebaseAuthException catch (e, stack) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'Đăng nhập GitHub thất bại.';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'GitHub sign-in error: ${e.code}',
      );
      notifyListeners();
      return false;
    } catch (e, stack) {
      _status = AuthStatus.error;
      _errorMessage = 'Đăng nhập GitHub thất bại. Vui lòng thử lại.';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'GitHub sign-in error',
      );
      notifyListeners();
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
      await analyticsService.logLogin(method: 'guest');
      return true;
    } catch (e, stack) {
      _status = AuthStatus.error;
      _errorMessage = 'Đăng nhập khách thất bại.';
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'Anonymous sign-in error',
      );
      notifyListeners();
      return false;
    }
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
