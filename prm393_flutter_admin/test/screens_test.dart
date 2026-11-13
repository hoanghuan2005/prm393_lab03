import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/app/admin_theme.dart';
import 'package:prm393_flutter_admin/models/shopee_voucher.dart';
import 'package:prm393_flutter_admin/models/user_summary.dart';
import 'package:prm393_flutter_admin/screens/admin_shell.dart';
import 'package:prm393_flutter_admin/screens/sign_in_screen.dart';
import 'package:prm393_flutter_admin/services/admin_ai_service.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/dashboard_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
import 'package:prm393_flutter_admin/services/shopee_voucher_service.dart';
import 'package:prm393_flutter_admin/services/user_directory_service.dart';
import 'package:prm393_flutter_admin/viewmodels/auth_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/shell_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

/// The whole admin area with fake services: every page is laid out at each
/// size, in light and dark mode, so any overflow or layout error fails the test.
void main() {
  late FakeSaleEventService events;
  late FakeSuggestionService suggestions;
  late FakeAnnouncementService announcements;
  late FakeUserDirectory directory;
  late FakeShopeeVoucherService vouchers;
  late FakeVoucherRecordService codes;
  late FakeCrashReportService crashes;
  late FakeAuthService auth;
  late ShellViewModel shell;

  setUp(() {
    events = FakeSaleEventService();
    suggestions = FakeSuggestionService();
    announcements = FakeAnnouncementService();
    directory = FakeUserDirectory()
      ..activity['u1'] = const UserActivity(wishlistItems: 3, purchases: 1);
    vouchers = FakeShopeeVoucherService();
    codes = FakeVoucherRecordService();
    crashes = FakeCrashReportService();
    auth = FakeAuthService();
    shell = ShellViewModel();
  });

  Widget harness(Widget home) => MultiProvider(
    providers: [
      Provider<AdminAuthService>.value(value: auth),
      Provider<RoleService>.value(value: FakeRoleService({})),
      Provider<DashboardService>.value(value: FakeDashboardService()),
      Provider<UserDirectoryService>.value(value: directory),
      Provider<InboxService>.value(value: FakeInboxService()),
      Provider<SaleEventService>.value(value: events),
      Provider<SaleSuggestionService>.value(value: suggestions),
      Provider<AnnouncementService>.value(value: announcements),
      Provider<AdminAiService>.value(
        value: AdminAiService(generator: (m, p) async => throw Exception('x')),
      ),
      Provider<PushService>.value(value: FakePushService(isConfigured: true)),
      Provider<ShopeeVoucherService>.value(value: vouchers),
      Provider<VoucherRecordService>.value(value: codes),
      Provider<CrashReportService>.value(value: crashes),
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(auth, FakeRoleService({})),
      ),
      ChangeNotifierProvider.value(value: shell),
    ],
    child: Consumer<ShellViewModel>(
      builder: (_, s, _) => MaterialApp(
        theme: buildAdminTheme(Brightness.light),
        darkTheme: buildAdminTheme(Brightness.dark),
        themeMode: s.themeMode,
        home: home,
      ),
    ),
  );

  Future<void> feed(WidgetTester tester) async {
    events.controller.add([
      SaleEvent(
        id: 'a',
        name: 'Siêu sale 11.11 của các sàn',
        date: DateTime(2026, 11, 11),
        type: SaleType.doubleDay,
        confirmed: true,
        suggestionId: 's0',
      ),
      SaleEvent(
        id: 'b',
        name: 'Nháp 12.12',
        date: DateTime(2026, 12, 12),
        type: SaleType.doubleDay,
        confirmed: false,
        status: SaleEventStatus.draft,
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
            'Xem mục Lịch sale để biết những ngày nên chờ trước khi mua. ' * 3,
        createdAt: DateTime(2026, 11, 5, 9),
      ),
    ]);
    directory.controller.add([
      UserSummary(
        uid: 'admin-1',
        displayName: 'Admin Thử',
        email: 'admin.thu@example.com',
        role: AppRole.admin,
        createdAt: DateTime(2026, 11, 1),
      ),
      UserSummary(
        uid: 'u1',
        displayName: 'Nguyễn Hoàng Huân với một cái tên rất dài để thử tràn',
        email: 'huan.nguyen.hoang.rat.dai@example.com',
        createdAt: DateTime(2026, 11, 5, 9),
      ),
    ]);
    crashes.controller.add([
      CrashReport(
        id: 'k1',
        feature: 'Màn hình Hồ sơ với một cái tên rất dài để thử tràn trên màn hẹp',
        errorCode: 'FATAL_TEST_CRASH',
        errorMessage: 'Crash thử ' * 20,
        stackTrace: '#0 main (package:app/main.dart:1)\n' * 30,
        severity: CrashSeverity.fatal,
        userId: 'uSnhdwvYnrS93fhLcg1goXXoTMI1',
        platform: 'android',
        appVersion: '1.0.0+1',
        createdAt: DateTime(2026, 11, 13, 8, 30),
      ),
    ]);
    codes.controller.add([
      VoucherRecord(
        id: 'c1',
        isActive: true,
        draft: VoucherDraft(
          code: 'SHOPEE50KDAIDETHUTRAN',
          title: 'Giảm 50K cho đơn từ 250K, mô tả rất dài để thử tràn trên màn hẹp',
          kind: VoucherKind.discount,
          discountVnd: 50000,
          minOrderVnd: 250000,
          category: VoucherCategory.fashion,
          validUntil: DateTime(2099, 12, 31),
          shopId: '123456',
          shopName: 'Cửa hàng chính hãng với một cái tên rất dài để thử tràn',
        ),
      ),
      VoucherRecord(
        id: 'c2',
        isActive: false,
        isLegacy: true,
        draft: VoucherDraft(
          code: 'FREESHIP',
          title: 'Miễn phí vận chuyển',
          kind: VoucherKind.freeship,
          discountVnd: 15000,
          minOrderVnd: 0,
          category: VoucherCategory.all,
          validUntil: DateTime(2020, 1, 1),
        ),
      ),
    ]);
    vouchers.controller.add([
      ShopeeVoucher(
        id: 'v1',
        raw:
            'Giảm 10% Giảm tối đa ₫50k Đơn Tối Thiểu ₫99k HSD: 30.11.2026 '
            'Đã dùng 80% với một đoạn mô tả rất dài để thử tràn',
        kind: 'percent',
        scope: VoucherScope.shop,
        percent: 10,
        capVnd: 50000,
        minSpendVnd: 99000,
        usedPct: 80,
        expiresText: '30.11.2026',
        shopName: 'Cửa hàng chính hãng với một cái tên rất dài để thử tràn',
        productTitle: 'Tai nghe không dây chống ồn chủ động bản quốc tế',
        sourceUrl: 'https://shopee.vn/product/1/2',
        capturedBy: 'cvuPP4HXuKcJdVNepkxbjWUdqTY2',
        lastSeenAt: DateTime(2026, 11, 7, 10),
      ),
      const ShopeeVoucher(
        id: 'v2',
        raw: 'Miễn phí vận chuyển Đã hết lượt',
        kind: 'shipping',
        scope: VoucherScope.platform,
        unavailable: true,
      ),
    ]);
    await tester.pumpAndSettle();
  }

  const pages = {
    AdminSection.users: 'Nguyễn Hoàng Huân với một cái tên rất dài để thử tràn',
    AdminSection.saleEvents: 'Thêm sự kiện',
    AdminSection.reviews: 'Siêu sale 12.12',
    AdminSection.announcements: 'Lịch sale tháng 12 đã cập nhật',
    AdminSection.codes: 'SHOPEE50KDAIDETHUTRAN',
    AdminSection.vouchers: 'Giảm 10% tối đa 50.000 ₫',
    AdminSection.crashes: 'FATAL_TEST_CRASH',
    AdminSection.assistant: 'Tạo Gợi Ý Thông Minh',
  };

  for (final size in const [Size(1366, 820), Size(800, 1000), Size(400, 860)]) {
    for (final dark in [false, true]) {
      testWidgets('every admin page lays out at ${size.width.toInt()} px, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (dark) shell.toggleTheme();

        await tester.pumpWidget(
          harness(
            const AdminShell(
              account: AdminAccount(uid: 'admin-1', email: 'a@x.com'),
              role: AppRole.admin,
            ),
          ),
        );
        await feed(tester);
        expect(find.textContaining('CÀI APP NHƯNG CHƯA DÙNG'), findsWidgets);

        for (final MapEntry(key: section, value: content) in pages.entries) {
          shell.goTo(section);
          await tester.pumpAndSettle();
          // On narrow screens the content can sit below the fold: jump the
          // page to its end (a drag could land on a multi-line text field)
          if (find.text(content).evaluate().isEmpty) {
            final page = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(ListView).first,
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            page.position.jumpTo(page.position.maxScrollExtent);
            await tester.pumpAndSettle();
          }
          expect(find.text(content), findsWidgets, reason: '$section');
        }

        // The reject dialog fits too
        shell.goTo(AdminSection.reviews);
        await tester.pumpAndSettle();
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
  }

  testWidgets('staff see the dashboard without the admin-only figures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(
        const AdminShell(
          account: AdminAccount(uid: 'staff-1', email: 's@x.com'),
          role: AppRole.staff,
        ),
      ),
    );
    await feed(tester);
    expect(find.textContaining('chỉ admin'), findsWidgets);
    expect(find.textContaining('Tổng chi tiêu'), findsNothing);
  });

  testWidgets('the sidebar switches pages and the theme', (tester) async {
    tester.view.physicalSize = const Size(1366, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(
        const AdminShell(
          account: AdminAccount(uid: 'admin-1', email: 'a@x.com'),
          role: AppRole.admin,
        ),
      ),
    );
    await feed(tester);
    await tester.tap(find.text('Người dùng').first);
    await tester.pumpAndSettle();
    expect(shell.section, AdminSection.users);
    await tester.tap(find.text('Chế độ tối'));
    await tester.pumpAndSettle();
    expect(shell.isDark, isTrue);
  });

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
