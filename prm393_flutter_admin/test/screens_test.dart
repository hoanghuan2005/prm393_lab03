import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/app/admin_theme.dart';
import 'package:prm393_flutter_admin/screens/admin_shell.dart';
import 'package:prm393_flutter_admin/screens/sign_in_screen.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/dashboard_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
import 'package:prm393_flutter_admin/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

/// The whole admin area with fake services: every page is laid out at each
/// size, so any overflow or layout error fails the test.
void main() {
  late FakeSaleEventService events;
  late FakeSuggestionService suggestions;
  late FakeAnnouncementService announcements;
  late FakeAuthService auth;

  setUp(() {
    events = FakeSaleEventService();
    suggestions = FakeSuggestionService();
    announcements = FakeAnnouncementService();
    auth = FakeAuthService();
  });

  Widget harness(Widget home) => MultiProvider(
    providers: [
      Provider<AdminAuthService>.value(value: auth),
      Provider<DashboardService>.value(value: FakeDashboardService()),
      Provider<SaleEventService>.value(value: events),
      Provider<SaleSuggestionService>.value(value: suggestions),
      Provider<AnnouncementService>.value(value: announcements),
      Provider<PushService>.value(value: FakePushService(isConfigured: true)),
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(auth, FakeRoleService({})),
      ),
    ],
    child: MaterialApp(theme: buildAdminTheme(), home: home),
  );

  Future<void> feed(WidgetTester tester) async {
    events.controller.add([
      SaleEvent(
        id: 'a',
        name:
            'Siêu sale 11.11 — đợt lớn nhất năm của các sàn thương mại điện tử',
        date: DateTime(2026, 11, 11),
        type: SaleType.doubleDay,
        confirmed: true,
        source: SaleEventSource.suggestion,
      ),
      SaleEvent(
        id: 'b',
        name: 'Sale cũ',
        date: DateTime(2026, 6, 6),
        type: SaleType.other,
        confirmed: false,
        status: SaleEventStatus.archived,
      ),
    ]);
    suggestions.controllers[SuggestionStatus.pending]!.add([
      SaleSuggestion(
        id: 's1',
        uid: 'kxhqokl1Wf2XVbfqnNd5mQ8AIHXn',
        name: 'Siêu sale 12.12',
        date: DateTime(2026, 12, 12),
        note: 'Shopee đã đăng banner trên trang chủ',
        createdAt: DateTime(2026, 11, 5, 14, 30),
      ),
    ]);
    announcements.controller.add([
      Announcement(
        id: 'n1',
        title: 'Lịch sale tháng 12 đã cập nhật',
        body:
            'Xem mục Lịch sale để biết những ngày nên chờ trước khi mua. ' * 4,
        createdAt: DateTime(2026, 11, 5, 9),
      ),
    ]);
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(1366, 820), Size(800, 1000), Size(400, 860)]) {
    testWidgets('every admin page lays out at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness(
          const AdminShell(
            account: AdminAccount(uid: 'admin-1', email: 'a@x.com'),
          ),
        ),
      );
      await feed(tester);

      expect(find.text('Tổng quan'), findsWidgets);
      expect(find.text('Tổng người dùng'), findsOneWidget);

      // Each page, checked while it is the visible one
      for (final (page, content) in [
        ('Sự kiện sale', 'Thêm sự kiện'),
        ('Thông báo', 'Lịch sale tháng 12 đã cập nhật'),
        ('Duyệt đề xuất', 'Siêu sale 12.12'),
      ]) {
        await tester.tap(find.text(page).first);
        await tester.pumpAndSettle();
        // On narrow screens the content can sit below the fold
        await tester.scrollUntilVisible(
          find.text(content),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(content), findsOneWidget, reason: page);
      }

      // The reject dialog fits too
      await tester.tap(find.text('Từ chối').first);
      await tester.pumpAndSettle();
      expect(find.text('Từ chối đề xuất'), findsOneWidget);
      await tester.tap(find.text('Chưa có thông báo chính thức từ shop'));
      await tester.pump();
      await tester.tap(find.text('Từ chối').last);
      await tester.pumpAndSettle();
      expect(suggestions.rejected.single, (
        's1',
        'Chưa có thông báo chính thức từ shop',
      ));
    });
  }

  testWidgets('sign-in screen shows why an account was refused', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const SignInScreen()));
    auth.emit(null);
    await tester.pumpAndSettle();
    auth.failNextSignIn = const SignInException(SignInFailure.popupBlocked);
    await tester.tap(find.text('Đăng nhập với Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chặn cửa sổ đăng nhập'), findsOneWidget);
  });
}
