import '../core/utils/price_history_ids.dart';
import 'price_history.dart';
import 'price_snapshot.dart';
import 'shared_price.dart';
import 'shopee_link.dart';
import 'wishlist_item.dart';

/// What the user's own prices of one item add to "Giá tham khảo" (G7): anonymous
/// reports in priceHistory/{productKey}/reports, one per person, variant and day.
abstract final class HistoryContribution {
  /// firestore.rules refuse prices observed more than 3 days ago
  static const int windowDays = 3;

  /// Room for a write that waits a little before reaching the server
  static const Duration _margin = Duration(minutes: 10);

  static const int _maxShopName = 60;
  static const int _maxTitle = 120;

  /// Reports to send for [item]. Only an item with a Shopee productKey; only confirmed
  /// prices typed in the app or read by the extension, observed in the last
  /// [windowDays]. One per Vietnam day (the report id holds the day): the latest list
  /// price of that day, otherwise its latest "sau voucher" price, which keeps its type.
  static List<PriceHistoryReport> reportsFor(
    WishlistItem item,
    List<PriceSnapshot> snapshots,
    DateTime now,
  ) {
    if (productKeyOf(item) == null) return const [];
    final byDay = <String, PriceSnapshot>{};
    for (final s in snapshots) {
      if (!_eligible(s, now)) continue;
      final day = PriceHistoryIds.dayKey(s.observedAt);
      final kept = byDay[day];
      if (kept == null || _preferred(s, kept)) byDay[day] = s;
    }
    final modelKey = SharedPriceSummary.modelKeyOf(item.modelId);
    return [
      for (final s in byDay.values)
        PriceHistoryReport(
          // The document id is the hash made by the service (it needs the uid)
          id: '',
          amountVnd: s.amountVnd,
          priceType: HistoryPriceType.fromKey(s.priceType.key),
          modelKey: modelKey,
          observedAt: s.observedAt,
          source: s.source == PriceSource.manual
              ? HistoryReportSource.manual
              : HistoryReportSource.extensionPage,
          shopName: shopNameOf(s.shopName ?? item.shopName),
          productRating: s.productRating ?? item.productRating,
          productRatingCount: s.productRatingCount ?? item.productRatingCount,
          shopRating: s.shopRating ?? item.shopRating,
        ),
    ];
  }

  /// The item's productKey when it is a Shopee product (written by the extension)
  static String? productKeyOf(WishlistItem item) =>
      ShopeeLink.fromProductKey(item.productKey)?.productKey;

  /// Title of priceHistory/{productKey} (1–120 characters)
  static String? titleOf(WishlistItem item) => _clip(item.title, _maxTitle);

  /// Shop name as firestore.rules accept it (1–60 characters)
  static String? shopNameOf(String? name) => _clip(name, _maxShopName);

  static String? _clip(String? text, int max) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.length <= max ? t : t.substring(0, max).trimRight();
  }

  static bool _eligible(PriceSnapshot s, DateTime now) =>
      s.confirmed &&
      (s.source == PriceSource.manual ||
          s.source == PriceSource.extensionPage) &&
      s.amountVnd > 0 &&
      s.amountVnd <= 999999999 &&
      !s.observedAt.isAfter(now.add(const Duration(minutes: 5))) &&
      now.difference(s.observedAt) < const Duration(days: windowDays) - _margin;

  /// A list price beats "sau voucher" on the same day; otherwise the later one
  static bool _preferred(PriceSnapshot a, PriceSnapshot b) {
    final aList = a.priceType != PriceType.afterVoucher;
    final bList = b.priceType != PriceType.afterVoucher;
    if (aList != bList) return aList;
    return a.observedAt.isAfter(b.observedAt);
  }
}
