import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/shared_price.dart';
import 'package:prm393_lab03/models/shopee_link.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/shared_price_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/shared_price_viewmodel.dart';
import 'package:prm393_lab03/widgets/shared_price_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 5, 12);
const _key = 'shopee:446089250:44081797761';

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

SharedPriceReport _r(int amount, {int daysAgo = 0, PriceType? type}) =>
    SharedPriceReport(
      amountVnd: amount,
      priceType: type ?? PriceType.single,
      observedAt: _now.subtract(Duration(days: daysAgo, hours: 1)),
    );

PriceSnapshot _mine(
  int amount, {
  PriceSource source = PriceSource.manual,
  bool confirmed = true,
  int daysAgo = 0,
}) => PriceSnapshot(
  id: 's',
  amountVnd: amount,
  source: source,
  confirmed: confirmed,
  observedAt: _now.subtract(Duration(days: daysAgo, hours: 1)),
);

void main() {
  group('Shopee link (spec 6.4, the 8 shared cases)', () {
    test('1: full link with a dotted slug and extraParams', () {
      final link = ShopeeLink.tryParse(
        'https://shopee.vn/K%C3%ADnh-c%C6%B0%E1%BB%9Dng-l%E1%BB%B1c-Glas.tR-i.1367701657.27634673446'
        '?sp_atk=abc&xptdk=def&extraParams=%7B%22display_model_id%22%3A147815204739%7D',
      )!;
      expect(link.shopId, '1367701657');
      expect(link.itemId, '27634673446');
      expect(link.modelId, '147815204739');
      expect(link.productKey, 'shopee:1367701657:27634673446');
    });

    for (final (n, text) in [
      (2, 'shopee.vn/product/446089250/44081797761'),
      (3, 'shopee.vn/opaanlp/446089250/44081797761'),
      (4, 'https://shopee.vn/search?shopid=446089250&itemid=44081797761'),
      (
        5,
        'https://shopee.vn/Lovito-Ao-i.446089250.44081797761?is_from_login=true',
      ),
    ]) {
      test('$n: $text', () {
        final link = ShopeeLink.tryParse(text)!;
        expect(link.productKey, _key);
        expect(link.modelId, isNull);
        expect(
          link.canonicalUrl,
          'https://shopee.vn/product/446089250/44081797761',
        );
      });
    }

    test('6: a short link is not split; it must be opened first', () {
      expect(ShopeeLink.tryParse('s.shopee.vn/AbCd12'), isNull);
      expect(ShopeeLink.isShortLink('s.shopee.vn/AbCd12'), isTrue);
      expect(ShopeeLink.isShortLink('https://shp.ee/xyz'), isTrue);
    });

    test(
      '7: extraParams that is not JSON keeps the ids, drops the variant',
      () {
        final link = ShopeeLink.tryParse(
          'https://shopee.vn/product/446089250/44081797761?extraParams=%7Bnot-json',
        )!;
        expect(link.productKey, _key);
        expect(link.modelId, isNull);
      },
    );

    test('8: Lazada, a look-alike host and plain text are not Shopee', () {
      expect(
        ShopeeLink.tryParse('https://www.lazada.vn/products/x-i123.html'),
        isNull,
      );
      expect(ShopeeLink.tryParse('https://evilshopee.vn/product/1/2'), isNull);
      expect(ShopeeLink.tryParse('tai nghe sony'), isNull);
    });

    test('keys written by the extension are read back', () {
      final link = ShopeeLink.fromProductKey(_key, modelId: '9')!;
      expect(link.productKey, _key);
      expect(link.modelId, '9');
      expect(ShopeeLink.fromProductKey('lazada:1:2'), isNull);
    });
  });

  group('Summary (spec 8.3): same variant, ≤ 3 days, ≥ 2 people, no outliers', () {
    test('median, range and how the user compares', () {
      final s = SharedPriceSummary.summarize(
        [_r(400000), _r(420000), _r(440000)],
        priceType: PriceType.single,
        now: _now,
        myAmountVnd: 462000,
      )!;
      expect(s.count, 3);
      expect(s.medianVnd, 420000);
      expect(s.minVnd, 400000);
      expect(s.maxVnd, 440000);
      expect(s.myDiffPercent, 10);
    });

    test('an even count uses the mean of the two middle prices', () {
      final s = SharedPriceSummary.summarize(
        [_r(400000), _r(410000)],
        priceType: PriceType.single,
        now: _now,
      )!;
      expect(s.medianVnd, 405000);
    });

    test('prices more than 30% from the median are dropped and counted', () {
      final s = SharedPriceSummary.summarize(
        [_r(400000), _r(410000), _r(420000), _r(99000), _r(900000)],
        priceType: PriceType.single,
        now: _now,
      )!;
      expect(s.count, 3);
      expect(s.excludedCount, 2);
      expect(s.medianVnd, 410000);
    });

    test('one person, old prices or another price type say nothing', () {
      SharedPriceSummary? of(List<SharedPriceReport> r) =>
          SharedPriceSummary.summarize(
            r,
            priceType: PriceType.single,
            now: _now,
          );
      expect(of([_r(400000)]), isNull);
      expect(of([_r(400000), _r(410000, daysAgo: 4)]), isNull);
      expect(of([_r(400000), _r(410000, type: PriceType.flash)]), isNull);
      // Two people agree but one more is far off: still 2 left after the filter
      expect(of([_r(400000), _r(410000), _r(990000)])?.count, 2);
    });

    test('report ids are anonymous, stable and one per person and variant', () {
      final a = SharedPriceSummary.reportId('uid-a', _key, 'none');
      expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(a, isNot(contains('uid-a')));
      expect(SharedPriceSummary.reportId('uid-a', _key, 'none'), a);
      expect(SharedPriceSummary.reportId('uid-b', _key, 'none'), isNot(a));
      expect(SharedPriceSummary.reportId('uid-a', _key, '9'), isNot(a));
    });

    test('only the user\'s own fresh, confirmed prices are shared', () {
      bool ok(PriceSnapshot s) => SharedPriceSummary.isShareable(s, _now);
      expect(ok(_mine(400000)), isTrue);
      expect(ok(_mine(400000, source: PriceSource.extensionPage)), isTrue);
      expect(ok(_mine(400000, source: PriceSource.demo)), isFalse);
      expect(ok(_mine(400000, source: PriceSource.community)), isFalse);
      expect(ok(_mine(400000, confirmed: false)), isFalse);
      expect(ok(_mine(400000, daysAgo: 4)), isFalse);
    });
  });

  group('View model with Firestore', () {
    late FakeFirebaseFirestore db;
    late SharedPriceViewModel vm;
    final item = WishlistItem(
      id: 'w1',
      title: 'Tai nghe',
      url: 'https://shopee.vn/product/446089250/44081797761',
      latestPriceVnd: 462000,
      createdAt: DateTime(2026, 11, 1),
    );
    CollectionReference<Map<String, dynamic>> reports() =>
        db.collection('sharedPrices').doc(_key).collection('reports');

    Future<void> seed(String id, int amount) => reports().doc(id).set({
      'modelKey': 'none',
      'priceType': 'single',
      'amountVnd': amount,
      'observedAt': Timestamp.fromDate(_now.subtract(const Duration(hours: 2))),
      'source': 'manual',
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = FakeFirebaseFirestore();
      vm = SharedPriceViewModel(
        service: FirestoreSharedPriceService(db),
        preferencesService: PreferencesService(),
        now: () => _now,
      )..updateUser('uid-me', canContribute: true);
      await _settle();
    });

    tearDown(() => vm.dispose());

    test(
      'shares the user\'s price without any uid and compares with others',
      () async {
        await seed('other-1', 400000);
        await seed('other-2', 440000);
        final mine = _mine(462000);
        await vm.load(item, mine: mine);
        await _settle();

        final own = await reports()
            .doc(SharedPriceSummary.reportId('uid-me', _key, 'none'))
            .get();
        expect(own.exists, isTrue);
        expect(own.data()!.keys.toSet(), {
          'modelKey',
          'priceType',
          'amountVnd',
          'observedAt',
          'source',
        });
        expect(own.data().toString(), isNot(contains('uid-me')));

        // The user's own report is not part of the comparison
        final state = vm.stateFor(item, mine: mine);
        expect(state.status, SharedPriceStatus.ready);
        expect(state.summary!.count, 2);
        expect(state.summary!.medianVnd, 420000);
        expect(state.summary!.myDiffPercent, 10);
        expect(state.variantUnknown, isTrue);
      },
    );

    test('one other person is not enough', () async {
      await seed('other-1', 400000);
      await vm.load(item, mine: _mine(462000));
      expect(
        vm.stateFor(item, mine: _mine(462000)).status,
        SharedPriceStatus.notEnough,
      );
    });

    test('guests read but never share', () async {
      vm.updateUser('uid-guest', canContribute: false);
      await vm.load(item, mine: _mine(462000));
      await _settle();
      expect((await reports().get()).docs, isEmpty);
    });

    test(
      'turning sharing off removes the user\'s report and is remembered',
      () async {
        final mine = _mine(462000);
        await vm.load(item, mine: mine);
        await _settle();
        expect((await reports().get()).docs, hasLength(1));

        await vm.setSharingEnabled(false, item: item);
        expect((await reports().get()).docs, isEmpty);
        expect(await PreferencesService().getSharePricesEnabled(), isFalse);

        await vm.load(item, mine: mine, force: true);
        await _settle();
        expect((await reports().get()).docs, isEmpty);
      },
    );

    test('an item without a Shopee link has nothing to compare', () {
      final manual = WishlistItem(
        id: 'w2',
        title: 'Áo',
        createdAt: DateTime(2026, 11, 1),
      );
      expect(vm.stateFor(manual).status, SharedPriceStatus.unsupported);
    });

    testWidgets('the section shows the median and asks before using it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await seed('other-1', 400000);
        await seed('other-2', 440000);
      });
      int? used;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SharedPriceSection(
                  item: item,
                  onUsePrice: (amount) => used = amount,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Trung vị 420.000 ₫ · từ 2 người'),
        findsOneWidget,
      );
      expect(find.textContaining('chưa rõ phân loại'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('use-shared-price')));
      expect(used, 420000);
    });
  });
}
