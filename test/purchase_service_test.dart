import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/formatters/money_format.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/services/purchase_service.dart';

import 'support/purchase_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VND input', () {
    test('accepts whole VND with supported grouping and suffixes', () {
      for (final value in ['389000', '389.000 ₫', '389,000', '389000 VND']) {
        expect(parseVnd(value), 389000, reason: value);
      }
    });
    test('does not silently convert a negative, decimal or arbitrary text into money', () {
      for (final value in [
        '',
        '0',
        '-100',
        '12.5',
        '1e3',
        'abc100',
        '1,23',
        '1.000,000',
      ]) {
        expect(parseVnd(value), isNull, reason: value);
      }
    });
  });

  group('Wishlist purchase persistence', () {
    late FakeFirebaseFirestore db;
    late FirestorePurchaseService service;
    final item = sampleWishlist();
    const path = 'users/${PurchaseHarness.uid}';
    final at = DateTime(2026, 10, 20, 19, 30);
    final draft = PurchaseDraft(
      title: 'Tai nghe đã chọn',
      amountVnd: 389000,
      motive: BuyingMotive.need,
      budgetGroupId: 'tech',
      fromWishlistId: item.id,
      occurredAt: at,
      note: 'Dùng cho công việc',
      usedDiscountCode: true,
    );

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FirestorePurchaseService(db);
      await db.doc('$path/wishlistItems/${item.id}').set(item.toMap());
    });

    test(
      'stores actual paid data and links purchase, item and decision',
      () async {
        final saved = await service.buyFromWishlist(
          PurchaseHarness.uid,
          item,
          draft,
        );
        final stored = (await db.doc('$path/purchases/${saved.id}').get())
            .data()!;
        expect(stored['amountVnd'], 389000);
        expect(stored['title'], 'Tai nghe đã chọn');
        expect(stored['motive'], 'need');
        expect(stored['budgetGroupId'], 'tech');
        expect(stored['occurredAt'], Timestamp.fromDate(at));
        expect(stored['usedDiscountCode'], isTrue);
        expect(stored['note'], 'Dùng cho công việc');
        expect(stored['wishlistItemId'], 'headphones');
        final updated = (await db.doc('$path/wishlistItems/${item.id}').get())
            .data()!;
        expect(updated['status'], 'purchased');
        expect(updated['purchaseId'], saved.id);
        expect(
          updated['latestPriceVnd'],
          420000,
          reason: 'reference price remains distinct from actual paid price',
        );
        expect(updated['reviewAt'], isNull);
        expect(updated['decidedAt'], isA<Timestamp>());
        final decisions = await db.collection('$path/decisions').get();
        expect(decisions.docs, hasLength(1));
        expect(decisions.docs.single.data()['choice'], 'buy');
        expect(decisions.docs.single.data()['itemId'], item.id);
      },
    );

    test('a retry returns the first purchase without changing actual paid data or duplicating decisions', () async {
      final first = await service.buyFromWishlist(
        PurchaseHarness.uid,
        item,
        draft,
      );
      final retry = await service.buyFromWishlist(
        PurchaseHarness.uid,
        item,
        draft.copyWith(amountVnd: 300000),
      );
      expect(retry.id, first.id);
      expect(retry.amountVnd, 389000);
      expect((await db.collection('$path/purchases').get()).docs, hasLength(1));
      expect((await db.collection('$path/decisions').get()).docs, hasLength(1));
    });

    test('unknown reference price can be purchased after actual paid amount is supplied', () async {
      final unknown = sampleWishlist(price: null);
      await db.doc('$path/wishlistItems/${unknown.id}').set(unknown.toMap());
      final saved = await service.buyFromWishlist(
        PurchaseHarness.uid,
        unknown,
        draft,
      );
      expect(saved.amountVnd, 389000);
      expect(
        (await db.doc('$path/wishlistItems/${unknown.id}').get())
            .data()!['latestPriceVnd'],
        isNull,
      );
    });

    test(
      'reference price alone is not confirmation of an actual paid amount',
      () async {
        await expectLater(
          service.buyFromWishlist(
            PurchaseHarness.uid,
            item,
            const PurchaseDraft(),
          ),
          throwsA(isA<AppException>()),
        );
        expect((await db.collection('$path/purchases').get()).docs, isEmpty);
        expect(
          (await db.doc('$path/wishlistItems/${item.id}').get())
              .data()!['status'],
          'considering',
        );
      },
    );

    test('a removed or skipped source cannot create an expense', () async {
      await db.doc('$path/wishlistItems/${item.id}').update({
        'status': 'skipped',
      });
      await expectLater(
        service.buyFromWishlist(PurchaseHarness.uid, item, draft),
        throwsA(isA<AppException>()),
      );
      await db.doc('$path/wishlistItems/${item.id}').delete();
      await expectLater(
        service.buyFromWishlist(PurchaseHarness.uid, item, draft),
        throwsA(isA<AppException>()),
      );
      expect((await db.collection('$path/purchases').get()).docs, isEmpty);
    });

    test('explicit confirmation repairs a legacy purchased item without purchaseId', () async {
      final legacy = item.copyWith(status: WishlistStatus.purchased);
      await db.doc('$path/wishlistItems/${item.id}').set(legacy.toMap());
      final saved = await service.buyFromWishlist(
        PurchaseHarness.uid,
        legacy,
        draft,
      );
      expect(
        (await db.doc('$path/wishlistItems/${item.id}').get())
            .data()!['purchaseId'],
        saved.id,
      );
    });

    test('out of range amounts and long notes cannot be persisted', () async {
      for (final invalid in [
        draft.copyWith(amountVnd: 1000000000),
        draft.copyWith(note: 'x' * 201),
      ]) {
        await expectLater(
          service.buyFromWishlist(PurchaseHarness.uid, item, invalid),
          throwsA(isA<AppException>()),
        );
      }
      expect((await db.collection('$path/purchases').get()).docs, isEmpty);
      expect((await db.collection('$path/decisions').get()).docs, isEmpty);
    });

    test('retrying a manual operation uses the same purchase id', () async {
      final purchase = PurchaseItem(
        id: 'request-123',
        title: 'Cơm',
        amountVnd: 40000,
        motive: BuyingMotive.need,
        occurredAt: at,
        budgetGroupId: 'food',
      );
      await service.add(PurchaseHarness.uid, purchase);
      await service.add(PurchaseHarness.uid, purchase);
      expect((await db.collection('$path/purchases').get()).docs, hasLength(1));
    });
  });
}
