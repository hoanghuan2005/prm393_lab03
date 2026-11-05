import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'price_snapshot.dart';

/// One anonymous price in sharedPrices/{productKey}/reports/{reportId}. It holds no
/// uid, name or link: who recorded it is never returned to anyone (spec 6.5, 8.3).
class SharedPriceReport {
  /// The lowest price for a [PriceType.range], like [PriceSnapshot.amountVnd]
  final int amountVnd;
  final PriceType priceType;
  final DateTime observedAt;

  const SharedPriceReport({
    required this.amountVnd,
    required this.priceType,
    required this.observedAt,
  });
}

/// "Giá người khác ghi" (spec 8.3, decision 3): only shown for the same product and
/// variant, from at least 2 people within 3 days, after dropping prices more than 30%
/// away from the median. Only a suggestion; the user confirms before using it.
class SharedPriceSummary {
  static const int windowDays = 3;
  static const int minPeople = 2;
  static const int outlierPercent = 30;

  /// Reports kept after the outlier filter (one report per person)
  final int count;

  /// Reports dropped for being more than [outlierPercent] away from the median
  final int excludedCount;
  final int medianVnd;
  final int minVnd;
  final int maxVnd;

  /// Signed difference of the user's own price from [medianVnd]; null without one
  final int? myDiffPercent;

  const SharedPriceSummary({
    required this.count,
    required this.excludedCount,
    required this.medianVnd,
    required this.minVnd,
    required this.maxVnd,
    this.myDiffPercent,
  });

  static int _median(List<int> sorted) {
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  /// Null when there are not enough comparable prices to say anything
  static SharedPriceSummary? summarize(
    List<SharedPriceReport> reports, {
    required PriceType priceType,
    required DateTime now,
    int? myAmountVnd,
  }) {
    final since = now.subtract(const Duration(days: windowDays));
    // "So được": the same kind of price only (Flash Sale with Flash Sale, range with range)
    final prices = [
      for (final r in reports)
        if (r.priceType == priceType &&
            r.priceType != PriceType.afterVoucher &&
            r.amountVnd > 0 &&
            r.observedAt.isAfter(since))
          r.amountVnd,
    ]..sort();
    if (prices.length < minPeople) return null;

    final median = _median(prices);
    final kept = [
      for (final p in prices)
        if ((p - median).abs() * 100 <= median * outlierPercent) p,
    ];
    if (kept.length < minPeople) return null;

    final keptMedian = _median(kept);
    final mine = myAmountVnd;
    return SharedPriceSummary(
      count: kept.length,
      excludedCount: prices.length - kept.length,
      medianVnd: keptMedian,
      minVnd: kept.first,
      maxVnd: kept.last,
      myDiffPercent: mine == null || mine <= 0
          ? null
          : ((mine - keptMedian) * 100 / keptMedian).round(),
    );
  }

  /// `none` when the variant is unknown; prices are only compared within one key
  static String modelKeyOf(String? modelId) =>
      modelId == null || modelId.isEmpty ? 'none' : modelId;

  /// Document id of a person's report: sha256("uid|productKey|modelKey") in lowercase
  /// hex. firestore.rules recomputes it, so one person has one report per variant and
  /// nobody can write under someone else's id; the uid itself is never stored.
  static String reportId(String uid, String productKey, String modelKey) =>
      sha256.convert(utf8.encode('$uid|$productKey|$modelKey')).toString();

  /// A price this person may share: typed in the app or read from the page by the
  /// extension, confirmed, still "mới". Demo prices and prices taken from other people
  /// are never shared (spec 6.5).
  static bool isShareable(PriceSnapshot s, DateTime now) =>
      s.confirmed &&
      s.priceType != PriceType.afterVoucher &&
      (s.source == PriceSource.manual ||
          s.source == PriceSource.extensionPage) &&
      s.amountVnd > 0 &&
      now.difference(s.observedAt) <= const Duration(days: windowDays);
}
