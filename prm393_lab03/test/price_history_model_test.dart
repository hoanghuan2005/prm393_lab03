import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/services/firestore_paths.dart';

const _key = 'shopee:446089250:44081797761';

void main() {
  late FakeFirebaseFirestore db;
  late FirestorePaths paths;

  setUp(() {
    db = FakeFirebaseFirestore();
    paths = FirestorePaths(db);
  });

  test('paths', () {
    expect(paths.priceHistoryProduct(_key).path, 'priceHistory/$_key');
    expect(
      paths.priceHistoryReports(_key).doc('r1').path,
      'priceHistory/$_key/reports/r1',
    );
    expect(paths.productGroup('g1').path, 'productGroups/g1');
  });

  test('only afterVoucher is not a list price', () {
    for (final t in HistoryPriceType.values) {
      expect(t.countsAsListPrice, t != HistoryPriceType.afterVoucher);
    }
    expect(HistoryPriceType.fromKey('sale'), HistoryPriceType.sale);
    expect(HistoryPriceType.fromKey('coupon'), HistoryPriceType.single);
  });

  test('product round trip', () async {
    final p = PriceHistoryProduct(
      productKey: _key,
      title: 'Tai nghe',
      shopId: '446089250',
      itemId: '44081797761',
      shopName: 'Shop mẫu',
      groupId: 'g1',
      isDemo: true,
      createdAt: DateTime(2026, 11, 1),
    );
    await paths.priceHistoryProduct(_key).set(p.toMap());
    final back = PriceHistoryProduct.fromFirestore(
      await paths.priceHistoryProduct(_key).get(),
    );
    expect(back.productKey, _key);
    expect(back.title, 'Tai nghe');
    expect(back.groupId, 'g1');
    expect(back.isDemo, isTrue);
    expect(back.createdAt, DateTime(2026, 11, 1));
    expect(back.productCode, isNull);
    expect(back.productCodeSource, isNull);
    expect(back.variantCodes, isEmpty);
    // No code fields written when there is no code
    expect(p.toMap().keys, isNot(contains('variantCodes')));
    expect(p.toMap().keys, isNot(contains('productCode')));
  });

  test('product codes round trip', () async {
    final p = PriceHistoryProduct(
      productKey: _key,
      title: 'Tai nghe K-Sound A3',
      shopId: '446089250',
      itemId: '44081797761',
      shopName: 'Shop',
      createdAt: DateTime(2026, 11, 1),
      productCode: 'ksound-a3',
      productCodeSource: ProductCodeSource.ai,
      variantCodes: const {'123': 'den-nham', 'none': 'xanh'},
    );
    final map = p.toMap();
    expect(map['productCode'], 'ksound-a3');
    expect(map['productCodeSource'], 'ai');
    expect(map['variantCodes'], {'123': 'den-nham', 'none': 'xanh'});

    await paths.priceHistoryProduct(_key).set(map);
    final back = PriceHistoryProduct.fromFirestore(
      await paths.priceHistoryProduct(_key).get(),
    );
    expect(back.productCode, 'ksound-a3');
    expect(back.productCodeSource, ProductCodeSource.ai);
    expect(back.variantCodes, {'123': 'den-nham', 'none': 'xanh'});
  });

  test('unknown code source and malformed variant codes are ignored', () async {
    await paths.priceHistoryProduct(_key).set({
      'title': 'Tai nghe',
      'productCode': 'ksound-a3',
      'productCodeSource': 'guess',
      'variantCodes': {'123': 'den', '456': 7, '789': ''},
    });
    final back = PriceHistoryProduct.fromFirestore(
      await paths.priceHistoryProduct(_key).get(),
    );
    expect(back.productCodeSource, isNull);
    expect(back.variantCodes, {'123': 'den'});
    expect(ProductCodeSource.fromKey('admin'), ProductCodeSource.admin);
    expect(ProductCodeSource.fromKey('demo'), ProductCodeSource.demo);

    await paths.priceHistoryProduct(_key).update({'variantCodes': 'den'});
    final noMap = PriceHistoryProduct.fromFirestore(
      await paths.priceHistoryProduct(_key).get(),
    );
    expect(noMap.variantCodes, isEmpty);
  });

  test('report reads num money and rounds ratings to 1 decimal', () async {
    final ref = paths.priceHistoryReports(_key).doc('demo1_none_20261101');
    await ref.set({
      'amountVnd': 420000.0,
      'priceType': 'afterVoucher',
      'modelKey': 'none',
      'observedAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      'source': 'demo',
      'productRating': 4.86,
      'productRatingCount': 120.0,
      'shopRating': 5,
    });
    final r = PriceHistoryReport.fromFirestore(await ref.get());
    expect(r.amountVnd, 420000);
    expect(r.priceType, HistoryPriceType.afterVoucher);
    expect(r.countsAsListPrice, isFalse);
    expect(r.isDemo, isTrue);
    expect(r.productRating, 4.9);
    expect(r.productRatingCount, 120);
    expect(r.shopRating, 5.0);
    expect(r.shopName, isNull);
  });

  test('report drops out-of-range ratings', () async {
    final ref = paths.priceHistoryReports(_key).doc('x');
    await ref.set({
      'amountVnd': 1000,
      'observedAt': Timestamp.now(),
      'productRating': 6,
      'shopRating': 0,
      'productRatingCount': -1,
    });
    final r = PriceHistoryReport.fromFirestore(await ref.get());
    expect(r.productRating, isNull);
    expect(r.shopRating, isNull);
    expect(r.productRatingCount, isNull);
    expect(r.modelKey, 'none');
    expect(r.source, HistoryReportSource.manual);
  });

  test('report toMap omits null optionals', () {
    final r = PriceHistoryReport(
      id: 'r',
      amountVnd: 1000,
      priceType: HistoryPriceType.sale,
      observedAt: DateTime(2026, 11, 1),
    );
    expect(r.toMap().keys.toSet(), {
      'amountVnd',
      'priceType',
      'modelKey',
      'observedAt',
      'source',
    });
    expect(r.toMap()['priceType'], 'sale');
  });

  test('group round trip', () async {
    const g = ProductGroup(
      id: 'g1',
      name: 'Tai nghe',
      productKeys: [_key],
      isDemo: true,
    );
    await paths.productGroup('g1').set(g.toMap());
    final back = ProductGroup.fromFirestore(
      await paths.productGroup('g1').get(),
    );
    expect(back.productKeys, [_key]);
    expect(back.isDemo, isTrue);
  });
}
