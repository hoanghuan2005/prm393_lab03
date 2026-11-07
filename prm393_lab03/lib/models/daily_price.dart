import '../core/utils/price_history_ids.dart';
import 'price_history.dart';

/// "Biểu đồ giá tham khảo": one product's reports grouped by day (Vietnam time).
/// Pure functions, no widgets: sparse data stays sparse, an empty day is null.

/// The Vietnamese calendar date of [t] as a UTC date (fields = the date in Vietnam)
DateTime vnDate(DateTime t) {
  final vn = t.toUtc().add(PriceHistoryIds.vietnamOffset);
  return DateTime.utc(vn.year, vn.month, vn.day);
}

/// Every Vietnamese date from [from] to [to], both included
List<DateTime> vnDays(DateTime from, DateTime to) {
  final first = vnDate(from), last = vnDate(to);
  return [
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) d,
  ];
}

/// One Vietnamese day of one product. Every day of the period has one, even without
/// reports; a missing value stays null so the chart leaves a gap.
class DailyPricePoint {
  /// Vietnamese date (UTC fields)
  final DateTime day;

  /// Lowest and median list price after the 30% filter; null below
  /// [minReportsPerDay] kept reports. afterVoucher never counts here.
  final int? minVnd;
  final int? medianVnd;

  /// Highest kept list price, with the same rule as [minVnd]
  final int? maxVnd;

  /// List-price reports kept after the filter (afterVoucher not counted)
  final int reportCount;

  /// afterVoucher reports that day
  final int afterVoucherCount;

  /// Lowest "sau voucher, tham khảo" price, shown on its own; null below
  /// [minReportsPerDay] afterVoucher reports (its own threshold)
  final int? afterVoucherMinVnd;

  /// A kept report was a sale or Flash Sale price
  final bool hasSale;

  /// Median of the kept list-price reports and the afterVoucher reports; a report
  /// dropped for its price is dropped for its rating too
  final double? productRating;
  final double? shopRating;

  /// From the newest of those reports that has one
  final int? productRatingCount;
  final String? shopName;

  const DailyPricePoint({
    required this.day,
    this.minVnd,
    this.medianVnd,
    this.maxVnd,
    this.reportCount = 0,
    this.afterVoucherCount = 0,
    this.afterVoucherMinVnd,
    this.hasSale = false,
    this.productRating,
    this.shopRating,
    this.productRatingCount,
    this.shopName,
  });

  /// Has a list price to draw
  bool get hasPrice => minVnd != null;
}

/// A price (list or after-voucher) needs this many reports that day
const int minReportsPerDay = 2;

/// List-price reports further than this from the day's median are dropped
const int outlierPercent = 30;

int _medianInt(List<int> sorted) {
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

double? _medianRating(Iterable<double?> values) {
  final s = [for (final v in values) ?v]..sort();
  if (s.isEmpty) return null;
  final mid = s.length ~/ 2;
  final m = s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  return (m * 10).round() / 10;
}

/// Exactly one [DailyPricePoint] per Vietnamese day from [from] to [to].
/// List prices: drop reports more than [outlierPercent]% from the day's median, then
/// minVnd / medianVnd need [minReportsPerDay] kept reports. A range report counts with
/// its lowest price (stored in amountVnd). afterVoucher prices never enter the filter,
/// the count, minVnd or medianVnd; afterVoucherMinVnd has its own threshold.
List<DailyPricePoint> aggregateDaily(
  List<PriceHistoryReport> reports,
  DateTime from,
  DateTime to,
) {
  final byDay = <DateTime, List<PriceHistoryReport>>{};
  for (final r in reports) {
    if (r.amountVnd <= 0) continue;
    (byDay[vnDate(r.observedAt)] ??= []).add(r);
  }
  return [
    for (final day in vnDays(from, to)) _point(day, byDay[day] ?? const []),
  ];
}

DailyPricePoint _point(DateTime day, List<PriceHistoryReport> reports) {
  final listed = [
    for (final r in reports)
      if (r.countsAsListPrice) r,
  ];
  final vouchers = [
    for (final r in reports)
      if (!r.countsAsListPrice) r,
  ];
  final median = listed.isEmpty
      ? 0
      : _medianInt([for (final r in listed) r.amountVnd]..sort());
  final kept = [
    for (final r in listed)
      if ((r.amountVnd - median).abs() * 100 <= median * outlierPercent) r,
  ];
  final prices = [for (final r in kept) r.amountVnd]..sort();
  final enough = prices.length >= minReportsPerDay;
  final voucherPrices = [for (final r in vouchers) r.amountVnd]..sort();

  // Ratings: only reports whose price was kept, plus the afterVoucher ones
  final rated = [...kept, ...vouchers]
    ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  return DailyPricePoint(
    day: day,
    minVnd: enough ? prices.first : null,
    medianVnd: enough ? _medianInt(prices) : null,
    maxVnd: enough ? prices.last : null,
    reportCount: kept.length,
    afterVoucherCount: vouchers.length,
    afterVoucherMinVnd: voucherPrices.length >= minReportsPerDay
        ? voucherPrices.first
        : null,
    hasSale: kept.any(
      (r) =>
          r.priceType == HistoryPriceType.sale ||
          r.priceType == HistoryPriceType.flash,
    ),
    productRating: _medianRating(rated.map((r) => r.productRating)),
    shopRating: _medianRating(rated.map((r) => r.shopRating)),
    productRatingCount: [for (final r in rated) ?r.productRatingCount]
        .firstOrNull,
    shopName: [for (final r in rated) ?r.shopName].firstOrNull,
  );
}

/// One product's numbers on a day of the group comparison
class GroupPick {
  final String productKey;
  final int minVnd;
  final String? shopName;
  final double? productRating;

  const GroupPick({
    required this.productKey,
    required this.minVnd,
    this.shopName,
    this.productRating,
  });
}

/// A day of "cùng món, nhiều shop": the lowest list price and the highest product
/// rating, side by side (facts only, no ranking or advice)
class GroupDayComparison {
  final DateTime day;

  /// Products with a point that day
  final int productCount;
  final GroupPick lowestPrice;

  /// Null when no product had a rating that day
  final GroupPick? highestRated;

  const GroupDayComparison({
    required this.day,
    required this.productCount,
    required this.lowestPrice,
    this.highestRated,
  });
}

/// [pointsByProduct]: [aggregateDaily] of each product over the same days. One entry
/// per day: null when no product has a list price that day, otherwise the comparison (also with a
/// single product). Only minVnd is compared, never the after-voucher price. Ties go to
/// the earlier product in [pointsByProduct].
List<GroupDayComparison?> compareGroup(
  Map<String, List<DailyPricePoint>> pointsByProduct,
) {
  final length = pointsByProduct.values.fold(
    0,
    (n, points) => points.length > n ? points.length : n,
  );
  return [for (var i = 0; i < length; i++) _compareDay(pointsByProduct, i)];
}

GroupDayComparison? _compareDay(
  Map<String, List<DailyPricePoint>> pointsByProduct,
  int i,
) {
  final picks = <(GroupPick, DateTime)>[
    for (final MapEntry(:key, :value) in pointsByProduct.entries)
      if (value.elementAtOrNull(i)?.minVnd case final minVnd?)
        (
          GroupPick(
            productKey: key,
            minVnd: minVnd,
            shopName: value[i].shopName,
            productRating: value[i].productRating,
          ),
          value[i].day,
        ),
  ];
  if (picks.isEmpty) return null;
  GroupPick? lowest, best;
  for (final (p, _) in picks) {
    if (lowest == null || p.minVnd < lowest.minVnd) lowest = p;
    final r = p.productRating;
    if (r != null &&
        (best == null ||
            r > best.productRating! ||
            (r == best.productRating && p.minVnd < best.minVnd))) {
      best = p;
    }
  }
  return GroupDayComparison(
    day: picks.first.$2,
    productCount: picks.length,
    lowestPrice: lowest!,
    highestRated: best,
  );
}
