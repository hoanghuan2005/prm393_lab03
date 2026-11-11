import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/formatters/money_format.dart';
import 'package:prm393_lab03/models/voucher.dart';
import 'package:prm393_lab03/models/voucher_matcher.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/voucher_service.dart';
import 'package:prm393_lab03/widgets/voucher_suggestion_card.dart';
import 'package:prm393_lab03/widgets/wishlist_card.dart';
import 'package:provider/provider.dart';

import '../support/test_theme.dart';
import '../ui/ui_audit_harness.dart';

// 15/11/2026, 10:00 Vietnam time (UTC+7)
final _now = DateTime.utc(2026, 11, 15, 3);

Voucher _voucher(
  String code, {
  int discount = 10000,
  int minOrder = 0,
  String validUntil = '2026-12-31',
  String? shopName,
  String platform = 'Shopee',
}) => Voucher(
  id: code,
  code: code,
  title: 'Voucher $code',
  platform: platform,
  discountAmount: discount,
  minOrder: minOrder,
  validUntil: validUntil,
  shopName: shopName,
);

// Same values as PERSEPER15K in VoucherService.defaultVouchers
final _perseper = _voucher(
  'PERSEPER15K',
  discount: 15000,
  minOrder: 50000,
  validUntil: '2026-11-30',
  shopName: 'Perseper',
);

WishlistItem _item({String? shopName = 'Perseper', int? price = 120000}) =>
    WishlistItem(
      id: 'item-1',
      title: 'Áo thun',
      url: 'https://shopee.vn/product/1/2',
      productKey: 'shopee:1:2',
      saveChannel: SaveChannel.share,
      shopName: shopName,
      latestPriceVnd: price,
      createdAt: DateTime(2026, 11, 1),
    );

void main() {
  group('VoucherMatcher.canApply: hạn dùng', () {
    bool applies(String validUntil, {DateTime? now}) => VoucherMatcher.canApply(
      _voucher('X', validUntil: validUntil),
      _item(),
      120000,
      now ?? _now,
    );

    test('hết hạn hôm trước thì không áp', () {
      expect(applies('2026-11-14'), isFalse);
    });

    test('hạn đúng hôm nay thì áp', () {
      expect(applies('2026-11-15'), isTrue);
    });

    test('chuỗi rỗng thì không áp', () {
      expect(applies(''), isFalse);
    });

    test('không phải ngày thì không áp', () {
      expect(applies('abc'), isFalse);
    });

    test('áp tới hết ngày theo giờ Việt Nam', () {
      // 23:59 15/11 giờ Việt Nam
      expect(
        applies('2026-11-15', now: DateTime.utc(2026, 11, 15, 16, 59)),
        isTrue,
      );
      // 00:00 16/11 giờ Việt Nam
      expect(
        applies('2026-11-15', now: DateTime.utc(2026, 11, 15, 17)),
        isFalse,
      );
    });
  });

  group('VoucherMatcher.canApply: đơn tối thiểu', () {
    test('món 40.000đ với PERSEPER15K (đơn từ 50.000đ) thì không áp', () {
      expect(VoucherMatcher.canApply(_perseper, _item(), 40000, _now), isFalse);
    });

    test('món 120.000đ với PERSEPER15K thì áp', () {
      expect(VoucherMatcher.canApply(_perseper, _item(), 120000, _now), isTrue);
    });
  });

  group('VoucherMatcher.applicable / best', () {
    final all = [
      _voucher('MID30', discount: 30000),
      _perseper,
      _voucher('BIG50', discount: 50000, minOrder: 100000),
      _voucher('EXPIRED99', discount: 99000, validUntil: '2026-11-14'),
      _voucher('SHOP20', discount: 20000, shopName: 'Perseper'),
      _voucher('OTHERSHOP', discount: 40000, shopName: 'XMMN'),
    ];

    test('voucher của shop trước, sau đó số tiền giảm lớn nhất', () {
      final codes = VoucherMatcher.applicable(
        all,
        _item(),
        120000,
        _now,
      ).map((v) => v.code).toList();
      expect(codes, ['SHOP20', 'PERSEPER15K', 'BIG50', 'MID30']);
    });

    test('best là phần tử đầu của applicable', () {
      expect(VoucherMatcher.best(all, _item(), 120000, _now)?.code, 'SHOP20');
      expect(
        VoucherMatcher.best(all, _item(shopName: null), 120000, _now)?.code,
        'BIG50',
      );
    });

    test('best là null khi không voucher nào áp', () {
      expect(VoucherMatcher.best([_perseper], _item(), 40000, _now), isNull);
    });

    test('món chưa có giá (null hoặc 0): rỗng, null, kể cả mã đơn từ 0đ', () {
      final vouchers = [_voucher('FREE0', minOrder: 0), _perseper];
      for (final price in <int?>[null, 0]) {
        final item = _item(price: price);
        expect(VoucherMatcher.applicable(vouchers, item, price, _now), isEmpty);
        expect(VoucherMatcher.best(vouchers, item, price, _now), isNull);
      }
    });
  });

  group('wishlist_card và voucher_suggestion_card', () {
    // Far-future dates: the widgets use the real DateTime.now()
    Future<VoucherService> service(List<Map<String, Object?>> vouchers) async {
      final db = FakeFirebaseFirestore();
      for (final v in vouchers) {
        await db.collection('vouchers').doc(v['code'] as String).set(v);
      }
      return VoucherService(firestore: db);
    }

    Map<String, Object?> doc(
      String code,
      int discount, {
      int minOrder = 0,
      String validUntil = '2099-12-31',
      String? shopName,
    }) => {
      'code': code,
      'title': 'Voucher $code',
      'platform': 'Shopee',
      'discountAmount': discount,
      'minOrder': minOrder,
      'validUntil': validUntil,
      'isActive': true,
      'shopName': ?shopName,
    };

    final vouchers = [
      doc('MID30', 30000),
      doc('PERSEPER15K', 15000, minOrder: 50000, shopName: 'Perseper'),
      doc('BIG50', 50000, minOrder: 100000),
      doc('EXPIRED99', 99000, validUntil: '2020-01-01'),
    ];

    Future<void> pumpBoth(
      WidgetTester tester,
      VoucherService vs,
      WishlistItem item,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<VoucherService>.value(
          value: vs,
          child: MaterialApp(
            theme: testAppTheme,
            home: Scaffold(
              body: ListView(
                children: [
                  WishlistCard(item: item, onTap: () {}),
                  VoucherSuggestionCard(item: item),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder inWishlistCard(String text) => find.descendant(
      of: find.byType(WishlistCard),
      matching: find.text(text),
    );

    Finder inSuggestionCard(String text) => find.descendant(
      of: find.byType(VoucherSuggestionCard),
      matching: find.text(text),
    );

    testWidgets('cùng voucher tốt nhất khi có voucher của shop', (
      tester,
    ) async {
      final vs = await service(vouchers);
      addTearDown(vs.dispose);
      final item = _item();
      await pumpBoth(tester, vs, item);

      final best = VoucherMatcher.best(
        vs.allVouchers,
        item,
        item.latestPriceVnd!,
        DateTime.now(),
      )!;
      expect(best.code, 'PERSEPER15K');
      expect(inSuggestionCard('Đủ điều kiện'), findsOneWidget);
      expect(
        inWishlistCard('Voucher Shop -${formatVnd(best.discountAmount)}'),
        findsOneWidget,
      );
      expect(inSuggestionCard(best.code), findsOneWidget);
      expect(
        inSuggestionCard('Tiết kiệm ${formatVnd(best.discountAmount)}'),
        findsOneWidget,
      );
    });

    testWidgets('cùng voucher tốt nhất, bỏ voucher hết hạn', (tester) async {
      final vs = await service(vouchers);
      addTearDown(vs.dispose);
      final item = _item(shopName: null);
      await pumpBoth(tester, vs, item);

      final best = VoucherMatcher.best(
        vs.allVouchers,
        item,
        item.latestPriceVnd!,
        DateTime.now(),
      )!;
      expect(best.code, 'BIG50');
      expect(
        inWishlistCard('Mã ${best.code} -${formatVnd(best.discountAmount)}'),
        findsOneWidget,
      );
      expect(inSuggestionCard(best.code), findsOneWidget);
      expect(
        inSuggestionCard('Tiết kiệm ${formatVnd(best.discountAmount)}'),
        findsOneWidget,
      );
      expect(find.textContaining('EXPIRED99'), findsNothing);
    });

    testWidgets('món chưa có giá: cả hai không có mã, không có nhãn', (
      tester,
    ) async {
      final vs = await service(vouchers);
      addTearDown(vs.dispose);
      await pumpBoth(tester, vs, _item(price: null));

      for (final v in vouchers) {
        expect(find.textContaining(v['code'] as String), findsNothing);
      }
      expect(find.textContaining('Voucher Shop'), findsNothing);
      expect(find.text('Đủ điều kiện'), findsNothing);
      expect(find.text('Giá sau áp voucher:'), findsNothing);
      expect(
        inSuggestionCard('Thêm giá của món để xem mã áp được'),
        findsOneWidget,
      );
    });

    testWidgets('không có mã nào áp được thì không có nhãn "Đủ điều kiện"', (
      tester,
    ) async {
      final vs = await service([doc('BIG50', 50000, minOrder: 100000)]);
      addTearDown(vs.dispose);
      await pumpBoth(tester, vs, _item(price: 40000));

      expect(find.textContaining('Mã BIG50 cần thêm'), findsOneWidget);
      expect(find.text('Đủ điều kiện'), findsNothing);
    });

    testWidgets(
      'Chi tiết món 360×640, chữ 1.3, tên dài + giá 999.999.999đ: không tràn',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final vs = await service(vouchers);
        addTearDown(vs.dispose);
        // Item: auditLongName, 999.999.999 ₫
        final h = UiAuditHarness(true);
        final errors = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(details.toString());
        try {
          final app = await h.app('item_detail', testAppTheme, 1.3);
          await tester.pumpWidget(
            ChangeNotifierProvider<VoucherService>.value(value: vs, child: app),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.scrollUntilVisible(
            find.text('Giá sau áp voucher:'),
            200,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
          await tester.pump();

          expect(inSuggestionCard('BIG50'), findsOneWidget);
          expect(inSuggestionCard(formatVnd(999999999)), findsOneWidget);
          expect(
            inSuggestionCard(formatVnd(999999999 - 50000)),
            findsOneWidget,
          );
          final exception = tester.takeException();
          if (exception != null) errors.add(exception.toString());
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          h.dispose();
          FlutterError.onError = original;
        }
        expect(errors, isEmpty);
      },
    );
  });
}
