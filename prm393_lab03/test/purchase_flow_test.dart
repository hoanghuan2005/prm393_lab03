import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/screens/home_screen.dart';
import 'package:prm393_lab03/screens/item_detail_screen.dart';
import 'package:prm393_lab03/screens/purchase_detail_screen.dart';
import 'package:prm393_lab03/screens/record_purchase_screen.dart';
import 'package:prm393_lab03/screens/wishlist_screen.dart';
import 'package:prm393_lab03/widgets/amount_field.dart';

import 'support/purchase_harness.dart';

void main() {
  late PurchaseHarness h;
  setUp(() => h = PurchaseHarness());
  tearDown(() => h.dispose());

  Future<void> size(WidgetTester tester, {double width = 360}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget launcher(String route, Object? arguments) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            Navigator.pushNamed(context, route, arguments: arguments),
        child: const Text('Mở'),
      ),
    ),
  );

  Future<void> openForm(
    WidgetTester tester, {
    RecordPurchaseArgs? args,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      h.app(launcher(AppRoutes.recordPurchase, args), textScale: textScale),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
  }

  Finder amountField() => find.descendant(
    of: find.byType(AmountField),
    matching: find.byType(TextFormField),
  );

  Future<void> selectTech(WidgetTester tester) async {
    final group = find.byKey(const ValueKey('purchase-budget-group'));
    await tester.ensureVisible(group);
    await tester.tap(group);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công nghệ').last);
    await tester.pumpAndSettle();
  }

  for (final icon in [true, false]) {
    testWidgets(
      'Home ${icon ? 'bookmark' : 'wishlist card'} opens Wishlist even inside the tab shell',
      (tester) async {
        await size(tester);
        await h.initialize(item: sampleWishlist());
        final tabChanges = <int>[];
        await tester.pumpWidget(
          h.app(HomeScreen(onNavigateTab: tabChanges.add)),
        );
        await tester.pumpAndSettle();
        final target = icon
            ? find.byTooltip('Danh sách mong muốn')
            : find.text('Danh sách mong muốn');
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.byType(WishlistScreen), findsOneWidget);
        expect(tabChanges, isEmpty);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'manual form validates required fields and saves the selected group',
    (tester) async {
      await size(tester);
      await h.initialize();
      await openForm(tester);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên món'), findsOneWidget);
      expect(h.service.addCalls, 0);
      await tester.enterText(amountField(), '389000');
      await tester.enterText(
        find.byKey(const ValueKey('purchase-title')),
        'Tai nghe',
      );
      await selectTech(tester);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhu cầu'));
      final note = find.byKey(const ValueKey('purchase-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, 'Dùng cho công việc');
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.pumpAndSettle();
      expect(find.byType(PurchaseDetailScreen), findsOneWidget);
      final purchase = h.purchases.allPurchases.single;
      expect(purchase.amountVnd, 389000);
      expect(purchase.budgetGroupId, 'tech');
      expect(purchase.motive, BuyingMotive.need);
      expect(purchase.note, 'Dùng cho công việc');
      expect(h.budget.spentFor('tech'), 389000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Back from wishlist purchase does not change status or create an expense',
    (tester) async {
      await size(tester);
      final item = sampleWishlist();
      await h.initialize(item: item);
      await tester.pumpWidget(
        h.app(launcher(AppRoutes.itemDetail, ItemDetailArgs(item))),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mua'));
      await tester.tap(find.text('Mua'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordPurchaseScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('purchase-title')))
            .controller!
            .text,
        item.title,
      );
      expect(
        tester.widget<TextFormField>(amountField()).controller!.text,
        '420.000',
      );
      await tester.enterText(amountField(), '389000');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bước 1/2: Thông tin khoản mua'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(amountField()).controller!.text,
        '389.000',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(h.service.buyCalls, 0);
      expect(h.purchases.allPurchases, isEmpty);
      expect(
        (await h.db
                .doc('users/${PurchaseHarness.uid}/wishlistItems/${item.id}')
                .get())
            .data()!['status'],
        'considering',
      );
    },
  );

  testWidgets(
    'confirmed buy navigates from wishlist detail to the actual purchase detail',
    (tester) async {
      await size(tester);
      final item = sampleWishlist();
      await h.initialize(item: item);
      await tester.pumpWidget(
        h.app(launcher(AppRoutes.itemDetail, ItemDetailArgs(item))),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mua'));
      await tester.tap(find.text('Mua'));
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '389000');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.pumpAndSettle();
      expect(find.byType(PurchaseDetailScreen), findsOneWidget);
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(find.text('389.000 ₫'), findsOneWidget);
      final source =
          (await h.db
                  .doc('users/${PurchaseHarness.uid}/wishlistItems/${item.id}')
                  .get())
              .data()!;
      expect(source['status'], 'purchased');
      expect(source['purchaseId'], h.purchases.allPurchases.single.id);
      expect(h.budget.spentFor('tech'), 389000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown wishlist price requires actual paid amount before continuing',
    (tester) async {
      await size(tester);
      final item = sampleWishlist(price: null);
      await h.initialize(item: item);
      await openForm(tester, args: RecordPurchaseArgs(wishlistItem: item));
      expect(
        tester.widget<TextFormField>(amountField()).controller!.text,
        isEmpty,
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
      expect(h.service.buyCalls, 0);
    },
  );

  testWidgets(
    'failed wishlist save preserves all input and retries successfully once',
    (tester) async {
      await size(tester);
      final item = sampleWishlist();
      await h.initialize(item: item);
      h.service.rejectWrites = true;
      await openForm(tester, args: RecordPurchaseArgs(wishlistItem: item));
      await tester.enterText(amountField(), '389000');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('purchase-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, 'Ghi chú giữ lại');
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordPurchaseScreen), findsOneWidget);
      expect(find.textContaining('Chưa lưu được.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(note).controller!.text,
        'Ghi chú giữ lại',
      );
      expect(h.purchases.allPurchases, isEmpty);
      expect(
        (await h.db
                .doc('users/${PurchaseHarness.uid}/wishlistItems/${item.id}')
                .get())
            .data()!['status'],
        'considering',
      );
      h.service.rejectWrites = false;
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.pumpAndSettle();
      expect(h.purchases.allPurchases.single.amountVnd, 389000);
      expect(h.purchases.allPurchases.single.note, 'Ghi chú giữ lại');
      expect(h.budget.spentFor('tech'), 389000);
      expect(
        (await h.db.collection('users/${PurchaseHarness.uid}/decisions').get())
            .docs,
        hasLength(1),
      );
      expect(find.byType(RecordPurchaseScreen), findsNothing);
    },
  );

  testWidgets(
    'repeated clicks and Android Back while saving cannot submit twice or abandon an in-flight save',
    (tester) async {
      await size(tester);
      final item = sampleWishlist();
      await h.initialize(item: item);
      await openForm(tester, args: RecordPurchaseArgs(wishlistItem: item));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      final gate = Completer<void>();
      h.service.gate = gate;
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.tap(find.text('Lưu khoản mua'));
      await tester.pump();
      expect(h.service.buyCalls, 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(RecordPurchaseScreen), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(h.purchases.allPurchases, hasLength(1));
    },
  );

  testWidgets(
    'edit failure stays on form; successful retry can clear note and change group',
    (tester) async {
      await size(tester);
      final original = PurchaseItem(
        id: 'edit-me',
        title: 'Tai nghe',
        amountVnd: 420000,
        motive: BuyingMotive.sale,
        occurredAt: DateTime.now(),
        note: 'Ghi chú cũ',
      );
      await h.initialize(purchase: original);
      await openForm(
        tester,
        args: RecordPurchaseArgs(existingPurchase: original),
      );
      await selectTech(tester);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('purchase-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, '');
      h.service.rejectWrites = true;
      await tester.tap(find.text('Cập nhật khoản mua'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordPurchaseScreen), findsOneWidget);
      expect(find.text('Đã cập nhật khoản mua.'), findsNothing);
      h.service.rejectWrites = false;
      await tester.tap(find.text('Cập nhật khoản mua'));
      await tester.pumpAndSettle();
      expect(h.purchases.allPurchases.single.note, isNull);
      expect(h.purchases.allPurchases.single.budgetGroupId, 'tech');
    },
  );

  testWidgets('overlong note is rejected without a write', (tester) async {
    await size(tester);
    await h.initialize();
    await openForm(
      tester,
      args: const RecordPurchaseArgs(
        initialAmount: 100000,
        initialTitle: 'Món',
      ),
    );
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    final note = find.byKey(const ValueKey('purchase-note'));
    await tester.ensureVisible(note);
    await tester.enterText(note, 'x' * 201);
    await tester.tap(find.text('Lưu khoản mua'));
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú tối đa 200 ký tự'), findsOneWidget);
    expect(h.service.addCalls, 0);
  });

  for (final width in [360.0, 412.0, 1024.0]) {
    testWidgets('form fits width $width with text scaled to 200 percent', (
      tester,
    ) async {
      await size(tester, width: width);
      await h.initialize(item: sampleWishlist());
      await openForm(
        tester,
        args: RecordPurchaseArgs(wishlistItem: sampleWishlist()),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('purchase-note')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'amount input keeps accepting digits after adding thousands separators and rejects invalid paste',
    (tester) async {
      await h.initialize();
      await openForm(tester);
      await tester.tap(amountField());
      final controller = tester
          .widget<TextFormField>(amountField())
          .controller!;
      for (final digit in ['1', '0', '0', '0', '0', '0', '0']) {
        final text = '${controller.text}$digit';
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump();
      }
      expect(controller.text, '1.000.000');
      await tester.enterText(amountField(), '12.5');
      expect(controller.text, '1.000.000');
      await tester.enterText(amountField(), '-100');
      expect(controller.text, '1.000.000');
      await tester.enterText(amountField(), '1000000000');
      expect(controller.text, '1.000.000');
    },
  );
}
