import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/screens/push_screen.dart';
import 'package:prm393_flutter_admin/services/admin_service.dart';
import 'package:provider/provider.dart';

class _SuccessfulPushService extends AdminService {
  String? sentAudience;

  @override
  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String targetAudience,
    required String targetScreen,
  }) async {
    sentAudience = targetAudience;
    clearPreselectedUser();
  }
}

Future<void> _showPushScreen(WidgetTester tester, AdminService admin) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider<AdminService>.value(
      value: admin,
      child: const MaterialApp(home: Scaffold(body: PushScreen())),
    ),
  );
}

void _expectRecipientRequired(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  final audience = tester.widget<DropdownButton<String>>(
    find.byType(DropdownButton<String>).first,
  );
  expect(audience.value, isNull);
  expect(find.text('Chọn đối tượng nhận thông báo'), findsOneWidget);
  final sendButton = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Bắn Thông Báo Push Ngay Bây Giờ'),
  );
  expect(sendButton.onPressed, isNull);
}

void main() {
  testWidgets('clearing a specific recipient requires a new selection', (
    tester,
  ) async {
    final admin = AdminService();
    addTearDown(admin.dispose);
    admin.selectUserForPush(admin.users.first);
    await _showPushScreen(tester, admin);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    _expectRecipientRequired(tester);
  });

  testWidgets('sending to a specific recipient keeps the form usable', (
    tester,
  ) async {
    final admin = _SuccessfulPushService();
    addTearDown(admin.dispose);
    admin.selectUserForPush(admin.users.first);
    await _showPushScreen(tester, admin);
    final sendButton = find.widgetWithText(
      ElevatedButton,
      'Bắn Thông Báo Push Ngay Bây Giờ',
    );
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pump();

    expect(admin.sentAudience, 'specific');
    _expectRecipientRequired(tester);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a stale specific draft requires a recipient when opened', (
    tester,
  ) async {
    final admin = AdminService();
    addTearDown(admin.dispose);
    admin.selectUserForPush(admin.users.first);
    admin.clearPreselectedUser();

    await _showPushScreen(tester, admin);

    _expectRecipientRequired(tester);
  });
}
