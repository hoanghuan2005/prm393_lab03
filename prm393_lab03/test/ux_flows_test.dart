import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/add_item_screen.dart';
import 'package:prm393_lab03/screens/email_verification_screen.dart';
import 'package:prm393_lab03/screens/feedback_screen.dart';
import 'package:prm393_lab03/screens/history_screen.dart';
import 'package:prm393_lab03/screens/item_detail_screen.dart';
import 'package:prm393_lab03/screens/login_screen.dart';
import 'package:prm393_lab03/screens/pre_purchase_screen.dart';
import 'package:prm393_lab03/screens/record_purchase_screen.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/settings_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/wishlist_viewmodel.dart';
import 'package:prm393_lab03/widgets/app_text_field.dart';
import 'package:prm393_lab03/widgets/wishlist_card.dart';
import 'package:provider/provider.dart';

import 'support/purchase_harness.dart';
import 'support/test_theme.dart';

class _Auth extends SignedInAuthViewModel {
  bool signedIn = false;
  @override
  AuthStatus get status =>
      signedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  @override
  bool get requiresEmailVerification => true;
  @override
  String? get errorMessage => null;
  @override
  Null get user => null;
  @override
  Future<bool> signInAnonymously() async {
    signedIn = true;
    notifyListeners();
    return true;
  }
}

class _ChangingAuth extends SignedInAuthViewModel {
  AuthStatus currentStatus = AuthStatus.unauthenticated;

  @override
  AuthStatus get status => currentStatus;
  @override
  String? get errorMessage => null;

  void change(AuthStatus status) {
    currentStatus = status;
    notifyListeners();
  }
}

class _FeedbackSettings extends ChangeNotifier implements SettingsViewModel {
  @override
  bool get isSendingFeedback => false;

  @override
  Future<String?> sendFeedback(String message) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetryWishlist extends WishlistViewModel {
  bool failNext = true;
  _RetryWishlist(PurchaseHarness h)
    : super(
        wishlistService: FirestoreWishlistService(h.db),
        analyticsService: h.analytics,
      );
  @override
  Future<bool> skip(WishlistItem item) async {
    if (failNext) {
      failNext = false;
      return false;
    }
    return super.skip(item);
  }

  @override
  Future<bool> deleteItem(WishlistItem item) async {
    if (failNext) {
      failNext = false;
      return false;
    }
    return super.deleteItem(item);
  }
}

class _SavingWishlist extends _RetryWishlist {
  final gate = Completer<void>();
  int adds = 0;
  _SavingWishlist(super.h);
  @override
  Future<bool> addItem({
    required String title,
    required int? price,
    required BuyingMotive motive,
    String? productUrl,
    String? budgetGroupId,
    int priority = WishlistItem.defaultPriority,
    String? imageUrl,
    String? shopName,
    SaveChannel saveChannel = SaveChannel.manual,
  }) async {
    adds++;
    await gate.future;
    return false;
  }
}

Widget _launcher(String route) => Scaffold(
  body: Builder(
    builder: (context) => TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: const Text('Mở'),
    ),
  ),
);

void main() {
  testWidgets(
    'root login keeps typed input while auth enters loading then fails',
    (tester) async {
      final auth = _ChangingAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: auth,
          child: MaterialApp(theme: testAppTheme, home: const AuthGate()),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'a@example.com');
      auth.change(AuthStatus.loading);
      await tester.pump();
      auth.change(AuthStatus.error);
      await tester.pump();
      expect(find.text('a@example.com'), findsOneWidget);
    },
  );

  testWidgets('pre-purchase back asks before dropping typed answers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PrePurchaseScreen(),
                ),
              ),
              child: const Text('Mở câu hỏi'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở câu hỏi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tai nghe');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ câu trả lời?'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(find.text('Tai nghe'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ câu trả lời').last);
    await tester.pumpAndSettle();
    expect(find.text('Mở câu hỏi'), findsOneWidget);
  });

  testWidgets('feedback keeps the draft on cancel and exits after send', (
    tester,
  ) async {
    final settings = _FeedbackSettings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsViewModel>.value(
        value: settings,
        child: MaterialApp(
          theme: testAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FeedbackScreen(),
                  ),
                ),
                child: const Text('Mở góp ý'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở góp ý'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('feedback-field')),
      'Góp ý thử',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ góp ý?'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(find.text('Góp ý thử'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('send-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('Mở góp ý'), findsOneWidget);
  });

  testWidgets('editing does not offer a shop change that cannot be persisted', (
    tester,
  ) async {
    final h = PurchaseHarness();
    addTearDown(h.dispose);
    await h.initialize();
    await tester.pumpWidget(h.app(AddItemScreen(existing: sampleWishlist())));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is AppTextField &&
            widget.label == 'Tên cửa hàng / Shop (Tùy chọn)',
      ),
      matching: find.byType(TextFormField),
    );
    final input = find.descendant(of: field, matching: find.byType(TextField));
    expect(tester.widget<TextField>(input).readOnly, isTrue);
    await tester.ensureVisible(
      find.text('Tên cửa hàng hiện chỉ có thể nhập khi thêm món.'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('adding cannot exit or submit again while saving', (
    tester,
  ) async {
    final h = PurchaseHarness();
    addTearDown(h.dispose);
    final vm = _SavingWishlist(h);
    addTearDown(vm.dispose);
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<WishlistViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: testAppTheme,
          home: _launcher(AppRoutes.wishlistAdd),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) =>
              ChangeNotifierProvider.value(value: h.budget, child: child!),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tai nghe');
    await tester.ensureVisible(find.text('Mong muốn'));
    await tester.tap(find.text('Mong muốn'));
    await tester.ensureVisible(find.text('Lưu vào danh sách'));
    await tester.tap(find.text('Lưu vào danh sách'));
    await tester.pump();
    expect(vm.adds, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(find.text('Bỏ thay đổi?'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Quay lại',
            ),
          )
          .onPressed,
      isNull,
    );
    vm.gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(vm.adds, 1);
  });

  for (final route in [AppRoutes.signup, AppRoutes.forgotPassword]) {
    testWidgets('$route dirty input is kept on cancelled back', (tester) async {
      final auth = _Auth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: auth,
          child: MaterialApp(
            theme: testAppTheme,
            home: _launcher(route),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Thông tin đang nhập',
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(find.text('Thông tin đang nhập'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Mở'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cooldown card displays a fixed date instead of time remaining', (
    tester,
  ) async {
    final item = sampleWishlist().copyWith(
      cooldownUntil: DateTime.now().add(const Duration(days: 2)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: testAppTheme,
        home: Scaffold(
          body: WishlistCard(item: item, onTap: () {}),
        ),
      ),
    );
    expect(find.textContaining('Mốc '), findsOneWidget);
    expect(find.textContaining('Còn '), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final deleting in [false, true]) {
    testWidgets(
      '${deleting ? 'delete' : 'skip'} retry finishes navigation and skip still offers undo',
      (tester) async {
        final h = PurchaseHarness();
        addTearDown(h.dispose);
        await h.initialize(item: sampleWishlist());
        final vm = _RetryWishlist(h)..updateUid(PurchaseHarness.uid);
        addTearDown(vm.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<WishlistViewModel>.value(
            value: vm,
            child: MaterialApp(
              theme: testAppTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ItemDetailScreen(item: sampleWishlist()),
                      ),
                    ),
                    child: const Text('Mở'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở'));
        await tester.pumpAndSettle();
        if (deleting) {
          await tester.tap(find.byTooltip('Xoá món'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xoá').last);
        } else {
          await tester.ensureVisible(find.text('Bỏ qua'));
          await tester.tap(find.text('Bỏ qua'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ItemDetailScreen), findsOneWidget);
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.byType(ItemDetailScreen), findsNothing);
        if (deleting) {
          expect(vm.allItems, isEmpty);
        } else {
          expect(find.text('Hoàn tác'), findsOneWidget);
          await tester.tap(find.text('Hoàn tác'));
          await tester.pumpAndSettle();
          expect(vm.allItems.single.status, WishlistStatus.considering);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'history empty action opens recording and filtered empty action clears filters',
    (tester) async {
      final h = PurchaseHarness();
      addTearDown(h.dispose);
      await h.initialize();
      await tester.pumpWidget(h.app(const HistoryScreen()));
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('history-empty-action'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(RecordPurchaseScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      h.purchases.setFromWishlistOnly(true);
      await tester.pumpAndSettle();
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(h.purchases.hasActiveFilter, isFalse);
    },
  );

  for (final route in [AppRoutes.wishlistAdd, AppRoutes.recordPurchase]) {
    testWidgets('$route unchanged prefilled form leaves without confirmation', (
      tester,
    ) async {
      final h = PurchaseHarness();
      addTearDown(h.dispose);
      await h.initialize();
      await tester.pumpWidget(
        h.app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  route,
                  arguments: route == AppRoutes.wishlistAdd
                      ? const AddItemArgs(initialTitle: 'Tên được điền sẵn')
                      : const RecordPurchaseArgs(
                          initialTitle: 'Tên được điền sẵn',
                        ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Mở'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('named login leaves the form through AuthGate on success', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(
          theme: testAppTheme,
          home: _launcher(AppRoutes.login),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    final guest = find.text('Dùng thử chế độ Khách');
    await tester.ensureVisible(guest);
    await tester.tap(guest);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(EmailVerificationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final route in [AppRoutes.wishlistAdd, AppRoutes.recordPurchase]) {
    testWidgets(
      '$route dirty form asks before Android back and keeps input on cancel',
      (tester) async {
        final h = PurchaseHarness();
        addTearDown(h.dispose);
        await h.initialize();
        await tester.pumpWidget(h.app(_launcher(route)));
        await tester.tap(find.text('Mở'));
        await tester.pumpAndSettle();
        final field = route == AppRoutes.recordPurchase
            ? find.byKey(const ValueKey('purchase-title'))
            : find.byType(TextFormField).first;
        await tester.enterText(field, 'Nội dung đang nhập');
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi?'), findsOneWidget);
        await tester.tap(find.text('Huỷ'));
        await tester.pumpAndSettle();
        expect(find.text('Nội dung đang nhập'), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();
        expect(find.byType(AddItemScreen), findsNothing);
        expect(find.byType(RecordPurchaseScreen), findsNothing);
        expect(h.purchases.allPurchases, isEmpty);
        expect(h.wishlist.allItems, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
