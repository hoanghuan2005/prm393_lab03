import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ViewModel managing Authentication state & Google Sign-In
class AuthViewModel extends ChangeNotifier {
  final AuthService authService;
  final AppAnalyticsService analyticsService;
  final CrashlyticsService crashlyticsService;

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthViewModel({
    required this.authService,
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
  String? get userId => _currentUser?.uid;

  void _init() {
    _currentUser = authService.currentUser;
    _status = _currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;

    _authSubscription = authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      if (user != null) {
        analyticsService.setUserId(user.uid);
        crashlyticsService.setUserId(user.uid);
      }
      notifyListeners();
    });
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
      _status = AuthStatus.authenticated;
      notifyListeners();
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
      _status = AuthStatus.authenticated;
      notifyListeners();
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
