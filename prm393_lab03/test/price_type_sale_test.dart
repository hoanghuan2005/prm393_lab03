import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/shared_price.dart';

final _now = DateTime(2026, 11, 6, 12);

PriceSnapshot _s(
  String id,
  int amount,
  PriceType type, {
  required DateTime at,
}) => PriceSnapshot(
  id: id,
  amountVnd: amount,
  priceType: type,
  source: PriceSource.extensionPage,
  observedAt: at,
);

void main() {
  test("'sale' is read back as PriceType.sale", () {
    expect(PriceType.fromKey('sale'), PriceType.sale);
    expect(
      _s('a', 1000, PriceType.sale, at: _now).toMap()['priceType'],
      'sale',
    );
  });

  test(
    'one reading with a sale and a regular price: the regular one is main',
    () {
      final reading = _now.subtract(const Duration(hours: 1));
      final first = _now.subtract(const Duration(days: 2));
      final insights = PriceInsights([
        _s('old-sale', 380000, PriceType.sale, at: first),
        _s('old', 450000, PriceType.single, at: first),
        _s('sale', 399000, PriceType.sale, at: reading),
        _s('regular', 459000, PriceType.single, at: reading),
      ], now: _now);

      expect(insights.latest?.id, 'regular');
      expect(insights.saved?.id, 'old');
      // A sale price is a real price: it still counts for the lowest one
      expect(insights.lowest?.id, 'old-sale');
    },
  );

  test('a sale price alone is the main price', () {
    final insights = PriceInsights([
      _s(
        'regular',
        459000,
        PriceType.single,
        at: _now.subtract(const Duration(days: 1)),
      ),
      _s(
        'sale',
        399000,
        PriceType.sale,
        at: _now.subtract(const Duration(hours: 1)),
      ),
    ], now: _now);

    expect(insights.latest?.id, 'sale');
    expect(insights.changeSinceSavedPercent, -13);
  });

  test(
    '"Giá đang giảm" is never shared (sharedPrices takes single/range/flash)',
    () {
      final at = _now.subtract(const Duration(hours: 1));
      expect(
        SharedPriceSummary.isShareable(
          _s('a', 1000, PriceType.sale, at: at),
          _now,
        ),
        isFalse,
      );
      expect(
        SharedPriceSummary.isShareable(
          _s('b', 1000, PriceType.flash, at: at),
          _now,
        ),
        isTrue,
      );
    },
  );
}
