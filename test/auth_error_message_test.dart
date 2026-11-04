import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';

const _accountExistsMessage =
    'Email này đã có tài khoản đăng nhập bằng cách khác (ví dụ Google). '
    'Hãy đăng nhập bằng cách đó.';
const _cancelledMessage = 'Bạn đã huỷ đăng nhập. Bấm "Thử lại" khi sẵn sàng.';

class _FailingGithubAuth extends Fake implements AuthService {
  final FirebaseAuthException error;

  _FailingGithubAuth(this.error);

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential?> signInWithGithub() async => throw error;
}

class _NoopCrashlytics extends Fake implements CrashlyticsService {
  @override
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {}
}

AuthViewModel _viewModelFailingWith(String code) => AuthViewModel(
  authService: _FailingGithubAuth(
    FirebaseAuthException(code: code, message: 'raw english message'),
  ),
  userService: _UnusedUserService(),
  budgetService: _UnusedBudgetService(),
  analyticsService: _UnusedAnalytics(),
  crashlyticsService: _NoopCrashlytics(),
);

class _UnusedUserService extends Fake implements UserService {}

class _UnusedBudgetService extends Fake implements BudgetService {}

class _UnusedAnalytics extends Fake implements AppAnalyticsService {}

void main() {
  group('mapFirebaseError', () {
    test(
      'account-exists-with-different-credential has a Vietnamese message',
      () {
        final mapped = mapFirebaseError(
          FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          ),
        );
        expect(mapped.code, 'account-exists-with-different-credential');
        expect(mapped.messageVi, _accountExistsMessage);
      },
    );

    test('Android cancel code from signInWithProvider maps to cancelled', () {
      // Android SDK ERROR_WEB_CONTEXT_CANCELED arrives as web-context-canceled
      final mapped = mapFirebaseError(
        FirebaseAuthException(code: 'web-context-canceled'),
      );
      expect(mapped.code, 'sign-in-cancelled');
      expect(mapped.messageVi, _cancelledMessage);
    });
  });

  group('AuthViewModel.signInWithGithub', () {
    test('account collision shows the Vietnamese message', () async {
      final vm = _viewModelFailingWith(
        'account-exists-with-different-credential',
      );

      expect(await vm.signInWithGithub(), isFalse);
      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, _accountExistsMessage);
      vm.dispose();
    });

    test('closing the GitHub window shows the cancelled message', () async {
      final vm = _viewModelFailingWith('web-context-canceled');

      await vm.signInWithGithub();
      expect(vm.errorMessage, _cancelledMessage);
      vm.dispose();
    });

    test('unknown codes never leak the raw Firebase message', () async {
      final vm = _viewModelFailingWith('internal-error');

      await vm.signInWithGithub();
      expect(vm.errorMessage, isNot(contains('raw english message')));
      expect(
        vm.errorMessage,
        'Không đăng nhập được. Bấm "Thử lại" sau ít phút.',
      );
      vm.dispose();
    });
  });
}
