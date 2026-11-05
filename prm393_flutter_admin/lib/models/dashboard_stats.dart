/// Figures of the dashboard, each one a Firestore aggregation query
/// (count / sum) run on the server: no document is downloaded.
class DashboardStats {
  final int totalUsers;
  final int newUsersLast7Days;
  final int pendingSuggestions;

  /// wishlistItems across every user, by status
  final int considering;
  final int purchased;
  final int skipped;

  /// Skipped items that have a recorded price
  final int skippedWithPrice;

  /// Sum of the last recorded price of skipped items; items without a price
  /// are not counted as 0 (data-model rule 9)
  final int skippedValueVnd;

  final DateTime loadedAt;

  const DashboardStats({
    required this.totalUsers,
    required this.newUsersLast7Days,
    required this.pendingSuggestions,
    required this.considering,
    required this.purchased,
    required this.skipped,
    required this.skippedWithPrice,
    required this.skippedValueVnd,
    required this.loadedAt,
  });

  int get decided => purchased + skipped;

  /// Share of decided items the user chose not to buy: the product's success
  /// signal (fewer impulse purchases). Null until something is decided.
  double? get skipRate => decided == 0 ? null : skipped / decided;

  bool get isEmpty => totalUsers == 0;
}
