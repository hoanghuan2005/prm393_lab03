import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/admin_auth_service.dart';
import 'safe_notifier.dart';

sealed class AdminAuthState {
  const AdminAuthState();
}

/// Waiting for Firebase Auth, or reading the role of the signed-in account
class AuthChecking extends AdminAuthState {
  const AuthChecking();
}

class AuthSignedOut extends AdminAuthState {
  /// Why the last attempt did not end on the admin pages
  final String? message;
  final bool signingIn;

  const AuthSignedOut({this.message, this.signingIn = false});
}

/// Signed in with a role allowed on the web admin (staff or admin)
class AuthAdmin extends AdminAuthState {
  final AdminAccount account;
  final AppRole role;

  const AuthAdmin(this.account, this.role);

  bool get isAdmin => role == AppRole.admin;
}

/// Routes by auth state and role: only `users/{uid}.role` staff or admin reaches
/// the admin pages; any other Google account is signed out with a message.
class AuthViewModel extends ChangeNotifier with SafeNotifier {
  final AdminAuthService _auth;
  final RoleService _roles;
  StreamSubscription<AdminAccount?>? _subscription;

  AdminAuthState _state = const AuthChecking();

  /// Kept across the sign-out that follows a rejected account
  String? _message;

  /// Ignores a role answer that arrives after the account changed again
  int _generation = 0;

  AuthViewModel(this._auth, this._roles) {
    _subscription = _auth.authStateChanges().listen(
      _onAccount,
      onError: (_) => _set(const AuthSignedOut(message: _networkMessage)),
    );
  }

  static const String _networkMessage =
      'Không kết nối được Firebase. Kiểm tra mạng rồi thử lại.';

  AdminAuthState get state => _state;

  Future<void> _onAccount(AdminAccount? account) async {
    final generation = ++_generation;
    if (account == null) {
      _set(AuthSignedOut(message: _message));
      return;
    }
    _set(const AuthChecking());
    final AppRole role;
    try {
      role = await _roles.roleOf(account.uid);
    } catch (e) {
      if (generation != _generation) return;
      _message =
          'Không kiểm tra được quyền truy cập. ${describeFirestoreError(e)}';
      await _auth.signOut();
      return;
    }
    if (generation != _generation) return;
    if (role.canUseWebAdmin) {
      _message = null;
      _set(AuthAdmin(account, role));
      return;
    }
    _message =
        'Tài khoản ${account.email ?? account.uid} không phải nhân viên hay quản trị viên. '
        'Trang này dành cho nhân viên và admin; người dùng hãy dùng app Why I Buy trên điện thoại.';
    await _auth.signOut();
  }

  Future<void> signIn() async {
    final current = _state;
    if (current is AuthSignedOut && current.signingIn) return;
    _message = null;
    _set(const AuthSignedOut(signingIn: true));
    try {
      // Success is handled by authStateChanges (role check, then the admin pages)
      await _auth.signInWithGoogle();
    } on SignInException catch (e) {
      _message = signInMessage(e.failure);
      _set(AuthSignedOut(message: _message));
    } catch (_) {
      _message = signInMessage(SignInFailure.unknown);
      _set(AuthSignedOut(message: _message));
    }
  }

  Future<void> signOut() async {
    _message = null;
    await _auth.signOut();
  }

  @visibleForTesting
  static String signInMessage(SignInFailure failure) => switch (failure) {
    SignInFailure.cancelled =>
      'Bạn đã huỷ đăng nhập. Bấm "Đăng nhập với Google" để thử lại.',
    SignInFailure.popupBlocked => 'Trình duyệt đã chặn cửa sổ đăng nhập. Cho phép popup cho trang này rồi thử lại.',
    SignInFailure.network => _networkMessage,
    SignInFailure.unauthorizedDomain => 'Tên miền này chưa có trong Authorized domains của Firebase Authentication.',
    SignInFailure.unknown => 'Đăng nhập không thành công. Vui lòng thử lại.',
  };

  void _set(AdminAuthState state) {
    _state = state;
    notifySafely();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
