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
