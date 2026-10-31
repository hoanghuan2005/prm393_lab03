import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import 'price_snapshot.dart';

/// Spec 6.5: ≤ 3 days is "mới" (used for comparisons and the Decision Card),
/// 4–7 days is shown with its date, older than 7 days is "cũ"
enum PriceFreshness { fresh, dated, stale }

/// "Lịch sử giá và so sánh" of one item (spec A-14, 6.5, 8.3).
///
/// The app only records single prices typed by the user for one item, with no price
/// type or variant, so every snapshot of the item is treated as comparable. Prices go
/// up or down only against a fresh latest price.
class PriceInsights {
  static const int freshDays = 3;
  static const int datedDays = 7;

  /// "Thấp nhất đã ghi" needs at least this many records (spec 8.2)
  static const int lowestMinRecords = 3;

  /// "Giá đang cao hơn lúc lưu" is shown from this rise (spec 8.2, in-app only)
  static const int notableRisePercent = 10;

  /// Newest first
  final List<PriceSnapshot> history;
  final DateTime now;

  PriceInsights(List<PriceSnapshot> snapshots, {required this.now})
    : history = [...snapshots]
        ..sort((a, b) => b.observedAt.compareTo(a.observedAt));

  PriceSnapshot? get latest => history.isEmpty ? null : history.first;

  /// "Giá lúc lưu": the first record
  PriceSnapshot? get saved => history.isEmpty ? null : history.last;

  static PriceFreshness freshnessOf(PriceSnapshot s, DateTime now) =>
      freshnessAt(s.observedAt, now);

  static PriceFreshness freshnessAt(DateTime at, DateTime now) {
    final days = now.difference(at).inDays;
    if (days <= freshDays) return PriceFreshness.fresh;
    if (days <= datedDays) return PriceFreshness.dated;
    return PriceFreshness.stale;
  }

  /// Label for a price recorded at [at] (e.g. an item's latestPriceAt)
  static String labelAt(DateTime at, DateTime now) =>
      switch (freshnessAt(at, now)) {
        PriceFreshness.fresh => 'Mới',
        PriceFreshness.dated => 'Ghi ngày ${formatDate(at)}',
        PriceFreshness.stale => 'Cũ · ${formatDate(at)}',
      };

  /// Signed change of the latest price from the saved one; null unless the latest is
  /// fresh and there are two records to compare
  int? get changeSinceSavedPercent {
    final last = latest, first = saved;
    if (last == null || first == null || history.length < 2) return null;
    if (first.amountVnd <= 0) return null;
    if (freshnessOf(last, now) != PriceFreshness.fresh) return null;
    return ((last.amountVnd - first.amountVnd) * 100 / first.amountVnd).round();
  }

  PriceSnapshot? get lowest {
    if (history.length < lowestMinRecords) return null;
    return history.reduce((a, b) => b.amountVnd < a.amountVnd ? b : a);
  }

  /// Short label next to a price: "Mới", "Ghi ngày 26/10/2026", "Cũ · 12/10/2026"
  static String freshnessLabel(PriceSnapshot s, DateTime now) =>
      labelAt(s.observedAt, now);

  /// Neutral observations; nothing when there is too little history
  List<String> get notes {
    final change = changeSinceSavedPercent;
    final low = lowest;
    final last = latest;
    return [
      if (change != null && change < 0) 'Thấp hơn lúc lưu ${-change}%.',
      if (change != null && change >= notableRisePercent)
        'Giá đang cao hơn lúc lưu $change%.'
      else if (change != null && change > 0)
        'Cao hơn lúc lưu $change%.',
      if (last != null &&
          history.length >= 2 &&
          freshnessOf(last, now) != PriceFreshness.fresh)
        'Giá mới nhất không còn mới nên chưa so với lúc lưu.',
      if (low != null)
        'Thấp nhất đã ghi: ${formatVnd(low.amountVnd)} (${formatDate(low.observedAt)}).',
    ];
  }
}
