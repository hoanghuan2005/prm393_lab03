import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/same_product.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/dev/price_chart_gallery.dart';
import 'package:prm393_lab03/screens/price_history_screen.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/hidden_match_service.dart';
import 'package:prm393_lab03/services/price_history_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/same_product_viewmodel.dart';
import 'package:prm393_lab03/widgets/same_product_card.dart';
import 'package:provider/provider.dart';

import 'support/linked_auth_fakes.dart';

/// The user's own listing and four other shops
const _own = 'shopee:1:10';
const _a = 'shopee:2:20';
const _b = 'shopee:3:30';
const _c = 'shopee:4:40';
const _d = 'shopee:5:50';

PriceHistoryProduct _product(
  String key, {
  String shop = 'Shop',
  Map<String, String> variants = const {},
  String? code = 'ksound-a3',
  bool isDemo = false,
  String? groupId,
}) => PriceHistoryProduct(
  productKey: key,
  title: 'Tai nghe K-Sound A3',
  shopId: key.split(':')[1],
  itemId: key.split(':')[2],
  shopName: shop,
  groupId: groupId,
  isDemo: isDemo,
  createdAt: DateTime.utc(2026, 8, 1),
  productCode: code,
  productCodeSource: code == null ? null : ProductCodeSource.ai,
  variantCodes: variants,
);

PriceHistoryReport _report(
  int vnd,
  DateTime at, {
  String modelKey = 'none',
  HistoryPriceType type = HistoryPriceType.single,
  double? rating,
  String? shop,
}) => PriceHistoryReport(
  id: '$vnd-${at.millisecondsSinceEpoch}-$modelKey',
  amountVnd: vnd,
  priceType: type,
  modelKey: modelKey,
  observedAt: at,
  source: HistoryReportSource.extensionPage,
  shopName: shop,
  productRating: rating,
);

void main() {
  group('pickLowestOffers', () {
    /// 12:00 in Vietnam
    final now = DateTime.utc(2026, 11, 7, 5);
    DateTime ago(int hours) => now.subtract(Duration(hours: hours));

    final products = {
      _a: _product(_a, shop: 'Shop A', variants: {'21': 'den', '22': 'trang'}),
      _b: _product(_b, shop: 'Shop B', variants: {'31': 'den'}),
      _c: _product(_c, shop: 'Shop C', variants: {'41': 'den'}),
      _d: _product(_d, shop: 'Shop D', variants: {'51': 'den'}),
    };

    test('lowest first, at most 3; latest price, people of that day', () {
      final offers = pickLowestOffers(
        products,
        {
          _a: [
            _report(420000, ago(30), modelKey: '21'),
            // Latest of shop A, with a second person the same day
            _report(410000, ago(2), modelKey: '21', rating: 4.8),
            _report(415000, ago(3), modelKey: '21'),
          ],
          _b: [
            _report(
              390000,
              ago(5),
              modelKey: '31',
              type: HistoryPriceType.flash,
            ),
          ],
          _c: [_report(450000, ago(1), modelKey: '41')],
          _d: [
            _report(
              400000,
              ago(4),
              modelKey: '51',
              type: HistoryPriceType.range,
            ),
          ],
        },
        'den',
        now,
      );

      expect(offers.map((o) => o.productKey), [_b, _d, _a]);
      expect(offers.map((o) => o.priceVnd), [390000, 400000, 410000]);
      final a = offers.last;
      expect(a.shopName, 'Shop A');
      expect(a.reporterCount, 2);
      expect(a.productRating, 4.8);
      expect(a.onSale, isFalse);
      expect(offers.first.onSale, isTrue, reason: 'Flash Sale');
      expect(offers[1].onSale, isFalse, reason: 'range: its lowest price');
    });

    test('another color is not matched', () {
      final offers = pickLowestOffers(
        products,
        {
          _a: [_report(300000, ago(1), modelKey: '22')], // trắng
          _b: [_report(400000, ago(1), modelKey: '31')],
          // A modelKey without a variant code does not count either
          _c: [_report(200000, ago(1), modelKey: '99')],
        },
        'den',
        now,
      );
      expect(offers.map((o) => o.productKey), [_b]);
    });

    test('"sau voucher" is never a list price', () {
      final offers = pickLowestOffers(
        products,
        {
          _a: [
            _report(
              300000,
              ago(1),
              modelKey: '21',
              type: HistoryPriceType.afterVoucher,
            ),
            _report(420000, ago(3), modelKey: '21'),
          ],
          _b: [
            _report(
              250000,
              ago(1),
              modelKey: '31',
              type: HistoryPriceType.afterVoucher,
            ),
          ],
        },
        'den',
        now,
      );
      expect(offers.single.productKey, _a);
      expect(offers.single.priceVnd, 420000);
    });

    test('prices older than 7 days are left out', () {
      final offers = pickLowestOffers(
        products,
        {
          _a: [_report(300000, ago(7 * 24 + 1), modelKey: '21')],
          _b: [_report(400000, ago(6 * 24), modelKey: '31')],
        },
        'den',
        now,
      );
      expect(offers.map((o) => o.productKey), [_b]);
    });

    test('hidden listings are left out; fewer than 3 shops is fine', () {
      final reports = {
        _a: [_report(410000, ago(1), modelKey: '21')],
        _b: [_report(390000, ago(1), modelKey: '31')],
      };
      expect(pickLowestOffers(products, reports, 'den', now), hasLength(2));
      final offers = pickLowestOffers(
        products,
        reports,
        'den',
        now,
        hidden: {_b},
      );
      expect(offers.map((o) => o.productKey), [_a]);
      expect(pickLowestOffers(products, const {}, 'den', now), isEmpty);
    });

    test('an item without variants only matches listings without variants', () {
      final plain = {
        _a: _product(_a, shop: 'Shop A'),
        _b: _product(_b, shop: 'Shop B', variants: {'31': 'den'}),
      };
      final offers = pickLowestOffers(
        plain,
        {
          _a: [_report(410000, ago(1))],
          _b: [_report(390000, ago(1), modelKey: '31')],
        },
        null,
        now,
      );
      expect(offers.map((o) => o.productKey), [_a]);
    });

    test('a shop with two listings appears once, at its lowest price', () {
      const sameShop = 'shopee:2:21';
      final offers = pickLowestOffers(
        {
          ...products,
          sameShop: _product(sameShop, shop: 'Shop A', variants: {'23': 'den'}),
        },
        {
          _a: [_report(410000, ago(1), modelKey: '21')],
          sameShop: [_report(405000, ago(1), modelKey: '23')],
        },
        'den',
        now,
      );
      expect(offers.single.productKey, sameShop);
    });
  });

  group('SameProductViewModel', () {
    late _Service service;
    late _Hidden hidden;
    late _Analytics analytics;
    late SameProductViewModel vm;

    setUp(() {
      service = _Service.sample(DateTime.now());
      hidden = _Hidden();
      analytics = _Analytics();
      vm = SameProductViewModel(
        service: service,
        hiddenService: hidden,
        analytics: analytics,
      )..updateUid('uid-me');
    });

    tearDown(() => vm.dispose());

    test('the 3 lowest other shops of the variant; analytics', () async {
      await vm.load(_item());
      final state = vm.stateFor(_item())!;
      expect(state.visible, isTrue);
      expect(state.offers.map((o) => o.productKey), [_b, _c, _a]);
      expect(state.links!.productKeys, [_b, _c, _a]);
      expect(state.links!.variantCode, 'den');
      expect(analytics.views, [(3, false)]);
    });

    test(
      'no card: no productCode, or the item\'s variant has no code',
      () async {
        service.products[_own] = _product(_own, code: null);
        await vm.load(_item());
        expect(vm.stateFor(_item())!.visible, isFalse);

        service.products[_own] = _product(_own, variants: {'12': 'trang'});
        await vm.load(_item());
        expect(vm.stateFor(_item())!.status, SameProductStatus.none);
        expect(analytics.views, isEmpty);
      },
    );

    test('sample data is only matched with sample data', () async {
      service.products[_own] = _product(
        _own,
        variants: {'11': 'den'},
        isDemo: true,
      );
      await vm.load(_item());
      expect(vm.stateFor(_item())!.visible, isFalse);
      expect(service.lastIsDemo, isTrue);
    });

    test('"Không phải món này": hidden at once, saved, undone', () async {
      await vm.load(_item());
      expect(await vm.hide(_b), isTrue);
      expect(hidden.keys, {_b});
      expect(analytics.hides, 1);
      // Shop D moves up into the 3
      expect(vm.stateFor(_item())!.offers.map((o) => o.productKey), [
        _c,
        _a,
        _d,
      ]);

      await vm.undoHide(_b);
      expect(hidden.keys, isEmpty);
      expect(vm.stateFor(_item())!.offers.first.productKey, _b);
    });

    test('hidden matches are read for the user', () async {
      hidden.keys.add(_b);
      await vm.load(_item());
      expect(
        vm.stateFor(_item())!.offers.map((o) => o.productKey),
        isNot(contains(_b)),
      );
    });

    test('a failed save shows the row again', () async {
      await vm.load(_item());
      hidden.fail = true;
      expect(await vm.hide(_b), isFalse);
      expect(vm.stateFor(_item())!.offers.first.productKey, _b);
    });
  });

  group('Chi tiết món card and the chart', () {
    late _Service service;
    late _Hidden hidden;
    late _Analytics analytics;
    late SameProductViewModel vm;

    Future<void> pump(
      WidgetTester tester, {
      Size size = const Size(412, 1600),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      service = _Service.sample(DateTime.now());
      hidden = _Hidden();
      analytics = _Analytics();
      vm = SameProductViewModel(
        service: service,
        hiddenService: hidden,
        analytics: analytics,
      )..updateUid('uid-me');
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<PriceHistoryService>.value(value: service),
            Provider<AppAnalyticsService>.value(value: analytics),
            Provider<CrashlyticsService>.value(value: CountingCrashlytics()),
            ChangeNotifierProvider<SameProductViewModel>.value(value: vm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: size.width < 400
                ? (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.5)),
                    child: child!,
                  )
                : null,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SameProductCard(item: _item()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void expectNeutral() {
      for (final word in [
        'rẻ hơn',
        'Nên chọn',
        'nên chọn',
        'Nên mua',
        'Mua ở đây',
      ]) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    }

    testWidgets('rows: shop, price, day, people, rating, "Đang giảm"', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Cùng món ở shop khác'), findsOneWidget);
      expect(find.text('Có thể là cùng món · ghép tự động'), findsOneWidget);
      for (final key in [_b, _c, _a]) {
        expect(find.byKey(ValueKey('same-offer-$key')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('same-offer-$_d')), findsNothing);
      expect(find.text('Shop B'), findsOneWidget);
      expect(find.text('390.000 ₫'), findsOneWidget);
      expect(find.textContaining('2 người ghi'), findsWidgets);
      expect(find.textContaining('★ 4,7'), findsOneWidget);
      expect(find.byKey(const ValueKey('same-sale-$_b')), findsOneWidget);
      expect(find.text('Đang giảm'), findsOneWidget);
      expect(find.text('Không phải món này'), findsNWidgets(3));
      expectNeutral();
    });

    testWidgets('"Không phải món này" with "Hoàn tác"', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('same-hide-$_b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('same-offer-$_b')), findsNothing);
      expect(find.byKey(const ValueKey('same-offer-$_d')), findsOneWidget);
      expect(hidden.keys, {_b});

      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('same-offer-$_b')), findsOneWidget);
      expect(hidden.keys, isEmpty);
    });

    testWidgets('hidden without a productCode', (tester) async {
      await pump(tester);
      service.products[_own] = _product(_own, code: null);
      await vm.load(_item());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('same-product-card')), findsNothing);
    });

    testWidgets('a row opens that listing; "Cả nhóm" = the same item list', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('same-offer-$_c')));
      await tester.pumpAndSettle();
      expect(find.byType(PriceHistoryScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('price-scope')), findsOneWidget);

      await tester.tap(find.text('Cả nhóm'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('same-product-note')), findsOneWidget);
      // This listing, the item and the other shops of the card; not shop D
      for (final key in [_c, _own, _b, _a]) {
        expect(find.byKey(ValueKey('shop-latest-$key')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('shop-latest-$_d')), findsNothing);
      // Only "đen" prices: the cheap "trắng" ones are not drawn
      expect(find.textContaining('200.000'), findsNothing);
      expectNeutral();
    });

    testWidgets('fits 320 dp with text at 150%', (tester) async {
      await pump(tester, size: const Size(320, 1600));
      expect(find.byKey(const ValueKey('same-product-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a real product ignores an old groupId', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _Service.sample(DateTime.now());
    // Left by rules G7b; the gallery service knows this group
    service.products[_own] = _product(
      _own,
      shop: 'Shop của tôi',
      variants: {'11': 'den'},
      groupId: InMemoryPriceHistoryService.groupId,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PriceHistoryService>.value(value: service),
          Provider<AppAnalyticsService>.value(value: _Analytics()),
          Provider<CrashlyticsService>.value(value: CountingCrashlytics()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: PriceHistoryScreen.withViewModel(productKey: _own),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tai nghe K-Sound A3'), findsOneWidget);
    expect(find.byKey(const ValueKey('price-scope')), findsNothing);
  });
}

WishlistItem _item() => WishlistItem(
  id: 'w1',
  title: 'Tai nghe của tôi',
  productKey: _own,
  modelId: '11',
  variantLabel: 'Đen',
  createdAt: DateTime.utc(2026, 11, 1),
);

/// The item ("đen" = modelKey 11) and 4 other shops selling "đen", each with
/// 2 reports a day for 6 days (enough for the chart) and a cheap "trắng" price
class _Service extends InMemoryPriceHistoryService {
  bool? lastIsDemo;

  _Service({required super.products, required super.reports});

  factory _Service.sample(DateTime now) {
    final shops = {
      _own: ('Shop của tôi', 430000, '11', '12'),
      _a: ('Shop A', 410000, '21', '22'),
      _b: ('Shop B', 390000, '31', '32'),
      _c: ('Shop C', 400000, '41', '42'),
      _d: ('Shop D', 450000, '51', '52'),
    };
    final products = <String, PriceHistoryProduct>{};
    final reports = <String, List<PriceHistoryReport>>{};
    for (final MapEntry(:key, value: (shop, price, den, trang))
        in shops.entries) {
      products[key] = _product(
        key,
        shop: shop,
        variants: {den: 'den', trang: 'trang'},
      );
      reports[key] = [
        for (var d = 5; d >= 0; d--) ...[
          for (final m in [20, 10])
            _report(
              price,
              now.subtract(Duration(days: d, minutes: m)),
              modelKey: den,
              shop: shop,
              rating: key == _b ? 4.7 : null,
              type: key == _b && d == 0
                  ? HistoryPriceType.sale
                  : HistoryPriceType.single,
            ),
          _report(
            200000,
            now.subtract(Duration(days: d, minutes: 15)),
            modelKey: trang,
            shop: shop,
          ),
        ],
      ];
    }
    return _Service(products: products, reports: reports);
  }

  @override
  Future<List<PriceHistoryProduct>> findSameProduct(
    String productCode, {
    required bool isDemo,
  }) {
    lastIsDemo = isDemo;
    return super.findSameProduct(productCode, isDemo: isDemo);
  }
}

class _Hidden implements HiddenMatchService {
  final keys = <String>{};
  bool fail = false;

  @override
  Future<Set<String>> hiddenKeys(String uid) async => {...keys};

  @override
  Future<void> hide(String uid, String productKey) async {
    if (fail) throw StateError('offline');
    keys.add(productKey);
  }

  @override
  Future<void> unhide(String uid, String productKey) async {
    keys.remove(productKey);
  }
}

class _Analytics extends Fake implements AppAnalyticsService {
  final views = <(int, bool)>[];
  int hides = 0;

  @override
  Future<void> logViewSameProduct({
    required int resultCount,
    required bool isDemo,
  }) async => views.add((resultCount, isDemo));

  @override
  Future<void> logHideSameProductMatch() async => hides++;

  @override
  Future<void> logViewPriceHistory({
    required String mode,
    required int rangeDays,
    required bool isDemo,
  }) async {}
}
