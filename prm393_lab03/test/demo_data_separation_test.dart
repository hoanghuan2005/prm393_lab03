import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/shared_price.dart';
import 'package:prm393_lab03/services/shared_price_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/widgets/demo_data_badge.dart';

import 'support/test_theme.dart';

const _key = 'shopee:446089250:44081797761';

void main() {
  test('"Giá người khác ghi" never counts demo reports', () async {
    final db = FakeFirebaseFirestore();
    final now = DateTime.now();
    Map<String, Object> report(int amount, {String source = 'manual'}) => {
      'modelKey': 'none',
      'priceType': 'single',
      'amountVnd': amount,
      'observedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'source': source,
    };
    final reports = db.collection('sharedPrices/$_key/reports');
    await reports.doc('a').set(report(420000));
    await reports.doc('b').set(report(430000, source: 'extensionPage'));
    await reports.doc('demo1').set(report(100000, source: 'demo'));
    await reports.doc('demo2').set(report(110000, source: 'demo'));

    final read = await FirestoreSharedPriceService(db).reportsFor(_key, 'none');

    expect(read.keys, unorderedEquals(['a', 'b']));
    final summary = SharedPriceSummary.summarize(
      read.values.toList(),
      priceType: PriceType.single,
      now: now,
    )!;
    expect(summary.count, 2);
    expect(summary.minVnd, 420000);
  });

  test('sample products have no Shopee link', () {
    PriceHistoryProduct product({required bool isDemo}) => PriceHistoryProduct(
      productKey: _key,
      title: 'Tai nghe',
      shopId: '446089250',
      itemId: '44081797761',
      shopName: 'Shop',
      isDemo: isDemo,
      createdAt: DateTime(2026, 11, 1),
    );

    expect(product(isDemo: true).shopeeUrl, isNull);
    expect(
      product(isDemo: false).shopeeUrl,
      'https://shopee.vn/product/446089250/44081797761',
    );
  });

  for (final (name, theme) in [
    ('light', testAppTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets('DemoDataBadge uses the $name theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Center(child: DemoDataBadge())),
        ),
      );

      expect(find.text('Dữ liệu mẫu'), findsOneWidget);
      expect(find.bySemanticsLabel('Dữ liệu mẫu'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Dữ liệu mẫu'));
      expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
      final box = tester.widget<Container>(
        find.ancestor(of: find.byType(Row), matching: find.byType(Container)),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        theme.colorScheme.surfaceContainerHighest,
      );
    });
  }
}
