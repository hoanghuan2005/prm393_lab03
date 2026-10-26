import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
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
