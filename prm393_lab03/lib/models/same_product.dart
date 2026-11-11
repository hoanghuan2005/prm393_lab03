import '../core/utils/price_history_ids.dart';
import 'price_history.dart';

/// "Cùng món ở shop khác" (G8): another shop's listing with the same productCode and
/// variant code. Facts only: price, day, shop; never a recommendation.
class SameProductOffer {
  final String productKey;

  /// Null when no report and no product names the shop
  final String? shopName;

  /// List price of [day] (the lowest price of a range); never "sau voucher"
  final int priceVnd;
  final DateTime observedAt;

  /// Reports of that Vietnamese day for this listing and variant
  final int reporterCount;
  final double? productRating;

  /// The price was read as "Giá đang giảm" or Flash Sale
  final bool onSale;
  final bool isDemo;

  const SameProductOffer({
    required this.productKey,
    this.shopName,
    required this.priceVnd,
    required this.observedAt,
    required this.reporterCount,
    this.productRating,
    this.onSale = false,
    this.isDemo = false,
  });
}

/// The other listings shown next to an item, for the "Cả nhóm" chart of a real
/// product (instead of productGroups)
class SameProductLinks {
  final List<String> productKeys;

  /// Null: the item has no variant, only listings without variants are compared
  final String? variantCode;

  const SameProductLinks({required this.productKeys, this.variantCode});
}

abstract final class SameProduct {
  /// Only prices recorded in the last 7 days are listed
  static const int windowDays = 7;
  static const int maxOffers = 3;

  /// Tìm ưu đãi có giá hời nhất từ các shop khác (nếu rẻ hơn món hiện tại ≥ 5%)
  static SameProductOffer? findBestDeal(
    List<SameProductOffer> offers,
    int? currentPrice,
  ) {
    if (offers.isEmpty || currentPrice == null || currentPrice <= 0) return null;
    final cheaper = offers.where((o) => o.priceVnd < currentPrice).toList();
    if (cheaper.isEmpty) return null;
    cheaper.sort((a, b) => a.priceVnd.compareTo(b.priceVnd));
    final lowest = cheaper.first;
    // Rẻ hơn ít nhất 5% hoặc từ 10.000đ
    final saving = currentPrice - lowest.priceVnd;
    if (saving >= 10000 || (saving * 100 / currentPrice) >= 5) {
      return lowest;
    }
    return null;
  }

  /// A report of [product] under [modelKey] is for [variantCode]. Without a variant
  /// code, only listings that have no variants at all match.
  static bool matchesVariant(
    PriceHistoryProduct product,
    String modelKey,
    String? variantCode,
  ) => variantCode == null
      ? product.variantCodes.isEmpty
      : product.variantCodes[modelKey] == variantCode;

  static String shopIdOf(String productKey) {
    final parts = productKey.split(':');
    return parts.length == 3 ? parts[1] : productKey;
  }
}

/// Up to [SameProduct.maxOffers] shops with their latest list price of the last 7
/// days for [variantCode], lowest first. One person's report is enough; the number of
/// reports of that day is shown with it. Listings in [hidden] ("Không phải món
/// này") are left out, and a shop with several listings appears once.
List<SameProductOffer> pickLowestOffers(
  Map<String, PriceHistoryProduct> products,
  Map<String, List<PriceHistoryReport>> reports,
  String? variantCode,
  DateTime now, {
  Set<String> hidden = const {},
}) {
  final since = now.subtract(const Duration(days: SameProduct.windowDays));
  final latest = now.add(const Duration(minutes: 5));
  final byShop = <String, SameProductOffer>{};

  for (final MapEntry(key: key, value: product) in products.entries) {
    if (hidden.contains(key)) continue;
    final listed = [
      for (final r in reports[key] ?? const <PriceHistoryReport>[])
        if (r.countsAsListPrice &&
            r.amountVnd > 0 &&
            r.observedAt.isAfter(since) &&
            !r.observedAt.isAfter(latest) &&
            SameProduct.matchesVariant(product, r.modelKey, variantCode))
          r,
    ];
    if (listed.isEmpty) continue;
    listed.sort((a, b) => b.observedAt.compareTo(a.observedAt));
    final last = listed.first;
    final day = PriceHistoryIds.dayKey(last.observedAt);
    final sameDay = [
      for (final r in listed)
        if (PriceHistoryIds.dayKey(r.observedAt) == day) r,
    ];
    final offer = SameProductOffer(
      productKey: key,
      shopName:
          last.shopName ?? (product.shopName.isEmpty ? null : product.shopName),
      priceVnd: last.amountVnd,
      observedAt: last.observedAt,
      reporterCount: sameDay.length,
      productRating: [for (final r in sameDay) ?r.productRating].firstOrNull,
      onSale:
          last.priceType == HistoryPriceType.sale ||
          last.priceType == HistoryPriceType.flash,
      isDemo: product.isDemo,
    );
    final shop = SameProduct.shopIdOf(key);
    final kept = byShop[shop];
    if (kept == null || offer.priceVnd < kept.priceVnd) byShop[shop] = offer;
  }

  return (byShop.values.toList()..sort((a, b) {
        final byPrice = a.priceVnd.compareTo(b.priceVnd);
        if (byPrice != 0) return byPrice;
        final byDate = b.observedAt.compareTo(a.observedAt);
        return byDate != 0 ? byDate : a.productKey.compareTo(b.productKey);
      }))
      .take(SameProduct.maxOffers)
      .toList();
}
