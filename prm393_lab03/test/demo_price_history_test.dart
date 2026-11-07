import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/price_history_ids.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/same_product.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/demo_price_history_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/price_history_demo_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_history_demo_section.dart';
import 'package:provider/provider.dart';

/// 2026-11-06 12:00 in Vietnam
final _now = DateTime.utc(2026, 11, 6, 5);

final _reportPath = RegExp(
  r'^priceHistory/(shopee:(\d+):(\d+))/reports/(demo[0-9]{1,6}_(?:none|[0-9]{1,20})_[0-9]{8})$',
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

    test(
      '8 groups of 3–4 shops (28 products) + 3 others, under 5,000 writes',
      () {
        expect(groups, hasLength(8));
        expect(products, hasLength(31));
        expect(products.where((p) => p.data['groupId'] != null), hasLength(28));
        for (final g in groups) {
          final keys = g.data['productKeys'] as List;
          expect(keys.length, inInclusiveRange(3, 4));
          expect(g.data['isDemo'], isTrue);
        }
        expect(docs.length, lessThanOrEqualTo(5000));
        expect(reports.length, greaterThan(3500));
      },
    );

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
        // The trap and the 2 vague products are in no group
        if (d['groupId'] != null) {
          expect(d['groupId'], startsWith('demo-group-'));
        }
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
      const productDays =
          28 * DemoPriceHistoryData.days + 3 * DemoPriceHistoryData.extraDays;
      final emptyShare = 1 - perDay.length / productDays;
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

    /// List prices (not afterVoucher) of each product and Vietnamese day, sorted
    Map<String, Map<DateTime, List<int>>> listPricesByDay() {
      final byDay = <String, Map<DateTime, List<int>>>{};
      for (final r in reports.where((r) => r.type != 'afterVoucher')) {
        final vn = r.observedAt.toUtc().add(PriceHistoryIds.vietnamOffset);
        ((byDay[r.productKey] ??= {})[DateTime.utc(
                  vn.year,
                  vn.month,
                  vn.day,
                )] ??=
                [])
            .add(r.amount);
      }
      for (final days in byDay.values) {
        for (final prices in days.values) {
          prices.sort();
        }
      }
      return byDay;
    }

    /// (first, last) index of the largest run of [sorted] within 1% of its first
    (int, int) samePrice(List<int> sorted) {
      var best = (0, 0);
      for (var j = 0; j < sorted.length; j++) {
        var k = j;
        while (k + 1 < sorted.length && sorted[k + 1] <= sorted[j] * 1.01) {
          k++;
        }
        if (k - j > best.$2 - best.$1) best = (j, k);
      }
      return best;
    }

    test('same day, same shop: list prices within 1%, except ~5% far-off '
        'reports for the 30% filter', () {
      var total = 0;
      var far = 0;
      for (final days in listPricesByDay().values) {
        for (final prices in days.values) {
          final (first, last) = samePrice(prices);
          final ref = prices[first];
          for (var j = 0; j < prices.length; j++) {
            total++;
            if (j >= first && j <= last) continue;
            far++;
            expect((prices[j] - ref).abs(), greaterThan(ref * 0.3));
          }
        }
      }
      expect(far / total, inInclusiveRange(0.02, 0.09));
    });

    test('a shop\'s price holds for days: it changes on few of them', () {
      var pairs = 0;
      var changes = 0;
      for (final days in listPricesByDay().values) {
        final price = {
          for (final MapEntry(:key, :value) in days.entries)
            key: value[samePrice(value).$1],
        };
        for (final MapEntry(key: day, value: p) in price.entries) {
          final next = day.add(const Duration(days: 1));
          final q = price[next];
          if (q == null || _isPatternSale(day) || _isPatternSale(next)) {
            continue;
          }
          pairs++;
          if ((q - p).abs() > p * 0.01) changes++;
        }
      }
      expect(pairs, greaterThan(500));
      // Daily random prices would change on ~80% of the days
      expect(changes / pairs, inInclusiveRange(0.03, 0.25));
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

    group('G8 product and variant codes (set here, no AI)', () {
      final codePattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      String keyOf(DemoDoc p) => p.path.split('/').last;
      List<Map<String, dynamic>> membersOf(DemoDoc g) {
        final keys = (g.data['productKeys'] as List).cast<String>();
        return [
          for (final p in products)
            if (keys.contains(keyOf(p))) p.data,
        ];
      }

      Map<String, String> variantsOf(Map<String, dynamic> product) =>
          (product['variantCodes'] as Map?)?.cast<String, String>() ?? {};

      test('a group shares one productCode (demo) under different titles', () {
        final codes = <String>{};
        for (final g in groups) {
          final members = membersOf(g);
          final groupCodes = {for (final m in members) m['productCode']};
          expect(groupCodes, hasLength(1), reason: g.path);
          final code = groupCodes.single as String;
          expect(code, matches(codePattern));
          expect(code.length, lessThanOrEqualTo(60));
          expect(codes.add(code), isTrue, reason: 'one code per group');
          for (final m in members) {
            expect(m['productCodeSource'], 'demo');
          }
          // Each shop writes the title its own way
          expect({
            for (final m in members) m['title'],
          }, hasLength(members.length));
        }
        expect(codes, contains('sonora-air-2'));
        expect(codes, contains('ha-vy-spf50-50ml'));
      });

      test('1–2 variants per product, of the group\'s two, each sold by '
          '2+ shops', () {
        final modelKeys = <String>{};
        for (final g in groups) {
          final members = membersOf(g);
          final perCode = <String, int>{};
          for (final m in members) {
            final variants = variantsOf(m);
            expect(variants.length, inInclusiveRange(1, 2), reason: g.path);
            for (final e in variants.entries) {
              expect(e.key, matches(RegExp(r'^[0-9]{1,20}$')));
              expect(modelKeys.add(e.key), isTrue, reason: 'unique modelKey');
              expect(e.value, matches(codePattern));
              expect(e.value.length, lessThanOrEqualTo(30));
              perCode.update(e.value, (n) => n + 1, ifAbsent: () => 1);
            }
          }
          expect(perCode, hasLength(2), reason: g.path);
          expect(perCode.values.every((n) => n >= 2), isTrue, reason: g.path);
        }
      });

      test('every report is for one of its product\'s variants', () {
        final variantsByKey = {
          for (final p in products) keyOf(p): variantsOf(p.data).keys.toSet(),
        };
        for (final r in reports) {
          final variants = variantsByKey[r.productKey]!;
          final modelKey = r.data['modelKey'] as String;
          if (variants.isEmpty) {
            expect(modelKey, DemoPriceHistoryData.modelKey);
          } else {
            expect(variants, contains(modelKey));
          }
          expect(r.id, startsWith('demo'));
          expect(r.id, contains('_${modelKey}_'));
        }
      });

      test(
        'outside the groups: a "Pro" trap and 2 products without a code',
        () {
          final others = [
            for (final p in products)
              if (p.data['groupId'] == null) p.data,
          ];
          expect(others, hasLength(3));
          final trap = others.singleWhere((p) => p['productCode'] != null);
          expect(trap['productCode'], 'sonora-air-2-pro');
          expect(trap['productCodeSource'], 'demo');
          expect(variantsOf(trap), hasLength(2));
          // Same brand and model name as group 1, but another item
          final group1 = membersOf(groups.first).first['productCode'];
          expect(group1, 'sonora-air-2');
          expect(trap['productCode'], isNot(group1));

          final vague = others.where((p) => p['productCode'] == null).toList();
          expect(vague, hasLength(2));
          for (final p in vague) {
            expect(p.containsKey('productCodeSource'), isFalse);
            expect(p.containsKey('variantCodes'), isFalse);
          }
          // Only the last 30 days of reports
          final since = _now.subtract(
            const Duration(days: DemoPriceHistoryData.extraDays + 1),
          );
          final extraKeys = {
            for (final p in products)
              if (p.data['groupId'] == null) keyOf(p),
          };
          final extraReports = reports.where(
            (r) => extraKeys.contains(r.productKey),
          );
          expect(extraReports, isNotEmpty);
          expect(
            extraReports.every((r) => r.observedAt.isAfter(since)),
            isTrue,
          );
        },
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

    group('G2c sample items in my wishlist', () {
      Future<List<WishlistItem>> items() async => [
        for (final d
            in (await db.collection('users/ada/wishlistItems').get()).docs)
          WishlistItem.fromFirestore(d),
      ];

      test('3 coded items from 3 groups, 1 without a code; added once', () async {
        await service.seed();
        expect(await service.addDemoItemsToMyWishlist('ada'), 4);

        final added = await items();
        expect(added, hasLength(4));
        final groups = <String?>{};
        var uncoded = 0;
        for (final item in added) {
          expect(item.isDemo, isTrue);
          expect(item.latestPriceVnd, greaterThan(0));
          expect(item.url, startsWith('https://shopee.vn/product/'));
          final product = PriceHistoryProduct.fromFirestore(
            await db.doc('priceHistory/${item.productKey}').get(),
          );
          expect(product.isDemo, isTrue);
          expect(item.title, product.title);
          if (product.productCode == null) {
            uncoded++;
            expect(item.modelId, isNull);
          } else {
            groups.add(product.groupId);
            expect(product.variantCodes[item.modelId], isNotNull);
            expect(item.variantLabel, isNotNull);
          }
          final snapshots = await db
              .collection('users/ada/wishlistItems/${item.id}/priceSnapshots')
              .get();
          expect(snapshots.size, 1);
        }
        expect(uncoded, 1);
        expect(groups, hasLength(3));

        // Again: nothing new
        expect(await service.addDemoItemsToMyWishlist('ada'), 0);
        expect(await items(), hasLength(4));
      });

      test('the picks: 2+ other shops of the same variant in the last 7 days', () {
        final docs = DemoPriceHistoryData.generate(now: _now);
        final products = <String, PriceHistoryProduct>{};
        final reports = <String, List<PriceHistoryReport>>{};
        final groups = <ProductGroup>[];
        for (final d in docs) {
          final parts = d.path.split('/');
          if (parts.first == 'productGroups') {
            groups.add(
              ProductGroup(
                id: parts[1],
                name: d.data['name'] as String,
                productKeys: List<String>.from(d.data['productKeys'] as List),
                isDemo: true,
              ),
            );
          } else if (parts.length == 2) {
            products[parts[1]] = PriceHistoryProduct(
              productKey: parts[1],
              title: d.data['title'] as String,
              shopId: d.data['shopId'] as String,
              itemId: d.data['itemId'] as String,
              shopName: d.data['shopName'] as String,
              groupId: d.data['groupId'] as String?,
              isDemo: true,
              createdAt: _now,
              productCode: d.data['productCode'] as String?,
              variantCodes: Map<String, String>.from(
                (d.data['variantCodes'] as Map?) ?? const {},
              ),
            );
          } else {
            final r = _Report(parts[1], parts[3], d.data);
            (reports[r.productKey] ??= []).add(
              PriceHistoryReport(
                id: r.id,
                amountVnd: r.amount,
                priceType: HistoryPriceType.values.firstWhere(
                  (t) => t.key == r.type,
                ),
                modelKey: d.data['modelKey'] as String,
                observedAt: r.observedAt,
                source: HistoryReportSource.demo,
              ),
            );
          }
        }

        final picks = DemoWishlistPicker.pick(
          groups: groups,
          products: products,
          reports: reports,
          now: _now,
        );
        expect(picks, hasLength(4));
        for (final p in picks.take(3)) {
          final code = p.product.variantCodes[p.modelId]!;
          final others = {
            for (final o in products.values)
              if (o.productCode == p.product.productCode &&
                  o.shopId != p.product.shopId)
                o.productKey: o,
          };
          expect(
            pickLowestOffers(others, reports, code, _now).length,
            greaterThanOrEqualTo(DemoWishlistPicker.minOtherShops),
          );
        }
        expect(picks.last.product.productCode, isNull);
        expect(picks.last.modelId, isNull);
      });

      test('removing deletes only my sample items, their prices and decisions',
          () async {
        final real = await FirestoreWishlistService(
          db,
        ).add('ada', title: 'Món thật', priceVnd: 100000, coolingOffDays: 0);
        await service.seed();
        await service.addDemoItemsToMyWishlist('ada');
        final demo = (await items()).firstWhere((i) => i.isDemo);
        await db.collection('users/ada/decisions').add({
          'itemId': demo.id,
          'choice': 'wait',
        });
        await db.collection('users/ada/decisions').add({
          'itemId': real.id,
          'choice': 'wait',
        });

        expect(await service.removeDemoItemsFromMyWishlist('ada'), 4);

        expect((await items()).map((i) => i.id), [real.id]);
        expect(
          (await db
                  .collection('users/ada/wishlistItems/${demo.id}/priceSnapshots')
                  .get())
              .size,
          0,
        );
        expect(
          (await db
                  .collection('users/ada/wishlistItems/${real.id}/priceSnapshots')
                  .get())
              .size,
          1,
        );
        final decisions = await db.collection('users/ada/decisions').get();
        expect(decisions.docs.map((d) => d['itemId']), [real.id]);
      });
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

  List<ProductGroup> groups = const [];

  @override
  Future<List<ProductGroup>> demoGroups() async => groups;

  @override
  Future<int> addDemoItemsToMyWishlist(String uid) async => 0;

  @override
  Future<int> removeDemoItemsFromMyWishlist(String uid) async => 0;
}
