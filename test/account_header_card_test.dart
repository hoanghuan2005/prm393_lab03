import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/screens/profile_screen.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';
import 'package:provider/provider.dart';

import 'support/linked_auth_fakes.dart';

const _uid = 'abcdef1234567890';

class _User extends Fake implements User {
  @override
  String get uid => _uid;
  @override
  final bool isAnonymous;
  @override
  final String? displayName;
  @override
  final String? email;
  final List<String> providers;

  _User({
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.providers = const [],
  });

  @override
  List<UserInfo> get providerData => [
    for (final id in providers) FakeUserInfo(id, email: email),
  ];
}

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

class _NoopAnalytics extends Fake implements AppAnalyticsService {
  @override
  Future<void> setUserId(String? userId) async {}
}

class _NoopCrashlytics extends Fake implements CrashlyticsService {
  @override
  Future<void> setUserId(String userId) async {}
}

Future<void> _pump(
  WidgetTester tester,
  User user, {
  bool showDebugUid = false,
}) async {
  final auth = _StreamFirebaseAuth();
  final authService = AuthService(auth: auth);
  final vm = AuthViewModel(
    authService: authService,
    userService: RecordingUserService(),
    budgetService: _NoopBudgetService(),
    analyticsService: _NoopAnalytics(),
    crashlyticsService: _NoopCrashlytics(),
  );
  final linkedVm = LinkedAccountsViewModel(
    authService: authService,
    userService: RecordingUserService(),
    isAvailable: true,
  );
  addTearDown(vm.dispose);
  addTearDown(linkedVm.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vm),
        ChangeNotifierProvider.value(value: linkedVm),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: AccountHeaderCard(showDebugUid: showDebugUid)),
      ),
    ),
  );
  await tester.runAsync(() async {
    auth.emit(user);
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
}

void main() {
  testWidgets('a guest is labelled "Khách"', (tester) async {
    await _pump(tester, _User(isAnonymous: true));

    expect(find.text('Khách'), findsOneWidget);
  });

  testWidgets('a GitHub account without email is never called a guest', (
    tester,
  ) async {
    await _pump(tester, _User(isAnonymous: false));

    expect(find.textContaining('Khách'), findsNothing);
    expect(find.textContaining('ẩn danh'), findsNothing);
    expect(find.text('Tài khoản đã liên kết'), findsOneWidget);
  });

  testWidgets('with a name but no email the label lists linked methods', (
    tester,
  ) async {
    await _pump(
      tester,
      _User(
        isAnonymous: false,
        displayName: 'Ngo Gia Kiet',
        providers: ['github.com'],
      ),
    );

    // Name only once (title), not repeated as the label
    expect(find.text('Ngo Gia Kiet'), findsOneWidget);
    expect(find.text('Đã liên kết: GitHub'), findsOneWidget);
    expect(find.textContaining('Khách'), findsNothing);
  });

  testWidgets('both linked methods are listed in row order', (tester) async {
    await _pump(
      tester,
      _User(
        isAnonymous: false,
        displayName: 'Ngo Gia Kiet',
        providers: ['github.com', 'google.com'],
      ),
    );

    expect(find.text('Đã liên kết: Google, GitHub'), findsOneWidget);
  });

  testWidgets('the email is shown masked, never in full', (tester) async {
    await _pump(
      tester,
      _User(isAnonymous: false, displayName: 'An', email: 'someone@gmail.com'),
    );

    expect(find.text('s…@gmail.com'), findsOneWidget);
    expect(find.textContaining('someone'), findsNothing);
  });

  testWidgets('an account named only by its email shows it masked as title', (
    tester,
  ) async {
    await _pump(tester, _User(isAnonymous: false, email: 'someone@gmail.com'));

    expect(find.textContaining('someone'), findsNothing);
    expect(find.text('s…@gmail.com'), findsNWidgets(2));
  });

  testWidgets('release builds show no UID line', (tester) async {
    await _pump(tester, _User(isAnonymous: true));

    expect(find.textContaining('UID'), findsNothing);
    expect(find.textContaining(_uid), findsNothing);
  });

  testWidgets('debug builds show only the first 6 characters of the UID', (
    tester,
  ) async {
    await _pump(tester, _User(isAnonymous: true), showDebugUid: true);

    expect(find.text('UID: abcdef…'), findsOneWidget);
    expect(find.textContaining(_uid), findsNothing);
  });
}
