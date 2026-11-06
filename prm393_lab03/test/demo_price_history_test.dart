import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/price_history_ids.dart';
import 'package:prm393_lab03/services/demo_price_history_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/price_history_demo_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_history_demo_section.dart';
import 'package:provider/provider.dart';

/// 2026-11-06 12:00 in Vietnam
final _now = DateTime.utc(2026, 11, 6, 5);

final _reportPath = RegExp(
  r'^priceHistory/(shopee:(\d+):(\d+))/reports/(demo[0-9]{1,6}_none_[0-9]{8})$',
);

class _Report {
  final String productKey;
  final String id;
  final Map<String, dynamic> data;
  _Report(this.productKey, this.id, this.data);

  int get amount => data['amountVnd'] as int;
  String get type => data['priceType'] as String;
  DateTime get observedAt => (data['observedAt'] as Timestamp).toDate();
  String get day => PriceHistoryIds.dayKey(observedAt);
}

List<_Report> _reports(List<DemoDoc> docs) => [
  for (final d in docs)
    if (_reportPath.firstMatch(d.path) case final m?)
      _Report(m.group(1)!, m.group(4)!, d.data),
];

int _median(List<int> values) {
  final s = [...values]..sort();
  return s[s.length ~/ 2];
}

bool _isPatternSale(DateTime vnDate) =>
    vnDate.month == vnDate.day || vnDate.day == 15 || vnDate.day == 25;

void main() {
  group('DemoPriceHistoryData', () {
    final docs = DemoPriceHistoryData.generate(now: _now);
    final reports = _reports(docs);
    final products = docs
        .where((d) => RegExp(r'^priceHistory/[^/]+$').hasMatch(d.path))
        .toList();
    final groups = docs
        .where((d) => d.path.startsWith('productGroups/'))
        .toList();

    test('same seed and day give the same data', () {
      final again = DemoPriceHistoryData.generate(now: _now);
      expect(again.map((d) => d.path), docs.map((d) => d.path));
      expect(again.map((d) => d.data), docs.map((d) => d.data));
    });

    test('8 groups of 3–4 shops, 28 products, under 5,000 writes', () {
      expect(groups, hasLength(8));
      expect(products, hasLength(28));
      for (final g in groups) {
        final keys = g.data['productKeys'] as List;
        expect(keys.length, inInclusiveRange(3, 4));
        expect(g.data['isDemo'], isTrue);
      }
      expect(docs.length, lessThanOrEqualTo(5000));
      expect(reports.length, greaterThan(3500));
    });

    test('products fit the rules and use ids 9000000000–9000999999', () {
      for (final p in products) {
        final d = p.data;
        expect(d['isDemo'], isTrue);
        expect((d['title'] as String).length, inInclusiveRange(1, 120));
        expect((d['shopName'] as String).length, inInclusiveRange(1, 60));
        for (final id in [d['shopId'], d['itemId']]) {
          expect(
            int.parse(id as String),
            inInclusiveRange(9000000000, 9000999999),
          );
        }
        expect(p.path, 'priceHistory/shopee:${d['shopId']}:${d['itemId']}');
        expect(d['groupId'], startsWith('demo-group-'));
      }
      // Every shop names the same item a little differently
      for (final g in groups) {
        final titles = {
          for (final p in products)
            if ((g.data['productKeys'] as List).contains(
              p.path.split('/').last,
            ))
              p.data['title'],
        };
        expect(titles.length, (g.data['productKeys'] as List).length);
      }
    });

    test('reports fit the rules: id, money, type, ratings, time', () {
      final since = _now.subtract(const Duration(days: 90));
      for (final r in reports) {
        final d = r.data;
        expect(
          d.keys.toSet().difference({
            'amountVnd',
            'priceType',
            'modelKey',
            'observedAt',
            'source',
            'shopName',
            'productRating',
            'productRatingCount',
            'shopRating',
          }),
          isEmpty,
        );
        expect(d['source'], 'demo');
        expect(r.amount, inInclusiveRange(1000, 999999999));
        expect(r.amount % 1000, 0);
        expect(
          r.type,
          isIn(['single', 'range', 'flash', 'sale', 'afterVoucher']),
        );
        expect(r.id, endsWith('_${r.day}'));
        expect(r.observedAt.isAfter(_now), isFalse);
        expect(r.observedAt.isAfter(since), isTrue);
        for (final f in ['productRating', 'shopRating']) {
          if (d[f] != null) {
            expect(d[f] as double, inExclusiveRange(0, 5.0001));
            expect(((d[f] as double) * 10).round() / 10, d[f]);
          }
        }
        if (d['productRatingCount'] != null) {
          expect(d['productRatingCount'] as int, greaterThanOrEqualTo(0));
        }
      }
    });

    test('0–6 reports a day, ~40% of product-days empty', () {
      final perDay = <String, int>{};
      for (final r in reports) {
        perDay.update(
          '${r.productKey}|${r.day}',
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
      expect(perDay.values.every((n) => n >= 1 && n <= 6), isTrue);
      final emptyShare = 1 - perDay.length / (28 * 90);
      expect(emptyShare, inInclusiveRange(0.33, 0.47));
    });

    test('sale and flash only on sale days; base prices 50k–3M', () {
      for (final r in reports) {
        final vn = r.observedAt.toUtc().add(PriceHistoryIds.vietnamOffset);
        if (r.type == 'sale' || r.type == 'flash') {
          expect(_isPatternSale(vn), isTrue, reason: r.id);
        }
      }
      final byProduct = <String, List<int>>{};
      for (final r in reports.where((r) => r.type == 'single')) {
        (byProduct[r.productKey] ??= []).add(r.amount);
      }
      for (final prices in byProduct.values) {
        expect(_median(prices), inInclusiveRange(50000, 3300000));
      }
    });

    test('~5% afterVoucher, 5–15% under the same day\'s price', () {
      final av = reports.where((r) => r.type == 'afterVoucher').toList();
      expect(av.length / reports.length, inInclusiveRange(0.03, 0.08));
      final byDay = <String, List<_Report>>{};
      for (final r in reports) {
        (byDay['${r.productKey}|${r.day}'] ??= []).add(r);
      }
      var compared = 0;
      var lower = 0;
      for (final r in av) {
        final others = [
          for (final o in byDay['${r.productKey}|${r.day}']!)
            if (o.type != 'afterVoucher') o.amount,
        ];
        if (others.length < 3) continue;
        compared++;
        if (r.amount < _median(others)) lower++;
      }
      expect(compared, greaterThan(20));
      expect(lower / compared, greaterThanOrEqualTo(0.9));
    });

    test('some range reports and ~5% outliers (>30% from the day median)', () {
      expect(reports.where((r) => r.type == 'range'), isNotEmpty);
      final byDay = <String, List<int>>{};
      for (final r in reports.where((r) => r.type != 'afterVoucher')) {
        (byDay['${r.productKey}|${r.day}'] ??= []).add(r.amount);
      }
      var total = 0;
      var outliers = 0;
      for (final prices in byDay.values.where((p) => p.length >= 3)) {
        final m = _median(prices);
        for (final p in prices) {
          total++;
          if ((p - m).abs() > m * 0.3) outliers++;
        }
      }
      expect(outliers / total, inInclusiveRange(0.02, 0.09));
    });

    test('~15% reports without ratings; rating count grows', () {
      final unrated = reports.where((r) => r.data['productRating'] == null);
      expect(unrated.length / reports.length, inInclusiveRange(0.1, 0.2));
      final first = <String, int>{};
      final last = <String, int>{};
      for (final r in reports) {
        final c = r.data['productRatingCount'] as int?;
        if (c == null) continue;
        first.putIfAbsent(r.productKey, () => c);
        last[r.productKey] = c;
      }
      for (final k in first.keys) {
        expect(last[k]!, greaterThan(first[k]!));
      }
    });

    test('the cheapest shop is not always the best rated', () {
      var cheapestNotBest = 0;
      for (final g in groups) {
        final keys = (g.data['productKeys'] as List).cast<String>();
        final price = <String, int>{};
        final rating = <String, double>{};
        for (final k in keys) {
          final mine = reports.where(
            (r) => r.productKey == k && r.type == 'single',
          );
          price[k] = _median([for (final r in mine) r.amount]);
          final rated = [
            for (final r in reports.where((r) => r.productKey == k))
              if (r.data['productRating'] case final double v) v,
          ];
          rating[k] = rated.reduce((a, b) => a + b) / rated.length;
        }
        final cheapest = keys.reduce((a, b) => price[a]! <= price[b]! ? a : b);
        final best = rating.values.reduce((a, b) => a > b ? a : b);
        if (rating[cheapest]! < best) cheapestNotBest++;
      }
      expect(cheapestNotBest, greaterThanOrEqualTo(4));
    });

    test('2–3 listings rise in the 5 days before a sale', () {
      var fake = 0;
      for (final p in products) {
        final key = p.path.split('/').last;
        final normal = <int>[];
        final beforeSale = <int>[];
        for (final r in reports.where(
          (r) => r.productKey == key && r.type == 'single',
        )) {
          final vn = r.observedAt.toUtc().add(PriceHistoryIds.vietnamOffset);
          final soon = [for (var k = 1; k <= 5; k++) vn.add(Duration(days: k))]
              .any(_isPatternSale);
          (soon ? beforeSale : normal).add(r.amount);
        }
        if (_median(beforeSale) > _median(normal) * 1.1) fake++;
      }
      expect(fake, inInclusiveRange(2, 3));
    });

    test('published sale events count as sale days', () {
      // 2026-10-20 is not a double day, 15th or 25th
      final withEvent = DemoPriceHistoryData.generate(
        now: _now,
        saleDays: {'20261020'},
      );
      final types = {
        for (final r in _reports(withEvent))
          if (r.day == '20261020') r.type,
      };
      expect(types.intersection({'sale', 'flash'}), isNotEmpty);
      expect(
        reports.where(
          (r) => r.day == '20261020' && (r.type == 'sale' || r.type == 'flash'),
        ),
        isEmpty,
      );
    });
  });

  group('FirestoreDemoPriceHistoryService', () {
    late FakeFirebaseFirestore db;
    late FirestoreDemoPriceHistoryService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = FirestoreDemoPriceHistoryService(db, () => _now);
    });

    Future<int> countDemo() async {
      final products = await db
          .collection('priceHistory')
          .where('isDemo', isEqualTo: true)
          .get();
      var n = products.size;
      for (final p in products.docs) {
        n += (await p.reference.collection('reports').get()).size;
      }
      n +=
          (await db
                  .collection('productGroups')
                  .where('isDemo', isEqualTo: true)
                  .get())
              .size;
      return n;
    }

    test('seed writes every document in batches of at most 450', () async {
      final expected = DemoPriceHistoryData.generate(now: _now).length;
      final steps = <(int, int)>[];
      final written = await service.seed(
        onProgress: (done, total) => steps.add((done, total)),
      );

      expect(written, expected);
      expect(await countDemo(), expected);
      expect(steps.last, (expected, expected));
      for (var i = 1; i < steps.length; i++) {
        if (steps[i].$2 == steps[i - 1].$2) {
          expect(steps[i].$1 - steps[i - 1].$1, lessThanOrEqualTo(450));
        }
      }
    });

    test('seeding twice never duplicates', () async {
      final first = await service.seed();
      await service.seed();
      expect(await countDemo(), first);
    });

    test('clearDemo deletes sample documents only', () async {
      const realKey = 'shopee:1:2';
      await db.doc('priceHistory/$realKey').set({
        'title': 'x',
        'isDemo': false,
      });
      await db.doc('priceHistory/$realKey/reports/r1').set({
        'amountVnd': 1000,
        'source': 'manual',
      });
      await db.doc('productGroups/real').set({'name': 'x', 'isDemo': false});
      await db.doc('sharedPrices/$realKey/reports/r1').set({'amountVnd': 1000});
      final written = await service.seed();

      final deleted = await service.clearDemo();

      expect(deleted, written);
      expect(await countDemo(), 0);
      expect((await db.doc('priceHistory/$realKey').get()).exists, isTrue);
      expect(
        (await db.doc('priceHistory/$realKey/reports/r1').get()).exists,
        isTrue,
      );
      expect((await db.doc('productGroups/real').get()).exists, isTrue);
      expect(
        (await db.doc('sharedPrices/$realKey/reports/r1').get()).exists,
        isTrue,
      );
    });

    test('reads published sale events', () async {
      await db.collection('saleEvents').add({
        'name': 'Sale giữa tháng',
        'date': Timestamp.fromDate(DateTime.utc(2026, 10, 20, 5)),
        'status': 'published',
      });
      await db.collection('saleEvents').add({
        'name': 'Nháp',
        'date': Timestamp.fromDate(DateTime.utc(2026, 10, 21, 5)),
        'status': 'draft',
      });
      await service.seed();

      final types = <String>{};
      final drafts = <String>{};
      for (final p in (await db.collection('priceHistory').get()).docs) {
        for (final r in (await p.reference.collection('reports').get()).docs) {
          if (r.id.endsWith('_20261020')) types.add(r['priceType'] as String);
          if (r.id.endsWith('_20261021')) drafts.add(r['priceType'] as String);
        }
      }
      expect(types.intersection({'sale', 'flash'}), isNotEmpty);
      expect(drafts.intersection({'sale', 'flash'}), isEmpty);
    });
  });

  group('PriceHistoryDemoSection', () {
    late _FakeUserService users;
    late _FakeDemoService demo;
    late PriceHistoryDemoViewModel vm;

    setUp(() {
      users = _FakeUserService();
      demo = _FakeDemoService();
      vm = PriceHistoryDemoViewModel(demoService: demo, userService: users)
        ..updateUid('ada');
    });
    tearDown(() {
      vm.dispose();
      users.roles.close();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: PriceHistoryDemoSection()),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('hidden for users and staff', (tester) async {
      await pump(tester);
      users.roles.add('user');
      await tester.pump();
      expect(find.text('Tạo dữ liệu giá mẫu'), findsNothing);

      users.roles.add('staff');
      await tester.pump();
      expect(find.text('Xoá dữ liệu giá mẫu'), findsNothing);
    });

    testWidgets('admin: confirm, progress, then the document count', (
      tester,
    ) async {
      await pump(tester);
      users.roles.add('admin');
      await tester.pump();

      await tester.tap(find.text('Tạo dữ liệu giá mẫu'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo dữ liệu giá mẫu?'), findsOneWidget);
      await tester.tap(find.text('Tạo'));
      await tester.pump();

      demo.progress!(450, 900);
      await tester.pump();
      expect(find.byKey(const ValueKey('price-demo-progress')), findsOneWidget);
      expect(find.text('Đang xử lý 450/900 document…'), findsOneWidget);

      demo.result!.complete(900);
      await tester.pumpAndSettle();
      expect(find.text('Đã ghi 900 document giá mẫu.'), findsOneWidget);
    });

    testWidgets('admin: cancelling the dialog deletes nothing', (tester) async {
      await pump(tester);
      users.roles.add('admin');
      await tester.pump();

      await tester.tap(find.text('Xoá dữ liệu giá mẫu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(demo.clearCalls, 0);
    });
  });
}

class _FakeUserService extends Fake implements UserService {
  // sync: setUp runs outside the widget test's fake async zone
  final roles = StreamController<String>.broadcast(sync: true);

  @override
  Stream<String> watchRole(String uid) => roles.stream;
}

class _FakeDemoService implements DemoPriceHistoryService {
  DemoProgress? progress;

  /// Created when seed() runs, inside the widget test's zone
  Completer<int>? result;
  int clearCalls = 0;

  @override
  Future<int> seed({DemoProgress? onProgress}) {
    progress = onProgress;
    return (result = Completer<int>()).future;
  }

  @override
  Future<int> clearDemo({DemoProgress? onProgress}) async {
    clearCalls++;
    return 0;
  }
}
