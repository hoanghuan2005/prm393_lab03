import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';

import 'support/purchase_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PurchaseHarness h;
  setUp(() async {
    h = PurchaseHarness();
    await h.initialize(item: sampleWishlist());
  });
  tearDown(() {
    h.dispose();
    h.budget.dispose();
  });

  test('manual save persists selected budget group, motive, note and discount flag', () async {
    final at = DateTime(2026, 10, 22, 18, 15);
    final saved = await h.purchases.addPurchase(
      title: '  Bữa tối  ',
      amount: 90000,
      motive: BuyingMotive.convenience,
      dateTime: at,
      budgetGroupId: 'food',
      note: '  Cùng bạn  ',
      usedDiscountCode: true,
    );
    expect(saved!.title, 'Bữa tối');
    expect(saved.budgetGroupId, 'food');
    expect(saved.motive, BuyingMotive.convenience);
    expect(saved.occurredAt, at);
    expect(saved.note, 'Cùng bạn');
    expect(saved.usedDiscountCode, isTrue);
    expect(h.analytics.recordedPurchases, 1);
    expect(h.analytics.buyDecisions, 0);
  });

  test('invalid data never reaches a write', () async {
    for (final amount in [0, -100, 1000000000]) {
      expect(
        await h.purchases.addPurchase(
          title: 'Món',
          amount: amount,
          motive: BuyingMotive.need,
        ),
        isNull,
      );
    }
    expect(
      await h.purchases.addPurchase(
        title: '',
        amount: 100,
        motive: BuyingMotive.need,
      ),
      isNull,
    );
    expect(
      await h.purchases.addPurchase(
        title: 'Món',
        amount: 100,
        motive: BuyingMotive.need,
        note: 'x' * 201,
      ),
      isNull,
    );
    expect(h.service.addCalls, 0);
    expect(h.purchases.actionError, isNotNull);
  });

  test('one in-flight save cannot create a second expense', () async {
    final gate = Completer<void>();
    h.service.gate = gate;
    final first = h.purchases.addPurchase(
      title: 'Món',
      amount: 100000,
      motive: BuyingMotive.want,
    );
    expect(h.purchases.isSaving, isTrue);
    final second = await h.purchases.addPurchase(
      title: 'Món',
      amount: 100000,
      motive: BuyingMotive.want,
    );
    expect(second, isNull);
    expect(h.service.addCalls, 1);
    gate.complete();
    expect(await first, isNotNull);
    expect(h.purchases.isSaving, isFalse);
  });

  test(
    'failed saves do not create an expense or log success and can be retried',
    () async {
      h.service.rejectWrites = true;
      expect(
        await h.purchases.addPurchase(
          title: 'Món',
          amount: 100000,
          motive: BuyingMotive.want,
          requestId: 'stable',
        ),
        isNull,
      );
      expect(h.purchases.actionError, contains('thử lại'));
      expect(h.analytics.recordedPurchases, 0);
      expect(h.purchases.isSaving, isFalse);
      h.service.rejectWrites = false;
      expect(
        await h.purchases.addPurchase(
          title: 'Món',
          amount: 100000,
          motive: BuyingMotive.want,
          requestId: 'stable',
        ),
        isNotNull,
      );
      expect(h.purchases.actionError, isNull);
      expect(
        (await h.db.collection('users/${PurchaseHarness.uid}/purchases').get())
            .docs,
        hasLength(1),
      );
    },
  );

  test(
    'wishlist buy uses actual data and logs decision only after saving',
    () async {
      final item = sampleWishlist();
      final saved = await h.purchases.addPurchase(
        title: item.title,
        amount: 389000,
        motive: BuyingMotive.sale,
        budgetGroupId: 'tech',
        fromWishlist: item,
      );
      expect(saved!.wishlistItemId, item.id);
      expect(saved.amountVnd, 389000);
      expect(h.service.addCalls, 0);
      expect(h.service.buyCalls, 1);
      expect(h.analytics.recordedPurchases, 1);
      expect(h.analytics.buyDecisions, 1);
    },
  );

  test('editing can clear a note without losing the wishlist link', () async {
    final purchase = PurchaseItem(
      id: 'old',
      title: 'Tai nghe',
      amountVnd: 400000,
      motive: BuyingMotive.want,
      occurredAt: DateTime(2026, 10, 1),
      note: 'Ghi chú cũ',
      wishlistItemId: 'headphones',
      budgetGroupId: 'tech',
    );
    await h.db
        .doc('users/${PurchaseHarness.uid}/purchases/old')
        .set(purchase.toMap());
    final ok = await h.purchases.updatePurchase(
      id: purchase.id,
      title: 'Tai nghe mới',
      amount: 389000,
      motive: BuyingMotive.need,
      dateTime: purchase.occurredAt,
      note: '',
      budgetGroupId: 'other',
      originalPurchase: purchase,
    );
    expect(ok, isTrue);
    final stored =
        (await h.db.doc('users/${PurchaseHarness.uid}/purchases/old').get())
            .data()!;
    expect(stored['note'], isNull);
    expect(stored['wishlistItemId'], 'headphones');
    expect(stored['budgetGroupId'], 'other');
  });

  test('a failed edit is reported as failure', () async {
    h.service.rejectWrites = true;
    final original = PurchaseItem(
      id: 'old',
      title: 'Món',
      amountVnd: 100,
      motive: BuyingMotive.need,
      occurredAt: DateTime(2026, 10),
    );
    expect(
      await h.purchases.updatePurchase(
        id: original.id,
        title: original.title,
        amount: 200,
        motive: original.motive,
        dateTime: original.occurredAt,
        originalPurchase: original,
      ),
      isFalse,
    );
    expect(h.purchases.actionError, contains('thử lại'));
  });

  test(
    'an old session completion cannot be treated as a new user save',
    () async {
      final gate = Completer<void>();
      h.service.gate = gate;
      final save = h.purchases.addPurchase(
        title: 'Món',
        amount: 100000,
        motive: BuyingMotive.need,
      );
      h.purchases.updateUid('user-b');
      gate.complete();
      expect(await save, isNull);
      expect(h.analytics.recordedPurchases, 0);
      expect(
        (await h.db.collection('users/user-b/purchases').get()).docs,
        isEmpty,
      );
    },
  );

  test('wishlist decisions (Chờ, Bỏ qua, Cân nhắc lại) never mark an item as purchased', () async {
    final item = sampleWishlist();
    expect(await h.wishlist.wait(item, DateTime.now().add(const Duration(days: 3))), isTrue);
    expect(await h.wishlist.skip(item), isTrue);
    expect(await h.wishlist.reconsider(item), isTrue);
    final data = (await h.db
            .doc('users/${PurchaseHarness.uid}/wishlistItems/headphones')
            .get())
        .data()!;
    expect(data['status'], WishlistStatus.considering.key);
    expect(data['purchaseId'], isNull);
    expect(h.analytics.buyDecisions, 0);
    expect(
      (await h.db.collection('users/${PurchaseHarness.uid}/purchases').get()).docs,
      isEmpty,
    );
  });
}
