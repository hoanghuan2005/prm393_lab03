import 'purchase_item.dart';

/// Spec 7.1, "Phần khả dụng cho Wishlist", with every intermediate number kept so
/// "Vì sao con số này?" can show the calculation with the user's own figures:
///
/// khaDung = max(0, conLai − duPhong) × (1 − bienDo)
/// duPhong = average daily spending of the group (last 90 days, purchases made from the
///           wishlist excluded) × days left in the month; 0 below 30 days of history
class AvailableBudget {
  static const int safetyMarginPercent = 10;
  static const int historyDaysRequired = 30;
  static const int historyWindowDays = 90;

  final int limit;
  final int spent;

  /// Days the daily average is measured over (≤ [historyWindowDays]); 0 without enough history
  final int windowDays;
  final int dailyAverage;
  final int daysLeft;
  final bool hasEnoughHistory;

  const AvailableBudget({
    required this.limit,
    required this.spent,
    required this.windowDays,
    required this.dailyAverage,
    required this.daysLeft,
    required this.hasEnoughHistory,
  });

  /// [groupPurchases]: every purchase of this group (any month).
  /// [firstPurchaseAt]: the user's first recorded purchase in any group.
  factory AvailableBudget.compute({
    required int limit,
    required DateTime month,
    required List<PurchaseItem> groupPurchases,
    required DateTime? firstPurchaseAt,
    required DateTime now,
  }) {
    final spent = groupPurchases
        .where(
          (p) =>
              p.occurredAt.year == month.year &&
              p.occurredAt.month == month.month,
        )
        .fold(0, (sum, p) => sum + p.amountVnd);

    final historyDays = firstPurchaseAt == null
        ? 0
        : now.difference(firstPurchaseAt).inDays;
    final hasEnoughHistory = historyDays >= historyDaysRequired;
    // A user with 45 days of history is averaged over 45 days, not diluted over 90
    final windowDays = hasEnoughHistory
        ? (historyDays < historyWindowDays ? historyDays : historyWindowDays)
        : 0;

    var dailyAverage = 0;
    if (windowDays > 0) {
      final since = now.subtract(Duration(days: windowDays));
      final routine = groupPurchases
          .where(
            (p) =>
                p.wishlistItemId == null &&
                p.occurredAt.isAfter(since) &&
                !p.occurredAt.isAfter(now),
          )
          .fold(0, (sum, p) => sum + p.amountVnd);
      dailyAverage = routine ~/ windowDays;
    }

    return AvailableBudget(
      limit: limit,
      spent: spent,
      windowDays: windowDays,
      dailyAverage: dailyAverage,
      daysLeft: daysLeftIn(month, now),
      hasEnoughHistory: hasEnoughHistory,
    );
  }

  /// Days after today in [month]: 0 for past months, the whole month for future ones
  static int daysLeftIn(DateTime month, DateTime now) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (month.year == now.year && month.month == now.month) {
      return daysInMonth - now.day;
    }
    return DateTime(month.year, month.month).isAfter(now) ? daysInMonth : 0;
  }

  /// conLai; negative when the limit is exceeded
  int get remaining => limit - spent;

  /// duPhong
  int get buffer => hasEnoughHistory ? dailyAverage * daysLeft : 0;

  /// khaDung, rounded down to whole VND
  int get available {
    final left = remaining - buffer;
    if (left <= 0) return 0;
    return left * (100 - safetyMarginPercent) ~/ 100;
  }
}
