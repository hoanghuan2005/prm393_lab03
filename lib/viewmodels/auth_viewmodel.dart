import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import '../services/pending_writes.dart';
import '../services/user_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// AppException code for a sign-in the user closed or cancelled
const _cancelledCode = 'sign-in-cancelled';

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
    } on AppException catch (e, stack) {
      await _onSignInFailed(e, stack, reason: 'Google sign-in error');
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
    } on AppException catch (e, stack) {
      await _onSignInFailed(e, stack, reason: 'GitHub sign-in error');
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

  /// Guest / Anonymous sign in for quick testing
  Future<bool> signInAnonymously() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signInAnonymously();
      await analyticsService.logLogin(method: 'guest');
      return true;
    } on AppException catch (e, stack) {
      await _onSignInFailed(e, stack, reason: 'Anonymous sign-in error');
      return false;
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

  /// Shows the mapped message; only unexpected errors reach Crashlytics
  Future<void> _onSignInFailed(
    AppException e,
    StackTrace stack, {
    required String reason,
  }) async {
    _errorMessage = e.messageVi;
    if (e.code == _cancelledCode) {
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.error;
      if (e.code == AppException.unknown.code) {
        await crashlyticsService.recordHandledError(e, stack, reason: reason);
      }
    }
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
