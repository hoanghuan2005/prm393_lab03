@TestOn('browser')
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/services/auth_service.dart';

class _Credential extends Fake implements UserCredential {}

class _User extends Fake implements User {
  AuthProvider? provider;
  bool reloaded = false;
  @override
  Future<UserCredential> linkWithPopup(AuthProvider value) async {
    provider = value;
    return _Credential();
  }

  @override
  Future<void> reload() async {
    reloaded = true;
  }
}

class _Auth extends Fake implements FirebaseAuth {
  AuthProvider? provider;
  Object? error;
  @override
  final _User currentUser = _User();
  @override
  Future<UserCredential> signInWithPopup(AuthProvider value) async {
    provider = value;
    if (error != null) throw error!;
    return _Credential();
  }
}

void main() {
  test('web uses Firebase Facebook popup with email scope', () async {
    final auth = _Auth();
    expect(
      await AuthService(auth: auth).signInWithFacebook(),
      isA<UserCredential>(),
    );
    expect(auth.provider?.providerId, 'facebook.com');
    expect((auth.provider as FacebookAuthProvider).scopes, contains('email'));
  });

  test('web links to current user with popup and reloads', () async {
    final auth = _Auth();
    expect(await AuthService(auth: auth).linkFacebook(), isA<UserCredential>());
    expect(auth.currentUser.provider?.providerId, 'facebook.com');
    expect(auth.currentUser.reloaded, true);
  });

  test('popup cancellation preserves the shared cancellation code', () async {
    final auth = _Auth()
      ..error = FirebaseAuthException(code: 'popup-closed-by-user');
    await expectLater(
      AuthService(auth: auth).signInWithFacebook(),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'sign-in-cancelled'),
      ),
    );
  });
}
