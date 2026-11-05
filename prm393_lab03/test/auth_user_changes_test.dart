import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';

import 'support/linked_auth_fakes.dart';

class _User extends Fake implements User {
  @override
  final String uid;
  @override
  final bool isAnonymous;
  @override
  final String? displayName;
  @override
  final String? email;

  _User({
    this.uid = 'uid-1',
    required this.isAnonymous,
    this.displayName,
    this.email,
  });
}

/// FirebaseAuth driven by the test through [emit]
class _StreamFirebaseAuth extends Fake implements FirebaseAuth {
  final _changes = StreamController<User?>.broadcast();

  @override
  User? currentUser;

  void emit(User? user) {
    currentUser = user;
    _changes.add(user);
  }

  @override
  Stream<User?> userChanges() => _changes.stream;
}

class _NoopBudgetService extends Fake implements BudgetService {
  @override
  Future<void> ensureDefaultGroups(String uid) async {}
}

class _CountingAnalytics extends Fake implements AppAnalyticsService {
  final List<String?> userIds = [];

  @override
  Future<void> setUserId(String? userId) async => userIds.add(userId);
}

class _CountingCrashlytics extends Fake implements CrashlyticsService {
  final List<String> userIds = [];

  @override
  Future<void> setUserId(String userId) async => userIds.add(userId);
}

void main() {
  late _StreamFirebaseAuth auth;
  late RecordingUserService userService;
  late _CountingAnalytics analytics;
  late _CountingCrashlytics crashlytics;
  late AuthViewModel vm;

  setUp(() {
    auth = _StreamFirebaseAuth();
    userService = RecordingUserService();
    analytics = _CountingAnalytics();
    crashlytics = _CountingCrashlytics();
    vm = AuthViewModel(
      authService: AuthService(auth: auth),
      userService: userService,
      budgetService: _NoopBudgetService(),
      analyticsService: analytics,
      crashlyticsService: crashlytics,
    );
  });

  tearDown(() => vm.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a guest who links Google is updated at once, without signing in '
      'again', () async {
    auth.emit(_User(isAnonymous: true));
    await settle();
    expect(vm.status, AuthStatus.authenticated);
    expect(vm.user!.isAnonymous, isTrue);
    expect(vm.displayName, 'Người dùng');
    final uidBefore = vm.userId;

    auth.emit(
      _User(isAnonymous: false, displayName: 'An', email: 'an@gmail.com'),
    );
    await settle();

    expect(vm.user!.isAnonymous, isFalse);
    expect(vm.displayName, 'An');
    expect(vm.user!.email, 'an@gmail.com');
    expect(vm.status, AuthStatus.authenticated);
    // Same uid for the ProxyProviders, so their updateUid is a no-op
    expect(vm.userId, uidBefore);
    // Sign-in work ran once only
    expect(userService.calls, hasLength(1));
    expect(analytics.userIds, ['uid-1']);
    expect(crashlytics.userIds, ['uid-1']);
  });

  test('repeated emissions for the same user (token refresh) do nothing '
      'more', () async {
    auth.emit(_User(isAnonymous: false, displayName: 'An'));
    await settle();
    auth.emit(_User(isAnonymous: false, displayName: 'An'));
    auth.emit(_User(isAnonymous: false, displayName: 'An'));
    await settle();

    expect(vm.status, AuthStatus.authenticated);
    expect(userService.calls, hasLength(1));
    expect(analytics.userIds, ['uid-1']);
  });

  test('sign-out and another account still go through the full flow', () async {
    auth.emit(_User(isAnonymous: false));
    await settle();

    auth.emit(null);
    await settle();
    expect(vm.status, AuthStatus.unauthenticated);
    expect(vm.userId, isNull);

    auth.emit(_User(uid: 'uid-2', isAnonymous: false));
    await settle();
    expect(vm.status, AuthStatus.authenticated);
    expect(vm.userId, 'uid-2');
    expect(userService.calls.map((c) => c.uid), ['uid-1', 'uid-2']);
    expect(analytics.userIds, ['uid-1', null, 'uid-2']);
  });
}
