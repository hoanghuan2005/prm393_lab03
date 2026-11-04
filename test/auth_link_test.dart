import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/services/auth_service.dart';

class _FakeUserInfo extends Fake implements UserInfo {
  @override
  final String providerId;

  _FakeUserInfo(this.providerId);
}

class _FakeCredential extends Fake implements UserCredential {}

/// User with fixed providers that records link / unlink / reload calls
class _FakeUser extends Fake implements User {
  final List<String> providers;
  final Object? linkError;
  final List<String> calls = [];
  AuthCredential? linkedCredential;

  _FakeUser(this.providers, {this.linkError});

  @override
  List<UserInfo> get providerData => [
    for (final id in providers) _FakeUserInfo(id),
  ];

  @override
  bool get isAnonymous => providers.isEmpty;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    calls.add('linkWithCredential');
    if (linkError != null) throw linkError!;
    linkedCredential = credential;
    return _FakeCredential();
  }

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async {
    calls.add('linkWithProvider:${provider.providerId}');
    if (linkError != null) throw linkError!;
    return _FakeCredential();
  }

  @override
  Future<User> unlink(String providerId) async {
    calls.add('unlink:$providerId');
    return this;
  }

  @override
  Future<void> reload() async => calls.add('reload');
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  final User? currentUser;

  _FakeFirebaseAuth(this.currentUser);
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

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  final bool cancels;
  int signOuts = 0;

  _FakeGoogleSignIn({this.cancels = false});

  @override
  Future<GoogleSignInAccount?> signIn() async =>
      cancels ? null : _FakeGoogleAccount();

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOuts++;
    return null;
  }
}

AuthService _service(User? user, {GoogleSignIn? googleSignIn}) => AuthService(
  auth: _FakeFirebaseAuth(user),
  googleSignIn: googleSignIn ?? _FakeGoogleSignIn(),
);

void main() {
  group('linkedProviderIds', () {
    test('lists the provider ids of the current user', () {
      final service = _service(_FakeUser(['google.com', 'github.com']));
      expect(service.linkedProviderIds, {'google.com', 'github.com'});
    });

    test('is empty for a guest and when nobody is signed in', () {
      expect(_service(_FakeUser([])).linkedProviderIds, isEmpty);
      expect(_service(null).linkedProviderIds, isEmpty);
    });
  });

  group('linkGoogle', () {
    test(
      'returns null and links nothing when the picker is cancelled',
      () async {
        final user = _FakeUser([]);
        final service = _service(
          user,
          googleSignIn: _FakeGoogleSignIn(cancels: true),
        );

        expect(await service.linkGoogle(), isNull);
        expect(user.calls, isEmpty);
      },
    );

    test('links the Google credential, then reloads the user', () async {
      final user = _FakeUser(['github.com']);
      final service = _service(user);

      expect(await service.linkGoogle(), isA<UserCredential>());
      expect(user.calls, ['linkWithCredential', 'reload']);
      expect(user.linkedCredential?.providerId, 'google.com');
    });

    test('Firebase errors come out as AppException, without reload', () async {
      final user = _FakeUser([
        'github.com',
      ], linkError: FirebaseAuthException(code: 'credential-already-in-use'));
      final service = _service(user);

      await expectLater(
        service.linkGoogle(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'credential-already-in-use',
          ),
        ),
      );
      expect(user.calls, ['linkWithCredential']);
    });

    test('throws UnsupportedError where Google Sign-In is unavailable', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        () => _service(_FakeUser([])).linkGoogle(),
        throwsUnsupportedError,
      );
    });

    test('without a signed-in user throws AppException', () async {
      await expectLater(
        _service(null).linkGoogle(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'no-current-user'),
        ),
      );
    });
  });

  group('linkGithub', () {
    test('links with the GitHub provider, then reloads the user', () async {
      final user = _FakeUser(['google.com']);

      expect(await _service(user).linkGithub(), isA<UserCredential>());
      expect(user.calls, ['linkWithProvider:github.com', 'reload']);
    });
  });

  group('unlink', () {
    test('refuses the only sign-in method and does not call unlink', () async {
      final user = _FakeUser(['google.com']);

      await expectLater(
        _service(user).unlink('google.com'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'last-provider')
              .having(
                (e) => e.messageVi,
                'messageVi',
                'Phải giữ ít nhất một cách đăng nhập.',
              ),
        ),
      );
      expect(user.calls, isEmpty);
    });

    test(
      'unlinks Google, signs out of the Google picker and reloads',
      () async {
        final user = _FakeUser(['google.com', 'github.com']);
        final googleSignIn = _FakeGoogleSignIn();

        await _service(user, googleSignIn: googleSignIn).unlink('google.com');

        expect(user.calls, ['unlink:google.com', 'reload']);
        expect(googleSignIn.signOuts, 1);
      },
    );

    test('unlinking GitHub leaves the Google picker signed in', () async {
      final user = _FakeUser(['google.com', 'github.com']);
      final googleSignIn = _FakeGoogleSignIn();

      await _service(user, googleSignIn: googleSignIn).unlink('github.com');

      expect(user.calls, ['unlink:github.com', 'reload']);
      expect(googleSignIn.signOuts, 0);
    });
  });
}
