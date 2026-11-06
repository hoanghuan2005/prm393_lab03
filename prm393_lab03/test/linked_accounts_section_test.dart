import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/screens/profile_screen.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';
import 'package:provider/provider.dart';

import 'support/linked_auth_fakes.dart';

const _googleId = LinkedAccountsViewModel.googleId;
const _githubId = LinkedAccountsViewModel.githubId;
final _lastNote = AuthService.lastProvider.messageVi;
const _guestNote =
    'Liên kết Google hoặc GitHub để giữ dữ liệu khi đổi máy hoặc đăng xuất.';

Future<LinkedAccountsViewModel> _pump(
  WidgetTester tester,
  FakeLinkAuthService auth, {
  bool isAvailable = true,
}) async {
  final vm = LinkedAccountsViewModel(
    authService: auth,
    userService: RecordingUserService(),
    crashlyticsService: CountingCrashlytics(),
    isAvailable: isAvailable,
  )..updateUid('uid-1');
  addTearDown(vm.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: LinkedAccountsSection()),
        ),
      ),
    ),
  );
  await tester.pump();
  return vm;
}

/// The TextButton with [label] in the row titled [provider]
Finder _button(String provider, String label) => find.descendant(
  of: find.widgetWithText(ListTile, provider),
  matching: find.widgetWithText(TextButton, label),
);

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<TextButton>(button).onPressed != null;

void main() {
  testWidgets('nothing linked: both rows offer "Liên kết"', (tester) async {
    await _pump(
      tester,
      FakeLinkAuthService(FakeLinkUser([FakeUserInfo('password')])),
    );

    expect(find.text('Tài khoản liên kết'), findsOneWidget);
    expect(_enabled(tester, _button('Google', 'Liên kết')), isTrue);
    expect(_enabled(tester, _button('GitHub', 'Liên kết')), isTrue);
    expect(find.text('Huỷ liên kết'), findsNothing);
    expect(find.text(_guestNote), findsNothing);
  });

  testWidgets('the only sign-in method cannot be unlinked', (tester) async {
    await _pump(
      tester,
      FakeLinkAuthService(
        FakeLinkUser([FakeUserInfo(_googleId, email: 'someone@gmail.com')]),
      ),
    );

    expect(find.text('Đã liên kết · s…@gmail.com'), findsOneWidget);
    expect(find.textContaining('someone@'), findsNothing);
    expect(_enabled(tester, _button('Google', 'Huỷ liên kết')), isFalse);
    expect(find.text(_lastNote), findsOneWidget);
    expect(_enabled(tester, _button('GitHub', 'Liên kết')), isTrue);
  });

  testWidgets('with two methods both can be unlinked', (tester) async {
    await _pump(
      tester,
      FakeLinkAuthService(
        FakeLinkUser([
          FakeUserInfo(_googleId, email: 'someone@gmail.com'),
          FakeUserInfo(_githubId, displayName: 'Ngo Gia Kiet'),
        ]),
      ),
    );

    expect(find.text('Đã liên kết · Ngo Gia Kiet'), findsOneWidget);
    expect(_enabled(tester, _button('Google', 'Huỷ liên kết')), isTrue);
    expect(_enabled(tester, _button('GitHub', 'Huỷ liên kết')), isTrue);
    expect(find.text(_lastNote), findsNothing);
  });

  testWidgets('a guest sees the note and no unlink button', (tester) async {
    await _pump(tester, FakeLinkAuthService(FakeLinkUser([])));

    expect(find.text(_guestNote), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Liên kết'), findsNWidgets(2));
    expect(find.text('Huỷ liên kết'), findsNothing);
    expect(find.text(_lastNote), findsNothing);
  });

  testWidgets('hidden where linking is unsupported', (tester) async {
    await _pump(
      tester,
      FakeLinkAuthService(FakeLinkUser([])),
      isAvailable: false,
    );

    expect(find.text('Tài khoản liên kết'), findsNothing);
    expect(find.text('Liên kết'), findsNothing);
  });

  testWidgets('unlinking Google asks first and mentions the extension', (
    tester,
  ) async {
    final auth = FakeLinkAuthService(
      FakeLinkUser([FakeUserInfo(_googleId), FakeUserInfo(_githubId)]),
    );
    await _pump(tester, auth);

    await tester.tap(_button('Google', 'Huỷ liên kết'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining(LinkedAccountsSection.extensionNote),
      findsOneWidget,
    );

    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(auth.unlinked, isEmpty);
  });

  testWidgets('unlinking GitHub asks without the extension note, then shows '
      'the result', (tester) async {
    final auth = FakeLinkAuthService(
      FakeLinkUser([FakeUserInfo(_googleId), FakeUserInfo(_githubId)]),
    );
    await _pump(tester, auth);

    await tester.tap(_button('GitHub', 'Huỷ liên kết'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining(LinkedAccountsSection.extensionNote),
      findsNothing,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Huỷ liên kết'),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.unlinked, [_githubId]);
    expect(find.text('Đã huỷ liên kết GitHub.'), findsOneWidget);
  });

  testWidgets('while one row is busy it shows a spinner and every button is '
      'locked', (tester) async {
    final gate = Completer<void>();
    final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
      ..gate = gate
      ..afterLink = () => FakeLinkUser([
        FakeUserInfo(_githubId),
        FakeUserInfo(_googleId, email: 'someone@gmail.com'),
      ]);
    await _pump(tester, auth);

    await tester.tap(_button('Google', 'Liên kết'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Google'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(_enabled(tester, _button('GitHub', 'Huỷ liên kết')), isFalse);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Đã liên kết Google.'), findsOneWidget);
    expect(find.text('Đã liên kết · s…@gmail.com'), findsOneWidget);
    expect(_enabled(tester, _button('GitHub', 'Huỷ liên kết')), isTrue);
  });

  testWidgets('an error is shown in a SnackBar', (tester) async {
    final auth = FakeLinkAuthService(FakeLinkUser([FakeUserInfo(_githubId)]))
      // Mapped as AuthService throws it
      ..error = mapFirebaseError(
        FirebaseAuthException(code: 'provider-already-linked'),
      );
    await _pump(tester, auth);

    await tester.tap(_button('Google', 'Liên kết'));
    await tester.pumpAndSettle();

    expect(find.text('Cách đăng nhập này đã được liên kết.'), findsOneWidget);
  });
}
