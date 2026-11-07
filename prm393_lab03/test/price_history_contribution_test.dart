import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/price_history_ids.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/price_history_contribution.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/price_history_contribution_service.dart';
import 'package:prm393_lab03/services/shared_price_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/shared_price_viewmodel.dart';
import 'package:prm393_lab03/widgets/shared_price_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 12:00 in Vietnam
final _now = DateTime.utc(2026, 11, 5, 5);
const _key = 'shopee:446089250:44081797761';

final _item = WishlistItem(
  id: 'w1',
  title: 'Tai nghe Sonora Air 2',
  url: 'https://shopee.vn/product/446089250/44081797761',
  productKey: _key,
  modelId: '123',
  shopName: 'Nhà Tai Nghe Mây',
  productRating: 4.8,
  productRatingCount: 120,
  shopRating: 4.9,
  latestPriceVnd: 420000,
  createdAt: DateTime.utc(2026, 11, 1),
);

PriceSnapshot _s(
  int amount, {
  Duration ago = const Duration(hours: 1),
  PriceType type = PriceType.single,
  PriceSource source = PriceSource.extensionPage,
  bool confirmed = true,
  String? shopName,
  double? productRating,
}) => PriceSnapshot(
  id: 's$amount',
  amountVnd: amount,
  observedAt: _now.subtract(ago),
  priceType: type,
  source: source,
  confirmed: confirmed,
  shopName: shopName,
  productRating: productRating,
);

void main() {
  group('Which prices are reported', () {
    List<PriceHistoryReport> reports(
      List<PriceSnapshot> s, [
      WishlistItem? item,
    ]) => HistoryContribution.reportsFor(item ?? _item, s, _now);

    test('confirmed app / extension prices of the last 3 days only', () {
      final r = reports([
        _s(410000, ago: const Duration(days: 1)),
        _s(400000, ago: const Duration(days: 2, hours: 20)),
        _s(380000, ago: const Duration(days: 3, hours: 1)),
        _s(390000, ago: const Duration(days: 2), confirmed: false),
        _s(370000, ago: const Duration(days: 2), source: PriceSource.demo),
        _s(360000, ago: const Duration(days: 2), source: PriceSource.community),
      ]);
      expect(r.map((e) => e.amountVnd), unorderedEquals([410000, 400000]));
    });

    test('afterVoucher is sent and keeps its type', () {
      final r = reports([_s(350000, type: PriceType.afterVoucher)]);
      expect(r.single.priceType, HistoryPriceType.afterVoucher);
      expect(r.single.priceType.countsAsListPrice, isFalse);
    });

    test('one report per day: the latest list price beats "sau voucher"', () {
      final r = reports([
        _s(430000, ago: const Duration(hours: 3)),
        _s(420000, ago: const Duration(hours: 2)),
        _s(350000, ago: const Duration(hours: 1), type: PriceType.afterVoucher),
      ]);
      expect(r.single.amountVnd, 420000);
      expect(r.single.priceType, HistoryPriceType.single);
    });

    test('source, variant, shop name and ratings; snapshot first', () {
      final r = reports([
        _s(
          420000,
          source: PriceSource.manual,
          shopName: 'Shop mới tên',
          productRating: 4.6,
        ),
      ]).single;
      expect(r.source, HistoryReportSource.manual);
      expect(r.modelKey, '123');
      expect(r.shopName, 'Shop mới tên');
      expect(r.productRating, 4.6);
      expect(r.productRatingCount, 120);
      expect(r.shopRating, 4.9);
    });

    test(
      'nothing without a Shopee productKey (a link alone is not enough)',
      () {
        final noKey = WishlistItem(
          id: 'w2',
          title: 'Tai nghe',
          url: 'https://shopee.vn/product/446089250/44081797761',
          createdAt: DateTime.utc(2026, 11, 1),
        );
        expect(reports([_s(420000)], noKey), isEmpty);
      },
    );

    test('a shop name longer than 60 characters is shortened', () {
      expect(HistoryContribution.shopNameOf('x' * 70), hasLength(60));
      expect(HistoryContribution.shopNameOf('  '), isNull);
    });
  });

  group('Firestore', () {
    late FakeFirebaseFirestore db;
    late FirestorePriceHistoryContributionService service;
    DocumentReference<Map<String, dynamic>> product() =>
        db.collection('priceHistory').doc(_key);
    CollectionReference<Map<String, dynamic>> reports() =>
        product().collection('reports');
    final report = HistoryContribution.reportsFor(_item, [
      _s(420000),
    ], _now).single;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = FirestorePriceHistoryContributionService(db);
    });

    Future<void> send({String? shopName = 'Nhà Tai Nghe Mây'}) =>
        service.contribute(
          uid: 'uid-me',
          productKey: _key,
          title: 'Tai nghe Sonora Air 2',
          shopName: shopName,
          report: report,
        );

    test(
      'creates the product and the hashed report, without any uid',
      () async {
        await send();

        final p = (await product().get()).data()!;
        expect(p['title'], 'Tai nghe Sonora Air 2');
        expect(p['shopId'], '446089250');
        expect(p['itemId'], '44081797761');
        expect(p['shopName'], 'Nhà Tai Nghe Mây');
        expect(p['isDemo'], isFalse);
        expect(p.containsKey('groupId'), isFalse);

        final id = PriceHistoryIds.userReportId(
          'uid-me',
          _key,
          '123',
          report.observedAt,
        );
        final r = (await reports().doc(id).get()).data()!;
        expect(r['amountVnd'], 420000);
        expect(r['source'], 'extensionPage');
        expect(r['modelKey'], '123');
        expect(r['shopName'], 'Nhà Tai Nghe Mây');
        expect(r['productRating'], 4.8);
        expect(r.toString(), isNot(contains('uid-me')));
        expect(r.keys, isNot(contains('url')));
      },
    );

    test(
      'the same day replaces the report; the product is left as it is',
      () async {
        await product().set({
          'title': 'Tên của người khác',
          'shopId': '446089250',
          'itemId': '44081797761',
          'shopName': 'Shop',
          'groupId': 'g1',
          'isDemo': false,
          'createdAt': Timestamp.fromDate(_now),
        });
        await send();
        await send();

        expect((await reports().get()).docs, hasLength(1));
        final p = (await product().get()).data()!;
        expect(p['title'], 'Tên của người khác');
        expect(p['shopName'], 'Shop');
        expect(p['groupId'], 'g1');
      },
    );

    test('never written into sample data', () async {
      await product().set({'title': 'Mẫu', 'isDemo': true});
      await send();
      expect((await reports().get()).docs, isEmpty);
    });

    test(
      'without a shop name: the product is still created, filled later',
      () async {
        await send(shopName: null);
        expect((await product().get()).data()!.containsKey('shopName'), false);
        expect((await reports().get()).docs, hasLength(1));

        await send();
        expect((await product().get()).data()!['shopName'], 'Nhà Tai Nghe Mây');
      },
    );
  });

  group('View model', () {
    late _History history;
    late SharedPriceViewModel vm;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      history = _History();
      vm = SharedPriceViewModel(
        service: FirestoreSharedPriceService(FakeFirebaseFirestore()),
        preferencesService: PreferencesService(),
        historyService: history,
        now: () => _now,
      )..updateUser('uid-me', canContribute: true);
    });

    tearDown(() => vm.dispose());

    test('sends each fresh price once', () async {
      final snapshots = [_s(420000), _s(410000, ago: const Duration(days: 1))];
      await vm.reportHistory(_item, snapshots);
      await vm.reportHistory(_item, snapshots);
      expect(history.sent.map((s) => s.$2.amountVnd), [420000, 410000]);
      expect(history.sent.first.$1, 'uid-me');

      // A new price of the same day replaces it
      await vm.reportHistory(_item, [
        _s(415000, ago: Duration.zero),
        ...snapshots,
      ]);
      expect(history.sent.last.$2.amountVnd, 415000);
    });

    test('guests send nothing', () async {
      vm.updateUser('uid-guest', canContribute: false);
      await vm.reportHistory(_item, [_s(420000)]);
      expect(history.sent, isEmpty);
    });

    test('sharing off ("Góp giá của tôi") sends nothing', () async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService().setSharePricesEnabled(false);
      final off = SharedPriceViewModel(
        service: FirestoreSharedPriceService(FakeFirebaseFirestore()),
        preferencesService: PreferencesService(),
        historyService: history,
        now: () => _now,
      )..updateUser('uid-me', canContribute: true);
      addTearDown(off.dispose);
      // Right away, before the preference has been read
      await off.reportHistory(_item, [_s(420000)]);
      expect(history.sent, isEmpty);
    });

    test('a failed send is tried again next time', () async {
      history.fail = true;
      await vm.reportHistory(_item, [_s(420000)]);
      history.fail = false;
      await vm.reportHistory(_item, [_s(420000)]);
      expect(history.sent, hasLength(1));
    });
  });

  group('Chi tiết món', () {
    Future<void> wait(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the price is sent once however often the section redraws; '
        'the switch off stops the next one', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final history = _History();
      final decision = _Decision([_s(420000)]);
      final vm = SharedPriceViewModel(
        service: FirestoreSharedPriceService(FakeFirebaseFirestore()),
        preferencesService: PreferencesService(),
        historyService: history,
        now: () => _now,
      )..updateUser('uid-me', canContribute: true);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DecisionSupportViewModel>.value(
              value: decision,
            ),
            ChangeNotifierProvider<SharedPriceViewModel>.value(value: vm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SharedPriceSection(item: _item),
              ),
            ),
          ),
        ),
      );
      await wait(tester);
      for (var i = 0; i < 3; i++) {
        decision.redraw();
        await wait(tester);
      }
      expect(history.sent, hasLength(1));
      expect(history.sent.single.$2.amountVnd, 420000);

      await tester.tap(find.byKey(const ValueKey('share-prices-switch')));
      await wait(tester);
      expect(vm.sharingEnabled, isFalse);

      decision.redraw([_s(410000, ago: Duration.zero), _s(420000)]);
      await wait(tester);
      expect(history.sent, hasLength(1));
    });
  });
}

/// Lịch sử giá of [_item] only
class _Decision extends ChangeNotifier implements DecisionSupportViewModel {
  List<PriceSnapshot> snapshots;

  _Decision(this.snapshots);

  void redraw([List<PriceSnapshot>? next]) {
    if (next != null) snapshots = next;
    notifyListeners();
  }

  @override
  PriceInsights? priceInsightsFor(WishlistItem item) =>
      PriceInsights(snapshots, now: _now);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _History implements PriceHistoryContributionService {
  final sent = <(String, PriceHistoryReport)>[];
  bool fail = false;

  @override
  Future<void> contribute({
    required String uid,
    required String productKey,
    required String title,
    String? shopName,
    required PriceHistoryReport report,
  }) async {
    if (fail) throw StateError('offline');
    sent.add((uid, report));
  }
}
