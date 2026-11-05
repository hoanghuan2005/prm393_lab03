import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/screens/login_screen.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/widgets/app_button.dart';
import 'package:provider/provider.dart';

const _accountExistsMessage =
    'Email này đã có tài khoản đăng nhập bằng Google. Hãy đăng nhập bằng '
    'Google, rồi vào Cá nhân → Tài khoản liên kết để thêm GitHub.';
const _accountExistsGithubMessage =
    'Email này đã có tài khoản đăng nhập bằng GitHub. Hãy đăng nhập bằng '
    'GitHub, rồi vào Cá nhân → Tài khoản liên kết để thêm Google.';
const _cancelledMessage =
    'Bạn đã huỷ đăng nhập. Chọn lại cách đăng nhập khi sẵn sàng.';
const _networkMessage = 'Không có kết nối mạng. Kiểm tra mạng rồi thử lại.';

/// FirebaseAuth whose sign-in calls fail with [error]
class _FailingFirebaseAuth extends Fake implements FirebaseAuth {
  final Object error;

  _FailingFirebaseAuth(this.error);

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Stream<User?> userChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      Future.error(error);

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) =>
      Future.error(error);

  @override
  Future<UserCredential> signInAnonymously() => Future.error(error);
}

class _FakeGoogleAuthentication extends Fake
    implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'access-token';

  @override
  String? get idToken => 'id-token';
}

class _FakeGoogleAccount extends Fake implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleAuthentication();
}

/// Google account picker that picks an account, or returns null when [cancels]
class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  final bool cancels;
  final Object? error;

  _FakeGoogleSignIn({this.cancels = false, this.error});

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (error != null) throw error!;
    return cancels ? null : _FakeGoogleAccount();
  }
}

class _CountingCrashlytics extends Fake implements CrashlyticsService {
  int handledErrors = 0;
  Object? lastError;
  Map<String, Object>? lastKeys;

  @override
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    handledErrors++;
    lastError = error;
    lastKeys = customKeys;
  }
}

class _UnusedUserService extends Fake implements UserService {}

class _UnusedBudgetService extends Fake implements BudgetService {}

class _UnusedAnalytics extends Fake implements AppAnalyticsService {}

class _FakeCredential extends Fake implements UserCredential {}

/// FirebaseAuth whose sign-in calls succeed
class _SucceedingFirebaseAuth extends _FailingFirebaseAuth {
  _SucceedingFirebaseAuth() : super(StateError('unused'));

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async =>
      _FakeCredential();

  @override
  Future<UserCredential> signInAnonymously() async => _FakeCredential();
}

class _ThrowingAnalytics extends Fake implements AppAnalyticsService {
  final List<String> methods = [];

  @override
  Future<void> logLogin({required String method}) async {
    methods.add(method);
    throw StateError('analytics down');
  }
}

/// FirebaseAnalytics whose every event fails
class _FailingFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
    List<AnalyticsEventItem>? items,
  }) => Future.error(StateError('analytics down'));
}

AuthViewModel _viewModel(
  AuthService authService,
  CrashlyticsService crashlytics,
) => AuthViewModel(
  authService: authService,
  userService: _UnusedUserService(),
  budgetService: _UnusedBudgetService(),
  analyticsService: _UnusedAnalytics(),
  crashlyticsService: crashlytics,
);

AuthService _authFailingWith(Object error, {GoogleSignIn? googleSignIn}) =>
    AuthService(
      auth: _FailingFirebaseAuth(error),
      googleSignIn: googleSignIn ?? _FakeGoogleSignIn(),
    );

FirebaseAuthException _authError(String code) =>
    FirebaseAuthException(code: code, message: 'raw english message');

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

    test('Android and iOS cancel codes map to cancelled', () {
      // Android: web-context-canceled; iOS: web-context-cancelled
      for (final code in ['web-context-canceled', 'web-context-cancelled']) {
        final mapped = mapFirebaseError(FirebaseAuthException(code: code));
        expect(mapped.code, 'sign-in-cancelled', reason: code);
        expect(mapped.messageVi, _cancelledMessage, reason: code);
      }
    });
  });

  group('AuthService', () {
    test('sign-in failures are thrown as AppException', () async {
      final service = _authFailingWith(_authError('network-request-failed'));

      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        service.signInWithGithub(),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        service.signInAnonymously(),
        throwsA(isA<AppException>()),
      );
    });

    test('cancelling the Google account picker still returns null', () async {
      final service = _authFailingWith(
        _authError('internal-error'),
        googleSignIn: _FakeGoogleSignIn(cancels: true),
      );

      expect(await service.signInWithGoogle(), isNull);
    });
  });

  group('AuthViewModel', () {
    test('Google network-request-failed shows the network message', () async {
      final crashlytics = _CountingCrashlytics();
      final vm = _viewModel(
        _authFailingWith(_authError('network-request-failed')),
        crashlytics,
      );

      expect(await vm.signInWithGoogle(), isFalse);
      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, _networkMessage);
      expect(crashlytics.handledErrors, 0);
      vm.dispose();
    });

    test('Google picker network error shows the network message', () async {
      final vm = _viewModel(
        _authFailingWith(
          _authError('internal-error'),
          googleSignIn: _FakeGoogleSignIn(
            error: PlatformException(code: 'network_error'),
          ),
        ),
        _CountingCrashlytics(),
      );

      await vm.signInWithGoogle();
      expect(vm.errorMessage, _networkMessage);
      vm.dispose();
    });

    test('GitHub account collision shows the Vietnamese message', () async {
      final vm = _viewModel(
        _authFailingWith(
          _authError('account-exists-with-different-credential'),
        ),
        _CountingCrashlytics(),
      );

      expect(await vm.signInWithGithub(), isFalse);
      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, _accountExistsMessage);
      vm.dispose();
    });

    test('closing the GitHub window shows the cancelled message and is not '
        'reported to Crashlytics', () async {
      final crashlytics = _CountingCrashlytics();
      final vm = _viewModel(
        _authFailingWith(_authError('web-context-canceled')),
        crashlytics,
      );

      await vm.signInWithGithub();
      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.errorMessage, _cancelledMessage);
      expect(crashlytics.handledErrors, 0);
      vm.dispose();
    });

    test('unknown codes never leak the raw Firebase message', () async {
      final crashlytics = _CountingCrashlytics();
      final vm = _viewModel(
        _authFailingWith(_authError('internal-error')),
        crashlytics,
      );

      await vm.signInWithGithub();
      expect(vm.errorMessage, isNot(contains('raw english message')));
      expect(
        vm.errorMessage,
        'Không đăng nhập được. Bấm "Thử lại" sau ít phút.',
      );
      // No message of its own, so it has a cause and is recorded
      expect(crashlytics.handledErrors, 1);
      expect(crashlytics.lastKeys, {
        'auth_method': 'github',
        'error_code': 'internal-error',
      });
      vm.dispose();
    });

    test('operation-not-allowed is recorded with the auth method', () async {
      final crashlytics = _CountingCrashlytics();
      final error = _authError('operation-not-allowed');
      final vm = _viewModel(_authFailingWith(error), crashlytics);

      await vm.signInWithGoogle();
      expect(vm.status, AuthStatus.error);
      expect(crashlytics.handledErrors, 1);
      expect(crashlytics.lastError, same(error));
      expect(crashlytics.lastKeys, {
        'auth_method': 'google',
        'error_code': 'operation-not-allowed',
      });
      vm.dispose();
    });

    test('errors with their own message are not recorded', () async {
      final crashlytics = _CountingCrashlytics();
      for (final code in [
        'web-context-canceled',
        'network-request-failed',
        'popup-blocked',
        'too-many-requests',
        'user-disabled',
        'account-exists-with-different-credential',
      ]) {
        final vm = _viewModel(_authFailingWith(_authError(code)), crashlytics);
        await vm.signInWithGithub();
        expect(crashlytics.handledErrors, 0, reason: code);
        vm.dispose();
      }
    });

    test('closing the Google account picker shows the shared cancelled '
        'message and is not recorded', () async {
      final crashlytics = _CountingCrashlytics();
      final vm = _viewModel(
        _authFailingWith(
          _authError('internal-error'),
          googleSignIn: _FakeGoogleSignIn(cancels: true),
        ),
        crashlytics,
      );

      expect(await vm.signInWithGoogle(), isFalse);
      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.errorMessage, _cancelledMessage);
      expect(vm.errorMessage, signInCancelled.messageVi);
      expect(crashlytics.handledErrors, 0);
      vm.dispose();
    });

    test(
      'unexpected errors report the original error to Crashlytics',
      () async {
        final crashlytics = _CountingCrashlytics();
        final original = StateError('boom');
        final vm = _viewModel(_authFailingWith(original), crashlytics);

        await vm.signInAnonymously();
        expect(vm.status, AuthStatus.error);
        expect(vm.errorMessage, AppException.unknown.messageVi);
        expect(crashlytics.handledErrors, 1);
        expect(crashlytics.lastError, same(original));
        expect(crashlytics.lastKeys, {
          'auth_method': 'guest',
          'error_code': 'unknown',
        });
        vm.dispose();
      },
    );
  });

  group('Analytics during sign-in', () {
    test('a failing logLogin does not fail the sign-in', () async {
      final crashlytics = _CountingCrashlytics();
      final analytics = _ThrowingAnalytics();
      final vm = AuthViewModel(
        authService: AuthService(
          auth: _SucceedingFirebaseAuth(),
          googleSignIn: _FakeGoogleSignIn(),
        ),
        userService: _UnusedUserService(),
        budgetService: _UnusedBudgetService(),
        analyticsService: analytics,
        crashlyticsService: crashlytics,
      );

      expect(await vm.signInAnonymously(), isTrue);
      expect(await vm.signInWithGithub(), isTrue);
      expect(analytics.methods, ['guest', 'github']);
      expect(vm.errorMessage, isNull);
      expect(vm.status, isNot(AuthStatus.error));
      expect(crashlytics.handledErrors, 0);
      vm.dispose();
    });

    test('AppAnalyticsService swallows Firebase Analytics errors', () async {
      final service = AppAnalyticsService(
        analytics: _FailingFirebaseAnalytics(),
      );

      await expectLater(service.logLogin(method: 'guest'), completes);
    });
  });

  group('account-exists-with-different-credential', () {
    test('GitHub sign-in points to Google and keeps the code', () async {
      final vm = _viewModel(
        _authFailingWith(_authError(accountExistsCode)),
        _CountingCrashlytics(),
      );

      await vm.signInWithGithub();

      expect(vm.errorMessage, _accountExistsMessage);
      expect(vm.suggestedProviderId, 'google.com');
      expect(
        mapFirebaseError(_authError(accountExistsCode)).code,
        'account-exists-with-different-credential',
      );
      vm.dispose();
    });

    test('Google sign-in points to GitHub', () async {
      final crashlytics = _CountingCrashlytics();
      final service = _authFailingWith(_authError(accountExistsCode));
      final vm = _viewModel(service, crashlytics);

      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', accountExistsCode),
        ),
      );
      await vm.signInWithGoogle();

      expect(vm.errorMessage, _accountExistsGithubMessage);
      expect(vm.suggestedProviderId, 'github.com');
      expect(crashlytics.handledErrors, 0);
      vm.dispose();
    });

    test('other errors and the next attempt clear the suggestion', () async {
      final vm = _viewModel(
        _authFailingWith(_authError(accountExistsCode)),
        _CountingCrashlytics(),
      );
      await vm.signInWithGithub();
      expect(vm.suggestedProviderId, 'google.com');

      await vm.signInAnonymously();
      expect(vm.suggestedProviderId, isNull);
      vm.dispose();
    });
  });

  group('LoginScreen', () {
    Future<void> pumpLogin(WidgetTester tester, AuthViewModel vm) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
    }

    testWidgets('shows the network message when Google sign-in is offline', (
      tester,
    ) async {
      final vm = _viewModel(
        _authFailingWith(_authError('network-request-failed')),
        _CountingCrashlytics(),
      );
      await pumpLogin(tester, vm);

      await tester.tap(find.text('Đăng nhập với Google'));
      await tester.pumpAndSettle();

      expect(find.text(_networkMessage), findsOneWidget);
    });

    testWidgets(
      'shows the cancelled message when the Google picker is closed',
      (tester) async {
        final vm = _viewModel(
          _authFailingWith(
            _authError('internal-error'),
            googleSignIn: _FakeGoogleSignIn(cancels: true),
          ),
          _CountingCrashlytics(),
        );
        await pumpLogin(tester, vm);

        await tester.tap(find.text('Đăng nhập với Google'));
        await tester.pumpAndSettle();

        expect(find.text(_cancelledMessage), findsOneWidget);
      },
    );

    testWidgets(
      'shows the cancelled message when the GitHub window is closed',
      (tester) async {
        final vm = _viewModel(
          _authFailingWith(_authError('web-context-canceled')),
          _CountingCrashlytics(),
        );
        await pumpLogin(tester, vm);

        await tester.tap(find.text('Đăng nhập với GitHub'));
        await tester.pumpAndSettle();

        expect(find.text(_cancelledMessage), findsOneWidget);
      },
    );

    testWidgets('GitHub collision: the message sits right above the Google '
        'button', (tester) async {
      final vm = _viewModel(
        _authFailingWith(_authError(accountExistsCode)),
        _CountingCrashlytics(),
      );
      await pumpLogin(tester, vm);

      await tester.tap(find.text('Đăng nhập với GitHub'));
      await tester.pumpAndSettle();

      final banner = tester.getRect(
        find.byKey(const Key('login-error-banner')),
      );
      final google = tester.getRect(find.byKey(const Key('login-google')));
      final github = tester.getRect(find.byKey(const Key('login-github')));
      expect(find.text(_accountExistsMessage), findsOneWidget);
      expect(banner.bottom, lessThanOrEqualTo(google.top));
      expect(google.top - banner.bottom, lessThan(32));
      expect(google.top, lessThan(github.top));
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byKey(const Key('login-google'))).variant,
        AppButtonVariant.primary,
      );
    });

    testWidgets('Google collision: the message moves above the GitHub button '
        'and GitHub becomes the main button', (tester) async {
      final vm = _viewModel(
        _authFailingWith(_authError(accountExistsCode)),
        _CountingCrashlytics(),
      );
      await pumpLogin(tester, vm);

      await tester.tap(find.text('Đăng nhập với Google'));
      await tester.pumpAndSettle();

      final banner = tester.getRect(
        find.byKey(const Key('login-error-banner')),
      );
      final google = tester.getRect(find.byKey(const Key('login-google')));
      final github = tester.getRect(find.byKey(const Key('login-github')));
      expect(find.text(_accountExistsGithubMessage), findsOneWidget);
      expect(banner.top, greaterThanOrEqualTo(google.bottom));
      expect(banner.bottom, lessThanOrEqualTo(github.top));
      expect(github.top - banner.bottom, lessThan(32));
      expect(
        tester.widget<AppButton>(find.byKey(const Key('login-github'))).variant,
        AppButtonVariant.primary,
      );
      expect(
        tester.widget<AppButton>(find.byKey(const Key('login-google'))).variant,
        AppButtonVariant.secondary,
      );
    });
  });
}
