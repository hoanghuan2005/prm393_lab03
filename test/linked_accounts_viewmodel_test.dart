import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/core/formatters/email_format.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';

const _googleId = LinkedAccountsViewModel.googleId;
const _githubId = LinkedAccountsViewModel.githubId;

class _FakeUserInfo extends Fake implements UserInfo {
  @override
  final String providerId;
  @override
  final String? email;
  @override
  final String? displayName;

  _FakeUserInfo(this.providerId, {this.email, this.displayName});
}

class _FakeUser extends Fake implements User {
  @override
  final List<UserInfo> providerData;
  @override
  final String? email;

  _FakeUser(this.providerData, {this.email});

  /// Top-level name stays empty, as for a guest who just linked
  @override
  String? get displayName => null;

  @override
  bool get isAnonymous => providerData.isEmpty;
}

class _FakeCredential extends Fake implements UserCredential {}

/// AuthService whose link / unlink swap the current user, or fail with [error]
class _FakeAuthService extends Fake implements AuthService {
  final _changes = StreamController<User?>.broadcast();
  User? user;
  Object? error;
  bool cancelLink = false;
  final List<String> unlinked = [];

  /// User returned after a successful link
  User? Function()? afterLink;

  _FakeAuthService(this.user);

  @override
  Stream<User?> get userChanges => _changes.stream;

  @override
  User? get currentUser => user;

  @override
  String? get currentUserId => user == null ? null : 'uid-1';

  @override
  Set<String> get linkedProviderIds => {
    for (final info in user?.providerData ?? const <UserInfo>[])
      info.providerId,
  };

  Future<UserCredential?> _link() async {
    if (error != null) throw error!;
    if (cancelLink) return null;
    user = afterLink?.call();
    _changes.add(user);
    return _FakeCredential();
  }

  @override
  Future<UserCredential?> linkGoogle() => _link();

  @override
  Future<UserCredential?> linkGithub() => _link();

  @override
  Future<void> unlink(String providerId) async {
    if (error != null) throw error!;
    unlinked.add(providerId);
  }
}

class _RecordingUserService extends Fake implements UserService {
  final List<({String uid, String? displayName, bool isAnonymous})> calls = [];

  @override
  Future<void> ensureUserDocument(
    String uid, {
    String? displayName,
    String? email,
    required bool isAnonymous,
  }) async {
    calls.add((uid: uid, displayName: displayName, isAnonymous: isAnonymous));
  }
}

class _CountingCrashlytics extends Fake implements CrashlyticsService {
  int handledErrors = 0;
  Map<String, Object>? lastKeys;

  @override
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    handledErrors++;
    lastKeys = customKeys;
  }
}

_FakeUser _googleUser() => _FakeUser([
  _FakeUserInfo(_googleId, email: 'someone@gmail.com', displayName: 'An'),
], email: 'someone@gmail.com');

void main() {
  late _RecordingUserService userService;
  late _CountingCrashlytics crashlytics;

  setUp(() {
    userService = _RecordingUserService();
    crashlytics = _CountingCrashlytics();
  });

  LinkedAccountsViewModel viewModel(_FakeAuthService auth) =>
      LinkedAccountsViewModel(
        authService: auth,
        userService: userService,
        crashlyticsService: crashlytics,
      )..updateUid('uid-1');

  test('maskEmail keeps only the first character and the domain', () {
    expect(maskEmail('someone@gmail.com'), 's…@gmail.com');
    expect(maskEmail('not-an-email'), '…');
  });

  test('rows show only Google and GitHub, with masked email and name', () {
    final auth = _FakeAuthService(
      _FakeUser([
        _FakeUserInfo(_googleId, email: 'someone@gmail.com'),
        _FakeUserInfo(_githubId, displayName: 'Ngo Gia Kiet'),
        _FakeUserInfo('password'),
      ]),
    );
    final vm = viewModel(auth);

    expect(vm.rows.map((r) => r.providerId), [_googleId, _githubId]);
    expect(vm.rowFor(_googleId).state, LinkState.linked);
    expect(vm.rowFor(_googleId).label, 's…@gmail.com');
    expect(vm.rowFor(_githubId).label, 'Ngo Gia Kiet');
    vm.dispose();
  });

  group('canUnlink', () {
    test('false for the only provider left', () {
      final vm = viewModel(_FakeAuthService(_googleUser()));
      expect(vm.canUnlink(_googleId), isFalse);
      expect(vm.rowFor(_googleId).canUnlink, isFalse);
      vm.dispose();
    });

    test('true when two providers are linked', () {
      final vm = viewModel(
        _FakeAuthService(
          _FakeUser([_FakeUserInfo(_googleId), _FakeUserInfo(_githubId)]),
        ),
      );
      expect(vm.canUnlink(_googleId), isTrue);
      expect(vm.canUnlink(_githubId), isTrue);
      vm.dispose();
    });

    test('counts providers that are not shown, like password', () {
      final vm = viewModel(
        _FakeAuthService(
          _FakeUser([_FakeUserInfo(_googleId), _FakeUserInfo('password')]),
        ),
      );
      expect(vm.canUnlink(_googleId), isTrue);
      vm.dispose();
    });

    test('false for a guest', () {
      final vm = viewModel(_FakeAuthService(_FakeUser([])));
      expect(vm.canUnlink(_googleId), isFalse);
      expect(vm.rowFor(_googleId).state, LinkState.notLinked);
      vm.dispose();
    });
  });

  test(
    'linking Google turns the row linked and shows a success message',
    () async {
      final auth = _FakeAuthService(_FakeUser([_FakeUserInfo(_githubId)]))
        ..afterLink = () => _FakeUser([
          _FakeUserInfo(_githubId),
          _FakeUserInfo(_googleId, email: 'someone@gmail.com'),
        ]);
      final vm = viewModel(auth);
      final states = <LinkState>[];
      vm.addListener(() => states.add(vm.rowFor(_googleId).state));

      expect(await vm.linkGoogle(), isTrue);
      expect(states.first, LinkState.busy);
      expect(vm.rowFor(_googleId).state, LinkState.linked);
      expect(vm.successMessage, 'Đã liên kết Google.');
      expect(vm.errorMessage, isNull);
      expect(vm.isBusy, isFalse);
      vm.dispose();
    },
  );

  test(
    'a guest linking Google updates the user document to not anonymous',
    () async {
      final auth = _FakeAuthService(_FakeUser([]))
        ..afterLink = () => _FakeUser([
          _FakeUserInfo(
            _googleId,
            email: 'someone@gmail.com',
            displayName: 'An',
          ),
        ]);
      final vm = viewModel(auth);

      await vm.linkGoogle();

      expect(userService.calls, hasLength(1));
      expect(userService.calls.single.uid, 'uid-1');
      expect(userService.calls.single.isAnonymous, isFalse);
      // Empty top-level name is filled from the Google profile
      expect(userService.calls.single.displayName, 'An');
      vm.dispose();
    },
  );

  test(
    'credential-already-in-use shows its message and is not recorded',
    () async {
      final auth = _FakeAuthService(_FakeUser([_FakeUserInfo(_githubId)]))
        ..error = mapFirebaseError(
          FirebaseAuthException(code: 'credential-already-in-use'),
        );
      final vm = viewModel(auth);

      expect(await vm.linkGoogle(), isFalse);
      expect(
        vm.errorMessage,
        'Tài khoản này đã có dữ liệu Why I Buy riêng nên không liên kết được. '
        'Đăng nhập bằng tài khoản đó, xoá dữ liệu hoặc tài khoản, rồi thử lại.',
      );
      expect(vm.rowFor(_googleId).state, LinkState.notLinked);
      expect(crashlytics.handledErrors, 0);
      expect(userService.calls, isEmpty);
      vm.dispose();
    },
  );

  test('cancelling is not an error', () async {
    final auth = _FakeAuthService(_FakeUser([_FakeUserInfo(_githubId)]))
      ..cancelLink = true;
    final vm = viewModel(auth);

    expect(await vm.linkGoogle(), isFalse);
    expect(vm.errorMessage, isNull);
    expect(vm.successMessage, isNull);

    auth
      ..cancelLink = false
      ..error = signInCancelled;
    expect(await vm.linkGithub(), isFalse);
    expect(vm.errorMessage, isNull);
    expect(crashlytics.handledErrors, 0);
    vm.dispose();
  });

  test('errors with a cause are recorded with auth_method', () async {
    final auth = _FakeAuthService(_FakeUser([_FakeUserInfo(_googleId)]))
      ..error = mapFirebaseError(FirebaseAuthException(code: 'internal-error'));
    final vm = viewModel(auth);

    await vm.linkGithub();

    expect(vm.errorMessage, isNotNull);
    expect(crashlytics.handledErrors, 1);
    expect(crashlytics.lastKeys, {
      'auth_method': 'link_github',
      'error_code': 'internal-error',
    });
    vm.dispose();
  });

  test('unlink calls the service and shows a success message', () async {
    final auth = _FakeAuthService(
      _FakeUser([_FakeUserInfo(_googleId), _FakeUserInfo(_githubId)]),
    );
    final vm = viewModel(auth);

    expect(await vm.unlink(_githubId), isTrue);
    expect(auth.unlinked, [_githubId]);
    expect(vm.successMessage, 'Đã huỷ liên kết GitHub.');
    expect(userService.calls, isEmpty);
    vm.dispose();
  });

  test('unlinking the last provider shows the service message', () async {
    final auth = _FakeAuthService(_googleUser())
      ..error = AuthService.lastProvider;
    final vm = viewModel(auth);

    expect(await vm.unlink(_googleId), isFalse);
    expect(vm.errorMessage, 'Phải giữ ít nhất một cách đăng nhập.');
    expect(crashlytics.handledErrors, 0);
    vm.dispose();
  });

  test('a second action while busy is ignored', () async {
    final auth = _FakeAuthService(_FakeUser([_FakeUserInfo(_githubId)]))
      ..afterLink = () =>
          _FakeUser([_FakeUserInfo(_githubId), _FakeUserInfo(_googleId)]);
    final vm = viewModel(auth);

    final first = vm.linkGoogle();
    expect(await vm.linkGithub(), isFalse);
    expect(await first, isTrue);
    vm.dispose();
  });
}
