import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/formatters/money_format.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/voucher.dart';
import 'package:prm393_lab03/models/voucher_matcher.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/item_detail_screen.dart';
import 'package:prm393_lab03/services/voucher_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/widgets/voucher_suggestion_card.dart';
import 'package:prm393_lab03/widgets/wishlist_card.dart';
import 'package:provider/provider.dart';

import '../support/purchase_harness.dart';
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
  String category = 'Tất cả',
}) => Voucher(
  id: code,
  code: code,
  title: 'Voucher $code',
  discountAmount: discount,
  minOrder: minOrder,
  validUntil: validUntil,
  shopName: shopName,
  category: category,
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

/// The UI audit item, but saved from a Shopee product so vouchers can apply
/// Gives the cards a price history (null = not loaded yet); nothing else is used
class _HistoryDecisions extends ChangeNotifier
    implements DecisionSupportViewModel {
  _HistoryDecisions(this.snapshots);

  final List<PriceSnapshot>? snapshots;

  @override
  PriceInsights? priceInsightsFor(WishlistItem item) {
    final list = snapshots;
    return list == null ? null : PriceInsights(list, now: DateTime.now());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ShopeeAuditHarness extends UiAuditHarness {
  _ShopeeAuditHarness() : super(true);

  late final WishlistItem _shopeeItem = super.item.copyWith(
    productKey: 'shopee:1:2',
  );

  @override
  WishlistItem get item => _shopeeItem;
}

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

  group('VoucherMatcher.canApply: chỉ món Shopee', () {
    // Discount vouchers (shop and site-wide) that a 450.000đ Shopee item gets
    final all = [
      _voucher('BIG50', discount: 50000, minOrder: 100000),
      _voucher('MID30', discount: 30000),
      _perseper,
    ];

    WishlistItem item({String? productKey, String? url, bool isDemo = false}) =>
        WishlistItem(
          id: 'i',
          title: 'Tai nghe',
          url: url,
          productKey: productKey,
          shopName: 'Perseper',
          latestPriceVnd: 450000,
          isDemo: isDemo,
          createdAt: DateTime(2026, 11, 1),
        );

    List<String> codes(WishlistItem i) => VoucherMatcher.applicable(
      all,
      i,
      450000,
      _now,
    ).map((v) => v.code).toList();

    test('món nhập tay (productKey null) 450.000đ: không áp mã nào', () {
      expect(codes(item()), isEmpty);
      expect(VoucherMatcher.best(all, item(), 450000, _now), isNull);
    });

    test('món có link Tiki/TikTok/Lazada: không áp', () {
      expect(codes(item(url: 'https://tiki.vn/tai-nghe-p123.html')), isEmpty);
      expect(
        codes(item(url: 'https://www.tiktok.com/view/product/1729')),
        isEmpty,
      );
      expect(codes(item(productKey: 'tiki:123')), isEmpty);
      expect(codes(item(productKey: 'lazada:1:2')), isEmpty);
      expect(codes(item(productKey: 'tiktok:shopee:1')), isEmpty);
    });

    test('món isDemo: không áp', () {
      expect(codes(item(productKey: 'shopee:1:2', isDemo: true)), isEmpty);
    });

    test('món có productKey Shopee: áp như cũ', () {
      expect(codes(item(productKey: 'shopee:1:2')), [
        'PERSEPER15K',
        'BIG50',
        'MID30',
      ]);
    });

    test('Voucher.fromFirestore bỏ qua field platform cũ', () {
      final v = Voucher.fromFirestore({
        'code': 'OLD',
        'platform': 'Lazada',
        'validUntil': '2026-12-31',
      }, 'old');
      expect(
        VoucherMatcher.canApply(
          v,
          item(productKey: 'shopee:1:2'),
          450000,
          _now,
        ),
        isTrue,
      );
    });
  });

  group('VoucherMatcher.canApply: đúng loại hàng', () {
    // Sample codes: TECH1111 'Công nghệ' (đơn từ 500K, hạn 15/11),
    // FASHION30K 'Thời trang' (đơn từ 100K, hạn 20/11); _now is 15/11
    Voucher sample(String code) =>
        VoucherService.defaultVouchers.firstWhere((v) => v.code == code);
    final tech = sample('TECH1111');
    final fashion = sample('FASHION30K');
    final everyone = _voucher('ALL20', discount: 20000);

    WishlistItem item(String title, String? groupId, int price) => WishlistItem(
      id: title,
      title: title,
      productKey: 'shopee:1:2',
      budgetGroupId: groupId,
      latestPriceVnd: price,
      createdAt: DateTime(2026, 11, 1),
    );

    test(
      'áo khoác 550.000đ nhóm fashion: không áp TECH1111, áp FASHION30K',
      () {
        final jacket = item('Áo khoác', 'fashion', 550000);
        expect(VoucherMatcher.canApply(tech, jacket, 550000, _now), isFalse);
        expect(VoucherMatcher.canApply(fashion, jacket, 550000, _now), isTrue);
      },
    );

    test('laptop nhóm tech: áp TECH1111', () {
      final laptop = item('Laptop', 'tech', 15000000);
      expect(VoucherMatcher.canApply(tech, laptop, 15000000, _now), isTrue);
      expect(VoucherMatcher.canApply(fashion, laptop, 15000000, _now), isFalse);
    });

    test('món nhóm other hoặc chưa có nhóm: chỉ áp voucher Tất cả', () {
      for (final groupId in ['other', null]) {
        final codes = VoucherMatcher.applicable(
          [tech, fashion, everyone],
          item('Đồ lặt vặt', groupId, 600000),
          600000,
          _now,
        ).map((v) => v.code);
        expect(codes, ['ALL20'], reason: 'budgetGroupId $groupId');
      }
    });

    test('category lạ: không áp', () {
      final toys = _voucher('TOY10', category: 'Đồ chơi');
      for (final groupId in ['food', 'tech', 'other', null]) {
        expect(
          VoucherMatcher.canApply(
            toys,
            item('Món', groupId, 200000),
            200000,
            _now,
          ),
          isFalse,
        );
      }
    });

    test('bảng ánh xạ đủ 5 loại', () {
      expect(VoucherMatcher.categoryToBudgetGroup, {
        'Ăn uống': 'food',
        'Thời trang': 'fashion',
        'Công nghệ': 'tech',
        'Làm đẹp': 'beauty',
        'Học tập': 'study',
      });
    });
  });

  test('danh sách mẫu không còn LAZADA1111', () {
    expect(
      VoucherService.defaultVouchers.map((v) => v.code),
      isNot(contains('LAZADA1111')),
    );
  });

  group('VoucherMatcher.listPriceFor / priceAfter', () {
    PriceSnapshot snap(
      int amount,
      int day, {
      PriceType type = PriceType.single,
      int? min,
      int? max,
    }) => PriceSnapshot(
      id: 's$day',
      amountVnd: amount,
      observedAt: DateTime(2026, 11, day),
      priceType: type,
      minVnd: min,
      maxVnd: max,
    );

    test('mới nhất afterVoucher 95.000đ, niêm yết trước 110.000đ: tính trên '
        '110.000đ', () {
      final item = _item(price: 95000);
      final history = [
        snap(110000, 1),
        snap(95000, 5, type: PriceType.afterVoucher),
      ];
      final list = VoucherMatcher.listPriceFor(item, history: history)!;
      expect(list, (amountVnd: 110000, isRange: false));
      // Đơn từ 100.000đ: áp trên 110.000đ, 95.000đ thì không
      final v = _voucher('MIN100', discount: 20000, minOrder: 100000);
      expect(VoucherMatcher.best([v], item, list.amountVnd, _now), v);
      expect(VoucherMatcher.priceAfter(list.amountVnd, v), 90000);
    });

    test('chỉ có giá afterVoucher: null', () {
      final history = [
        snap(95000, 5, type: PriceType.afterVoucher),
        snap(99000, 2, type: PriceType.afterVoucher),
      ];
      expect(
        VoucherMatcher.listPriceFor(_item(price: 95000), history: history),
        isNull,
      );
    });

    test('khoảng giá 120.000–250.000đ: tính trên 120.000đ, isRange', () {
      final history = [
        snap(110000, 1),
        snap(120000, 4, type: PriceType.range, min: 120000, max: 250000),
      ];
      expect(
        VoucherMatcher.listPriceFor(_item(price: 120000), history: history),
        (amountVnd: 120000, isRange: true),
      );
    });

    test('voucher giảm lớn hơn giá: 0', () {
      final big = _voucher('BIG80', discount: 80000);
      expect(VoucherMatcher.priceAfter(50000, big), 0);
    });

    test('lịch sử rỗng + latestPriceVnd 120.000đ + món Shopee: giá niêm yết '
        '120.000đ, có giá sau voucher', () {
      final item = _item(price: 120000, shopName: null);
      final list = VoucherMatcher.listPriceFor(item, history: const [])!;
      expect(list, (amountVnd: 120000, isRange: false));
      final v = _voucher('BIG50', discount: 50000, minOrder: 100000);
      final best = VoucherMatcher.best([v], item, list.amountVnd, _now)!;
      expect(VoucherMatcher.priceAfter(list.amountVnd, best), 70000);
    });

    test('lịch sử rỗng + latestPriceVnd null: null', () {
      expect(
        VoucherMatcher.listPriceFor(_item(price: null), history: const []),
        isNull,
      );
    });

    test('lịch sử chưa nạp: null', () {
      expect(VoucherMatcher.listPriceFor(_item(price: 120000)), isNull);
    });

    test('món không có link (nhập tay): vẫn không có voucher (V2)', () {
      final manual = WishlistItem(
        id: 'manual',
        title: 'Tai nghe',
        latestPriceVnd: 120000,
        createdAt: DateTime(2026, 11, 1),
      );
      final list = VoucherMatcher.listPriceFor(manual, history: const [])!;
      expect(list.amountVnd, 120000);
      final v = _voucher('BIG50', discount: 50000, minOrder: 100000);
      expect(VoucherMatcher.best([v], manual, list.amountVnd, _now), isNull);
    });
  });

  group('Mã miễn phí vận chuyển', () {
    // The sample codes expire on 12/11/2026: check on 11/11/2026, 10:00 Vietnam time
    final nov11 = DateTime.utc(2026, 11, 11, 3);
    Voucher sample(String code) =>
        VoucherService.defaultVouchers.firstWhere((v) => v.code == code);

    test('FREESHIP0D trong danh sách mẫu là freeship', () {
      expect(sample('FREESHIP0D').isFreeship, isTrue);
      expect(sample('SHOPEE1111').isFreeship, isFalse);
    });

    test('món 89.000đ chỉ có FREESHIP0D: best null, hasFreeship true', () {
      final all = [sample('FREESHIP0D')];
      final item = _item(price: 89000);
      expect(VoucherMatcher.best(all, item, 89000, nov11), isNull);
      expect(VoucherMatcher.hasFreeship(all, item, 89000, nov11), isTrue);
    });

    test('món 300.000đ có SHOPEE1111 và FREESHIP0D: best là SHOPEE1111', () {
      final all = [sample('FREESHIP0D'), sample('SHOPEE1111')];
      final item = _item(price: 300000);
      expect(VoucherMatcher.best(all, item, 300000, nov11)?.code, 'SHOPEE1111');
      expect(
        VoucherMatcher.applicable(all, item, 300000, nov11).map((v) => v.code),
        ['SHOPEE1111'],
      );
      expect(VoucherMatcher.hasFreeship(all, item, 300000, nov11), isTrue);
    });

    test('hasFreeship false khi món chưa có giá', () {
      final all = [sample('FREESHIP0D')];
      for (final price in <int?>[null, 0]) {
        expect(
          VoucherMatcher.hasFreeship(all, _item(price: price), price, nov11),
          isFalse,
        );
      }
    });

    test('đọc type từ Firestore, giá trị lạ là discount', () {
      Voucher read(Object? type) =>
          Voucher.fromFirestore({'code': 'X', 'type': ?type}, 'x');
      expect(read('freeship').type, Voucher.typeFreeship);
      expect(read('discount').type, Voucher.typeDiscount);
      expect(read('abc').type, Voucher.typeDiscount);
      expect(read(null).type, Voucher.typeDiscount);
    });

    test('dữ liệu cũ thiếu type: đoán từ code/title', () {
      String typeOf(Map<String, dynamic> data) =>
          Voucher.fromFirestore(data, 'x').type;
      expect(typeOf({'code': 'FREESHIPXTRA'}), Voucher.typeFreeship);
      expect(
        typeOf({'title': 'Miễn phí vận chuyển 15K'}),
        Voucher.typeFreeship,
      );
      expect(typeOf({'title': 'Free Ship đơn từ 0Đ'}), Voucher.typeFreeship);
      expect(typeOf({'code': 'SALE50K'}), Voucher.typeDiscount);
      // An explicit type is never guessed
      expect(
        typeOf({'code': 'FREESHIPXTRA', 'type': 'discount'}),
        Voucher.typeDiscount,
      );
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
      String? type,
    }) => {
      'code': code,
      'title': 'Voucher $code',
      'platform': 'Shopee',
      'discountAmount': discount,
      'minOrder': minOrder,
      'validUntil': validUntil,
      'isActive': true,
      'shopName': ?shopName,
      'type': ?type,
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
      WishlistItem item, {
      DecisionSupportViewModel? decisions,
    }) async {
      // Default: price history loaded and empty, so the cards use latestPriceVnd
      final vm = decisions ?? _HistoryDecisions(const []);
      if (decisions == null) addTearDown(vm.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<VoucherService>.value(value: vs),
            ChangeNotifierProvider<DecisionSupportViewModel>.value(value: vm),
          ],
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

    testWidgets('mã freeship không vào giá, Chi tiết món chỉ hiện một dòng', (
      tester,
    ) async {
      final vs = await service([doc('SHIP25', 25000, type: 'freeship')]);
      addTearDown(vs.dispose);
      await pumpBoth(tester, vs, _item(price: 89000));

      // Thẻ món: giá không bị gạch, không có giá sau voucher
      final price = tester.widget<Text>(inWishlistCard(formatVnd(89000)));
      expect(price.style?.decoration, isNot(TextDecoration.lineThrough));
      expect(find.text(formatVnd(89000 - 25000)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(WishlistCard),
          matching: find.textContaining('SHIP25'),
        ),
        findsNothing,
      );
      // Chi tiết món: không có khung giá, chỉ một dòng freeship kèm mã
      expect(find.text('Giá sau áp voucher:'), findsNothing);
      expect(find.text('Đủ điều kiện'), findsNothing);
      expect(
        inSuggestionCard('Có mã miễn phí vận chuyển: SHIP25'),
        findsOneWidget,
      );
    });

    group('thẻ món chỉ hiện giá sau voucher khi biết giá niêm yết', () {
      // BIG50: giảm 50.000đ cho đơn từ 100.000đ; món 120.000đ
      PriceSnapshot snap(int amount, int daysAgo, PriceType type) =>
          PriceSnapshot(
            id: 's$daysAgo',
            amountVnd: amount,
            observedAt: DateTime.now().subtract(Duration(days: daysAgo)),
            priceType: type,
          );

      Future<void> pumpCard(
        WidgetTester tester,
        List<PriceSnapshot>? history,
      ) async {
        final vs = await service([doc('BIG50', 50000, minOrder: 100000)]);
        addTearDown(vs.dispose);
        final decisions = _HistoryDecisions(history);
        addTearDown(decisions.dispose);
        await pumpBoth(tester, vs, _item(price: 120000), decisions: decisions);
      }

      bool mainPriceStruck(WidgetTester tester) =>
          tester
              .widget<Text>(inWishlistCard(formatVnd(120000)))
              .style
              ?.decoration ==
          TextDecoration.lineThrough;

      testWidgets('lịch sử chưa nạp: không có giá sau voucher', (tester) async {
        await pumpCard(tester, null);
        expect(inWishlistCard(formatVnd(70000)), findsNothing);
        expect(mainPriceStruck(tester), isFalse);
        // Chi tiết món waits for the history too: no voucher, no "Thêm giá…"
        expect(find.byType(VoucherSuggestionCard), findsOneWidget);
        expect(find.textContaining('BIG50'), findsNothing);
        expect(find.textContaining('Thêm giá của món'), findsNothing);
      });

      testWidgets('lịch sử đã nạp và rỗng: dùng latestPriceVnd ở cả hai chỗ', (
        tester,
      ) async {
        await pumpCard(tester, const []);
        expect(inWishlistCard(formatVnd(70000)), findsOneWidget);
        expect(mainPriceStruck(tester), isTrue);
        expect(inSuggestionCard(formatVnd(70000)), findsOneWidget);
      });

      testWidgets('đã nạp, giá mới nhất là giá niêm yết: có', (tester) async {
        await pumpCard(tester, [
          snap(120000, 0, PriceType.single),
          snap(130000, 3, PriceType.single),
        ]);
        expect(inWishlistCard(formatVnd(70000)), findsOneWidget);
        expect(mainPriceStruck(tester), isTrue);
      });

      testWidgets('đã nạp, chỉ có giá afterVoucher: không', (tester) async {
        await pumpCard(tester, [snap(95000, 0, PriceType.afterVoucher)]);
        expect(inWishlistCard(formatVnd(70000)), findsNothing);
        expect(inWishlistCard(formatVnd(45000)), findsNothing);
        expect(mainPriceStruck(tester), isFalse);
      });

      testWidgets('đã nạp, mới nhất afterVoucher nhưng có giá niêm yết trước '
          'đó: tính trên giá niêm yết (như V6)', (tester) async {
        await pumpCard(tester, [
          snap(95000, 0, PriceType.afterVoucher),
          snap(110000, 2, PriceType.single),
        ]);
        expect(inWishlistCard(formatVnd(110000 - 50000)), findsOneWidget);
        expect(inWishlistCard(formatVnd(95000 - 50000)), findsNothing);
      });
    });

    testWidgets('khoảng giá: giá sau voucher ghi "từ …" ở cả hai chỗ', (
      tester,
    ) async {
      final vs = await service([doc('BIG50', 50000, minOrder: 100000)]);
      addTearDown(vs.dispose);
      final decisions = _HistoryDecisions([
        PriceSnapshot(
          id: 'range',
          amountVnd: 120000,
          observedAt: DateTime.now(),
          priceType: PriceType.range,
          minVnd: 120000,
          maxVnd: 250000,
        ),
      ]);
      addTearDown(decisions.dispose);
      await pumpBoth(tester, vs, _item(price: 120000), decisions: decisions);

      final after = 'từ ${formatVnd(120000 - 50000)}';
      expect(inWishlistCard(after), findsOneWidget);
      expect(inSuggestionCard(after), findsOneWidget);
    });

    testWidgets('dòng freeship có nút Lưu mã sao chép đúng mã', (tester) async {
      String? copied;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final vs = await service([
        doc('MID30', 30000),
        doc('SHIP25', 25000, type: 'freeship'),
      ]);
      addTearDown(vs.dispose);
      await pumpBoth(tester, vs, _item(price: 89000));

      // Two "Lưu mã" buttons: MID30 and the free-shipping line
      expect(find.text('Lưu mã'), findsNWidgets(2));
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('voucher-freeship')),
          matching: find.text('Lưu mã'),
        ),
      );
      await tester.pump();
      expect(copied, 'SHIP25');
      expect(
        find.text('Đã sao chép mã SHIP25 để dùng trên Shopee.'),
        findsOneWidget,
      );
    });

    testWidgets('món chưa có giá, chỉ có mã freeship: vẫn hiện dòng Thêm giá', (
      tester,
    ) async {
      final vs = await service([doc('SHIP25', 25000, type: 'freeship')]);
      addTearDown(vs.dispose);
      await pumpBoth(tester, vs, _item(price: null));

      expect(
        inSuggestionCard('Thêm giá của món để xem mã áp được'),
        findsOneWidget,
      );
      expect(find.textContaining('SHIP25'), findsNothing);
    });

    testWidgets(
      'Chi tiết món 360×640, chữ 1.3, tên dài + giá 999.999.999đ: không tràn',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final vs = await service(vouchers);
        addTearDown(vs.dispose);
        // Item: auditLongName, 999.999.999 ₫, saved from Shopee
        final h = _ShopeeAuditHarness();
        final errors = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(details.toString());
        try {
          final app = await h.app('item_detail', testAppTheme, 1.3);
          await tester.pumpWidget(
            ChangeNotifierProvider<VoucherService>.value(value: vs, child: app),
          );
          await tester.pump(const Duration(milliseconds: 300));
          // The harness's DecisionSupportViewModel has no signed-in user, so the
          // price history never loads: sign in and load it as PriceHistoryPanel does
          final decisions = Provider.of<DecisionSupportViewModel>(
            tester.element(find.byType(ItemDetailScreen)),
            listen: false,
          )..updateUid(PurchaseHarness.uid);
          await decisions.loadPriceHistory(h.item);
          await tester.pump();
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
