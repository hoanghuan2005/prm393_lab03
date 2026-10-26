import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/budget_screen.dart';

import 'support/purchase_harness.dart';

const _path = 'users/${PurchaseHarness.uid}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PurchaseHarness h;

  setUp(() async {
    h = PurchaseHarness();
    await h.initialize(item: sampleWishlist());
  });
  tearDown(() => h.dispose());

  Future<Map<String, dynamic>> itemData() async =>
      (await h.db.doc('$_path/wishlistItems/headphones').get()).data()!;

  Future<List<String>> decisionChoices() async =>
      (await h.db.collection('$_path/decisions').get()).docs
          .map((d) => d.data()['choice'] as String)
          .toList();

  group('Chờ · Bỏ qua · Cân nhắc lại (item 4)', () {
    test('Chờ stores the chosen review date, keeps "Đang cân nhắc" and logs "wait"', () async {
      final reviewAt = DateTime(2026, 11, 2, 9);
      expect(await h.wishlist.wait(sampleWishlist(), reviewAt), isTrue);
      final data = await itemData();
      expect(data['status'], WishlistStatus.considering.key);
      expect((data['reviewAt'] as dynamic).toDate(), reviewAt);
      expect(await decisionChoices(), ['wait']);
    });

    test('Bỏ qua then undo returns to "Đang cân nhắc" with skip + undo in the log', () async {
      expect(await h.wishlist.skip(sampleWishlist()), isTrue);
      expect((await itemData())['status'], WishlistStatus.skipped.key);
      expect(await h.wishlist.reconsider(sampleWishlist()), isTrue);
      expect((await itemData())['status'], WishlistStatus.considering.key);
      expect(await decisionChoices(), containsAll(['skip', 'undo']));
    });

    test('a failed decision reports an error instead of success', () async {
      h.wishlist.updateUid(null);
      expect(await h.wishlist.skip(sampleWishlist()), isFalse);
      expect(h.wishlist.actionError, isNotNull);
      expect((await itemData())['status'], WishlistStatus.considering.key);
    });
  });

  group('Deleting a purchase bought from the wishlist (item 5)', () {
    Future<String> buy() async {
      final saved = await h.service.buyFromWishlist(
        PurchaseHarness.uid,
        sampleWishlist(),
        const PurchaseDraft(
          title: 'Tai nghe Bluetooth',
          amountVnd: 389000,
          motive: BuyingMotive.sale,
          budgetGroupId: 'tech',
          fromWishlistId: 'headphones',
        ),
      );
      return saved.id;
    }

    test('returns the item to "Đang cân nhắc" in the same batch', () async {
      final purchaseId = await buy();
      expect((await itemData())['status'], WishlistStatus.purchased.key);

      expect(await h.purchases.deletePurchase(purchaseId), isTrue);
      final data = await itemData();
      expect(data['status'], WishlistStatus.considering.key);
      expect(data['purchaseId'], isNull);
      expect((await h.db.doc('$_path/purchases/$purchaseId').get()).exists, isFalse);
      expect(await decisionChoices(), contains('undo'));
    });

    test('the item can be bought again after its purchase was deleted', () async {
      final first = await buy();
      await h.purchases.deletePurchase(first);
      final second = await buy();
      expect((await h.db.doc('$_path/purchases/$second').get()).exists, isTrue);
      expect((await itemData())['purchaseId'], second);
    });

    test('an unlinked purchase is deleted without touching wishlist items', () async {
      final saved = await h.purchases.addPurchase(
        title: 'Cơm tấm',
        amount: 40000,
        motive: BuyingMotive.convenience,
      );
      expect(await h.purchases.deletePurchase(saved!.id), isTrue);
      expect((await itemData())['status'], WishlistStatus.considering.key);
      expect(await decisionChoices(), isEmpty);
    });
  });

  group('Budget per group (item 6)', () {
    test('several group limits are saved in one write; empty removes a limit', () async {
      final month = h.budget.monthKeyValue;
      expect(await h.budget.setGroupLimits({'food': 1000000, 'tech': 2000000}), isTrue);
      var limits = (await h.db.doc('$_path/budgets/$month').get()).data()!['limits'] as Map;
      expect(limits, {'food': 1000000, 'tech': 2000000});

      expect(await h.budget.setGroupLimits({'tech': null}), isTrue);
      limits = (await h.db.doc('$_path/budgets/$month').get()).data()!['limits'] as Map;
      expect(limits, {'food': 1000000});
    });

    testWidgets('purchases count towards their own group and month; total = sum of groups', (
      tester,
    ) async {
      final now = DateTime.now();
      await h.budgetService.setGroupLimits(PurchaseHarness.uid, h.budget.monthKeyValue, {
        'food': 500000,
        'tech': 1000000,
      });
      await h.purchases.addPurchase(
        title: 'Cơm',
        amount: 50000,
        motive: BuyingMotive.need,
        budgetGroupId: 'food',
        dateTime: now,
      );
      await h.purchases.addPurchase(
        title: 'Áo',
        amount: 200000,
        motive: BuyingMotive.want,
        budgetGroupId: 'fashion',
        dateTime: now,
      );
      await h.purchases.addPurchase(
        title: 'Tháng trước',
        amount: 999000,
        motive: BuyingMotive.want,
        budgetGroupId: 'food',
        dateTime: DateTime(now.year, now.month - 1, 10),
      );
      await tester.pumpWidget(h.app(const BudgetScreen()));
      await tester.pumpAndSettle();

      expect(h.budget.spentFor('food'), 50000);
      expect(h.budget.spentFor('fashion'), 200000);
      expect(h.budget.totalLimit, 1500000);
      // A group without a limit but with spending still appears
      expect(find.text('Chưa đặt hạn mức tháng này'), findsOneWidget);
      expect(find.text('Vì sao con số này?'), findsNWidgets(2));
    });
  });

  testWidgets('budget sheet saves a limit per group and shows the total as their sum', (
    tester,
  ) async {
    await tester.pumpWidget(h.app(const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt ngân sách cho tháng này'));
    await tester.pumpAndSettle();

    Finder field(String groupId) => find.descendant(
      of: find.byKey(ValueKey('budget-limit-$groupId')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field('food'), '500000');
    await tester.enterText(field('tech'), '1000000');
    await tester.pumpAndSettle();
    expect(find.text('Tổng ngân sách tháng: 1.500.000 ₫'), findsOneWidget);

    await tester.ensureVisible(find.text('Lưu hạn mức'));
    await tester.tap(find.text('Lưu hạn mức'));
    await tester.pumpAndSettle();
    final limits =
        (await h.db.doc('$_path/budgets/${h.budget.monthKeyValue}').get())
                .data()!['limits']
            as Map;
    expect(limits, {'food': 500000, 'tech': 1000000});
    expect(find.text('Lưu hạn mức'), findsNothing); // sheet closed only after saving
  });

  testWidgets('a failed delete stays on the purchase and offers "Thử lại"', (
    tester,
  ) async {
    final saved = await h.purchases.addPurchase(
      title: 'Cơm tấm',
      amount: 40000,
      motive: BuyingMotive.convenience,
    );
    h.service.rejectWrites = true;
    await tester.pumpWidget(
      h.app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.purchaseDetail,
              arguments: PurchaseDetailArgs(saved!),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xoá khoản mua'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Xoá'));
    await tester.pumpAndSettle();

    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Đã xoá'), findsNothing);
    expect(find.text('open'), findsNothing); // still on the detail screen

    h.service.rejectWrites = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect((await h.db.doc('$_path/purchases/${saved!.id}').get()).exists, isFalse);
  });

  group('Item detail screen', () {
    Future<void> openDetail(WidgetTester tester) async {
      await tester.pumpWidget(
        h.app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.itemDetail,
                    arguments: ItemDetailArgs(sampleWishlist()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Bỏ qua goes back with a 5-second "Hoàn tác" that restores the item', (
      tester,
    ) async {
      await openDetail(tester);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
      expect(find.text('Hoàn tác'), findsOneWidget);
      expect((await itemData())['status'], WishlistStatus.skipped.key);

      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect((await itemData())['status'], WishlistStatus.considering.key);
    });

    testWidgets('Chờ asks for a date and shows the chosen review date', (tester) async {
      await openDetail(tester);
      await tester.tap(find.text('Chờ'));
      await tester.pumpAndSettle();
      expect(find.text('Xem lại món này khi nào?'), findsOneWidget);

      await tester.tap(find.text('Sau 3 ngày'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn hẹn xem lại vào'), findsOneWidget);
      expect((await itemData())['reviewAt'], isNotNull);
    });

    testWidgets('a skipped item offers "Cân nhắc lại"', (tester) async {
      await h.wishlist.skip(sampleWishlist());
      await openDetail(tester);
      await tester.tap(find.text('Cân nhắc lại'));
      await tester.pumpAndSettle();
      expect((await itemData())['status'], WishlistStatus.considering.key);
      expect(find.text('Mua'), findsOneWidget);
    });
  });
}
