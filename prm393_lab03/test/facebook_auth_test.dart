import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/facebook_login_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';

import 'support/linked_auth_fakes.dart';

class _Facebook extends Fake implements FacebookAuth {
  LoginStatus status = LoginStatus.success;
  Object? error;
  bool limited = false;
  int logins = 0;
  int logouts = 0;
  String? sentNonce;

  @override
  Future<LoginResult> login({
    List<String> permissions = const ['email', 'public_profile'],
    LoginBehavior loginBehavior = LoginBehavior.nativeWithFallback,
    LoginTracking loginTracking = LoginTracking.limited,
    String? nonce,
  }) async {
    logins++;
    expect(permissions, ['public_profile', 'email']);
    sentNonce = nonce;
    if (error != null) throw error!;
    return LoginResult(
      status: status,
      accessToken: limited
          ? LimitedToken(
              tokenString: 'id-token',
              userId: 'fb-id',
              userName: 'An',
              userEmail: null,
              nonce: nonce!,
            )
          : ClassicToken(
              declinedPermissions: const [],
              grantedPermissions: const ['public_profile', 'email'],
              tokenString: 'access-token',
              userId: 'fb-id',
              expires: DateTime(2030),
              applicationId: 'test-app',
            ),
    );
  }

  @override
  Future<void> logOut() async {
    logouts++;
  }
}

class _Credential extends Fake implements UserCredential {}

class _User extends Fake implements User {
  final List<String> providers;
  final Object? linkError;
  final calls = <String>[];
  _User(this.providers, {this.linkError});

  @override
  String get uid => 'same-uid';
  @override
  String? get email => null;
  @override
  String? get displayName => 'An';
  @override
  bool get isAnonymous => providers.isEmpty;
  @override
  List<UserInfo> get providerData => [
    for (final id in providers) FakeUserInfo(id, displayName: 'An'),
  ];
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    calls.add('link:${credential.providerId}');
    if (linkError != null) throw linkError!;
    providers.add(credential.providerId);
    return _Credential();
  }

  @override
  Future<User> unlink(String providerId) async {
    calls.add('unlink:$providerId');
    providers.remove(providerId);
    return this;
  }

  @override
  Future<void> reload() async {
    calls.add('reload');
  }
}

class _Auth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast();
  @override
  User? currentUser;
  Object? error;
  AuthCredential? credential;
  int signIns = 0;
  @override
  Stream<User?> userChanges() => changes.stream;
  @override
  Future<UserCredential> signInWithCredential(AuthCredential value) async {
    signIns++;
    if (error != null) throw error!;
    credential = value;
    currentUser = _User(['facebook.com']);
    changes.add(currentUser);
    return _Credential();
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}

class _Google extends Fake implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

class _Users extends Fake implements UserService {
  bool prepared = false;
  String? email;
  @override
  Future<void> ensureUserDocument(
    String uid, {
    String? displayName,
    String? email,
    required bool isAnonymous,
  }) async {
    prepared = true;
    this.email = email;
    expect(uid, 'same-uid');
    expect(displayName, 'An');
    expect(isAnonymous, false);
  }
}

class _Budget extends Fake implements BudgetService {
  @override
  Future<void> ensureDefaultGroups(String uid) async {}
}

class _Analytics extends Fake implements AppAnalyticsService {
  final methods = <String>[];
  @override
  Future<void> logLogin({required String method}) async {
    methods.add(method);
  }

  @override
  Future<void> setUserId(String? userId) async {}
}

class _Crash extends CountingCrashlytics {
  @override
  Future<void> setUserId(String userId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Facebook facebook;
  late _Auth auth;
  late FacebookLoginService gateway;
  late AuthService service;
  setUp(() {
    facebook = _Facebook();
    auth = _Auth();
    gateway = FacebookLoginService(
      facebook: facebook,
      configured: () async => true,
    );
    service = AuthService(
      auth: auth,
      facebookLogin: gateway,
      googleSignIn: _Google(),
    );
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await auth.changes.close();
  });

  test('unconfigured native login never invokes SDK', () async {
    final blocked = FacebookLoginService(
      facebook: facebook,
      configured: () async => false,
    );
    await expectLater(
      blocked.credential(),
      throwsA(FacebookLoginService.notConfigured),
    );
    expect(facebook.logins, 0);
  });

  test('Android exchanges classic access token with Firebase', () async {
    expect(await service.signInWithFacebook(), isA<UserCredential>());
    expect(auth.credential?.providerId, 'facebook.com');
    expect((auth.credential as OAuthCredential).accessToken, 'access-token');
    expect(facebook.sentNonce, isNull);
  });

  test('iOS Limited Login passes a fresh hashed nonce and ID token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    facebook.limited = true;
    final first = (await gateway.credential())!;
    final rawNonce = first.asMap()['rawNonce'] as String;
    expect(first.idToken, 'id-token');
    expect(first.accessToken, isNull);
    expect(
      facebook.sentNonce,
      sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final second = (await gateway.credential())!;
    expect(second.asMap()['rawNonce'], isNot(rawNonce));
  });

  test('cancelled SDK result does not call Firebase', () async {
    facebook.status = LoginStatus.cancelled;
    expect(await service.signInWithFacebook(), isNull);
    expect(auth.signIns, 0);
  });

  test(
    'SDK cancellation exception is silent; network failure is mapped',
    () async {
      facebook.error = PlatformException(code: 'CANCELLED');
      expect(await gateway.credential(), isNull);
      facebook.error = PlatformException(code: 'network_error');
      await expectLater(
        gateway.credential(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'network')),
      );
    },
  );

  test('desktop does not open Facebook SDK', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await expectLater(service.signInWithFacebook(), throwsUnsupportedError);
    expect(facebook.logins, 0);
  });

  test('Facebook link upgrades guest without replacing UID', () async {
    final user = _User([]);
    auth.currentUser = user;
    expect(await service.linkFacebook(), isA<UserCredential>());
    expect(auth.currentUser?.uid, 'same-uid');
    expect(user.calls, ['link:facebook.com', 'reload']);
  });

  test('credential collision has Facebook-specific guidance', () async {
    auth.currentUser = _User([
      'google.com',
    ], linkError: FirebaseAuthException(code: 'credential-already-in-use'));
    await expectLater(
      service.linkFacebook(),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', 'credential-already-in-use')
            .having(
              (e) => e.messageVi,
              'message',
              contains('Tài khoản Facebook này'),
            ),
      ),
    );
  });

  test('already-linked refreshes state without reporting an error', () async {
    final user = _User([
      'facebook.com',
    ], linkError: FirebaseAuthException(code: 'provider-already-linked'));
    auth.currentUser = user;
    expect(await service.linkFacebook(), isNull);
    expect(user.calls.last, 'reload');
  });

  test('last Facebook method is kept; multiple methods allow unlink and SDK logout', () async {
    final user = _User(['facebook.com']);
    auth.currentUser = user;
    await expectLater(
      service.unlink('facebook.com'),
      throwsA(AuthService.lastProvider),
    );
    expect(user.calls, isEmpty);
    expect(facebook.logouts, 0);
    user.providers.add('google.com');
    await service.unlink('facebook.com');
    expect(user.calls, ['unlink:facebook.com', 'reload']);
    expect(facebook.logouts, 1);
  });

  test(
    'signOut clears SDK session even when Firebase user is cleared',
    () async {
      auth.currentUser = _User(['facebook.com']);
      await service.signOut();
      expect(auth.currentUser, isNull);
      expect(facebook.logouts, 1);
    },
  );

  group('AuthViewModel', () {
    late _Users users;
    late _Analytics analytics;
    late _Crash crash;
    late AuthViewModel vm;
    setUp(() {
      users = _Users();
      analytics = _Analytics();
      crash = _Crash();
      vm = AuthViewModel(
        authService: service,
        userService: users,
        budgetService: _Budget(),
        analyticsService: analytics,
        crashlyticsService: crash,
      );
    });
    tearDown(() => vm.dispose());

    test('success with no email prepares user and logs facebook', () async {
      expect(await vm.signInWithFacebook(), true);
      await Future<void>.delayed(Duration.zero);
      expect(vm.status, AuthStatus.authenticated);
      expect(users.prepared, true);
      expect(users.email, isNull);
      expect(analytics.methods, ['facebook']);
      expect(vm.errorMessage, isNull);
    });

    test('native cancellation has no error or analytics', () async {
      facebook.status = LoginStatus.cancelled;
      expect(await vm.signInWithFacebook(), false);
      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.errorMessage, isNull);
      expect(analytics.methods, isEmpty);
      expect(crash.handledErrors, 0);
    });

    test('popup cancellation is also silent', () async {
      auth.error = FirebaseAuthException(code: 'popup-closed-by-user');
      expect(await vm.signInWithFacebook(), false);
      expect(vm.errorMessage, isNull);
      expect(vm.status, AuthStatus.unauthenticated);
    });

    test('email collision uses shared neutral message', () async {
      auth.error = FirebaseAuthException(code: accountExistsCode);
      expect(await vm.signInWithFacebook(), false);
      expect(vm.errorMessage, accountExistsOtherMethod.messageVi);
      expect(crash.handledErrors, 0);
    });
  });

  test(
    'linked ViewModel keeps no-email label and guest upgrade semantics',
    () async {
      final fakeAuth = FakeLinkAuthService(FakeLinkUser([]))
        ..afterLink = () =>
            FakeLinkUser([FakeUserInfo('facebook.com', displayName: 'An')]);
      final users = RecordingUserService();
      final vm = LinkedAccountsViewModel(
        authService: fakeAuth,
        userService: users,
      )..updateUid('uid-1');
      addTearDown(vm.dispose);
      expect(await vm.linkFacebook(), true);
      expect(vm.rowFor('facebook.com').label, 'An');
      expect(vm.canUnlink('facebook.com'), false);
      expect(users.calls.single.isAnonymous, false);
      expect(vm.successMessage, 'Đã liên kết Facebook.');
      fakeAuth.user = FakeLinkUser([FakeUserInfo('facebook.com')]);
      expect(vm.rowFor('facebook.com').label, 'Chưa có email');
    },
  );

  test('linked ViewModel cancellation and unlink outcomes', () async {
    final fakeAuth = FakeLinkAuthService(
      FakeLinkUser([FakeUserInfo('google.com')]),
    )..cancelLink = true;
    final vm = LinkedAccountsViewModel(
      authService: fakeAuth,
      userService: RecordingUserService(),
    )..updateUid('uid-1');
    addTearDown(vm.dispose);
    expect(await vm.linkFacebook(), false);
    expect(vm.errorMessage, isNull);
    expect(vm.successMessage, isNull);
    fakeAuth.error = const AppException(
      'credential-already-in-use',
      'Facebook đã thuộc tài khoản khác.',
    );
    expect(await vm.linkFacebook(), false);
    expect(vm.errorMessage, contains('tài khoản khác'));
    fakeAuth.error = AuthService.lastProvider;
    expect(await vm.unlink('facebook.com'), false);
    expect(vm.errorMessage, AuthService.lastProvider.messageVi);
    fakeAuth.error = null;
    expect(await vm.unlink('facebook.com'), true);
    expect(fakeAuth.unlinked, ['facebook.com']);
  });
}
