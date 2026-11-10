import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/core/formatters/email_format.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';

import 'support/linked_auth_fakes.dart';

const _googleId = LinkedAccountsViewModel.googleId;
const _githubId = LinkedAccountsViewModel.githubId;

FakeLinkUser _googleUser() => FakeLinkUser([
  FakeUserInfo(_googleId, email: 'someone@gmail.com', displayName: 'An'),
], email: 'someone@gmail.com');

void main() {
  late RecordingUserService userService;
  late CountingCrashlytics crashlytics;

  setUp(() {
    userService = RecordingUserService();
    crashlytics = CountingCrashlytics();
  });

  LinkedAccountsViewModel viewModel(FakeLinkAuthService auth) =>
      LinkedAccountsViewModel(
        authService: auth,
        userService: userService,
        crashlyticsService: crashlytics,
      )..updateUid('uid-1');

  test('maskEmail keeps only the first character and the domain', () {
    expect(maskEmail('someone@gmail.com'), 's…@gmail.com');
    expect(maskEmail('not-an-email'), '…');
  });

  test('rows show Google, Facebook and GitHub, with masked email and name', () {
    final auth = FakeLinkAuthService(
      FakeLinkUser([
        FakeUserInfo(_googleId, email: 'someone@gmail.com'),
        FakeUserInfo(_githubId, displayName: 'Ngo Gia Kiet'),
        FakeUserInfo('password'),
      ]),
    );
    final vm = viewModel(auth);

    expect(vm.rows.map((r) => r.providerId), [
      _googleId,
      LinkedAccountsViewModel.facebookId,
      _githubId,
    ]);
    expect(vm.rowFor(_googleId).state, LinkState.linked);
    expect(vm.rowFor(_googleId).label, 's…@gmail.com');
    expect(vm.rowFor(_githubId).label, 'Ngo Gia Kiet');
    vm.dispose();
  });

  group('canUnlink', () {
    test('false for the only provider left', () {
      final vm = viewModel(FakeLinkAuthService(_googleUser()));
      expect(vm.canUnlink(_googleId), isFalse);
      expect(vm.rowFor(_googleId).canUnlink, isFalse);
      vm.dispose();
    });

    test('true when two providers are linked', () {
      final vm = viewModel(
        FakeLinkAuthService(
          FakeLinkUser([FakeUserInfo(_googleId), FakeUserInfo(_githubId)]),
        ),
      );
      expect(vm.canUnlink(_googleId), isTrue);
      expect(vm.canUnlink(_githubId), isTrue);
      vm.dispose();
    });

    test('counts providers that are not shown, like password', () {
      final vm = viewModel(
        FakeLinkAuthService(
          FakeLinkUser([FakeUserInfo(_googleId), FakeUserInfo('password')]),
        ),
      );
      expect(vm.canUnlink(_googleId), isTrue);
      vm.dispose();
    });

    test('false for a guest', () {
      final vm = viewModel(FakeLinkAuthService(FakeLinkUser([])));
      expect(vm.canUnlink(_googleId), isFalse);
      expect(vm.rowFor(_googleId).state, LinkState.notLinked);
      vm.dispose();
    });
  });

  test(
    'linking Google turns the row linked and shows a success message',
    () async {
      final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
        ..afterLink = () => FakeLinkUser([
          FakeUserInfo(_githubId),
          FakeUserInfo(_googleId, email: 'someone@gmail.com'),
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
      final auth = FakeLinkAuthService(FakeLinkUser([]))
        ..afterLink = () => FakeLinkUser([
          FakeUserInfo(
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
      final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
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
    final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
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
    final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_googleId)]))
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
    final auth = FakeLinkAuthService(
      FakeLinkUser([FakeUserInfo(_googleId), FakeUserInfo(_githubId)]),
    );
    final vm = viewModel(auth);

    expect(await vm.unlink(_githubId), isTrue);
    expect(auth.unlinked, [_githubId]);
    expect(vm.successMessage, 'Đã huỷ liên kết GitHub.');
    expect(userService.calls, isEmpty);
    vm.dispose();
  });

  test('unlinking the last provider shows the service message', () async {
    final auth = FakeLinkAuthService(_googleUser())
      ..error = AuthService.lastProvider;
    final vm = viewModel(auth);

    expect(await vm.unlink(_googleId), isFalse);
    expect(vm.errorMessage, 'Phải giữ ít nhất một cách đăng nhập.');
    expect(crashlytics.handledErrors, 0);
    vm.dispose();
  });

  test('a second action while busy is ignored', () async {
    final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
      ..afterLink = () =>
          FakeLinkUser([FakeUserInfo(_githubId), FakeUserInfo(_googleId)]);
    final vm = viewModel(auth);

    final first = vm.linkGoogle();
    expect(await vm.linkGithub(), isFalse);
    expect(await first, isTrue);
    vm.dispose();
  });
}
