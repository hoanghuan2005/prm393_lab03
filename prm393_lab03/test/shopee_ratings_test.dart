import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/core/formatters/rating_format.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';

import 'support/purchase_harness.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() => db = FakeFirebaseFirestore());

  test('WishlistItem reads the extension ratings', () async {
    final ref = db.doc('users/u/wishlistItems/w1');
    await ref.set({
      'title': 'Tai nghe',
      'status': 'considering',
      'createdAt': Timestamp.now(),
      'shopName': 'Shop Mây',
      'productRating': 4.84,
      'productRatingCount': 1200,
      'shopRating': 5,
    });
    final item = WishlistItem.fromFirestore(await ref.get());

    expect(item.productRating, 4.8);
    expect(item.productRatingCount, 1200);
    expect(item.shopRating, 5.0);
    // Written back only when known, so an app edit keeps them
    expect(item.toMap()['productRatingCount'], 1200);
    final bare = WishlistItem(id: 'x', title: 'x', createdAt: DateTime(2026));
    expect(bare.toMap().containsKey('productRating'), isFalse);
  });

  test('bad ratings are dropped, not shown', () async {
    final ref = db.doc('users/u/wishlistItems/w2');
    await ref.set({
      'title': 'Tai nghe',
      'createdAt': Timestamp.now(),
      'productRating': 6,
      'productRatingCount': '1,2k',
      'shopRating': 0.04,
    });
    final item = WishlistItem.fromFirestore(await ref.get());

    expect(item.productRating, isNull);
    expect(item.productRatingCount, isNull);
    expect(item.shopRating, isNull, reason: '0.04 rounds to 0');
  });

  test('PriceSnapshot keeps the shop and ratings at reading time', () async {
    final ref = db.doc('users/u/wishlistItems/w1/priceSnapshots/s1');
    await ref.set({
      'amountVnd': 399000,
      'observedAt': Timestamp.now(),
      'source': 'extensionPage',
      'shopName': 'Shop Mây',
      'productRating': 4.8,
      'productRatingCount': 1200,
      'shopRating': 4.9,
    });
    final s = PriceSnapshot.fromFirestore(await ref.get());

    expect(s.shopName, 'Shop Mây');
    expect(s.productRating, 4.8);
    expect(s.productRatingCount, 1200);
    expect(s.shopRating, 4.9);
    expect(s.toMap()['shopRating'], 4.9);
  });

  test('rating parts', () {
    expect(formatProductRating(4.8, 1200), '★ 4,8 (1.200 đánh giá)');
    expect(formatProductRating(4.5, 3400000), '★ 4,5 (3.400.000 đánh giá)');
    expect(formatProductRating(4.8, null), '★ 4,8');
    expect(formatProductRating(null, 1200), isNull);
    // The shop name exactly as stored, no "Shop" added in front
    expect(formatShopRating('Shop Mây', 4.9), 'Shop Mây ★ 4,9');
    expect(formatShopRating('Mây', null), 'Mây');
    expect(formatShopRating(null, 5), '★ 5,0');
    expect(formatShopRating(' ', null), isNull);
  });

  group('Chi tiết món', () {
    late PurchaseHarness h;
    setUp(() => h = PurchaseHarness());
    tearDown(() => h.dispose());

    Future<void> open(WidgetTester tester, WishlistItem item) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.initialize(item: item);
      await tester.pumpWidget(
        h.app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.itemDetail,
                arguments: ItemDetailArgs(item),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
    }

    /// Plain text of the rating line; the shop icon is the placeholder ￼
    String line(WidgetTester tester) => tester
        .widget<RichText>(
          find
              .descendant(
                of: find.byKey(const ValueKey('item-ratings')),
                matching: find.byType(RichText),
              )
              .first, // the Icon inside renders its own RichText
        )
        .text
        .toPlainText();

    Finder shopIcon() => find.descendant(
      of: find.byKey(const ValueKey('item-ratings')),
      matching: find.byIcon(Icons.storefront_outlined),
    );

    testWidgets('shows the rating line with a shop icon when known', (
      tester,
    ) async {
      await open(
        tester,
        sampleWishlist().copyWith(
          shopName: 'Mây Store',
          productRating: 4.8,
          productRatingCount: 1200,
          shopRating: 4.9,
        ),
      );

      expect(line(tester), '★ 4,8 (1.200 đánh giá) · ￼ Mây Store ★ 4,9');
      expect(shopIcon(), findsOneWidget);
      final icon = tester.widget<Icon>(shopIcon());
      expect(
        icon.color,
        Theme.of(tester.element(shopIcon())).colorScheme.onSurfaceVariant,
      );
    });

    testWidgets('a shop named "Shop Mây" is not shown as "Shop Shop Mây"', (
      tester,
    ) async {
      await open(
        tester,
        sampleWishlist().copyWith(shopName: 'Shop Mây', shopRating: 4.9),
      );

      expect(line(tester), '￼ Shop Mây ★ 4,9');
      expect(line(tester), isNot(contains('Shop Shop')));
    });

    testWidgets('shows nothing without ratings, even with a shop name', (
      tester,
    ) async {
      await open(tester, sampleWishlist().copyWith(shopName: 'Shop Mây'));

      expect(find.byKey(const ValueKey('item-ratings')), findsNothing);
      expect(find.textContaining('★'), findsNothing);
    });
  });
}
