/// Buying motives as the app labels them (BuyingMotive in the mobile app)
const Map<String, String> motiveLabels = {
  'need': 'Nhu cầu',
  'want': 'Mong muốn',
  'sale': 'Khuyến mãi',
  'emotion': 'Cảm xúc',
  'social': 'Ảnh hưởng MXH',
  'convenience': 'Tiện lợi',
  'ads': 'Quảng cáo',
  'other': 'Khác',
};

/// Figures read from every user's purchases and wishlist. firestore.rules lets
/// only admins run these queries, so staff see the dashboard without them.
class ActivityStats {
  /// wishlistItems across every user, by status
  final int considering;
  final int purchased;
  final int skipped;

  /// Skipped items that have a recorded price, and the sum of those prices
  /// (items without a price are not counted as 0: data-model rule 9)
  final int skippedWithPrice;
  final int skippedValueVnd;

  final int purchaseCount;
  final int totalSpendingVnd;

  /// Purchases per motive key (see [motiveLabels])
  final Map<String, int> motives;

  /// Users who added an item or recorded a purchase today
  final int activeUsersToday;

  /// Users with neither an item nor a purchase ("cài app nhưng chưa dùng");
  /// null when there are too many users to check one by one
  final int? dormantUsers;

  const ActivityStats({
    required this.considering,
    required this.purchased,
    required this.skipped,
    required this.skippedWithPrice,
    required this.skippedValueVnd,
    required this.purchaseCount,
    required this.totalSpendingVnd,
    required this.motives,
    required this.activeUsersToday,
    required this.dormantUsers,
  });

  int get decided => purchased + skipped;
  int get wishlistItems => considering + purchased + skipped;

  /// Share of decided items the user chose not to buy: the product's success
  /// signal (fewer impulse purchases). Null until something is decided.
  double? get skipRate => decided == 0 ? null : skipped / decided;

  /// Most frequent motive, or null when nothing was bought
  MapEntry<String, int>? get topMotive {
    MapEntry<String, int>? top;
    for (final e in motives.entries) {
      if (e.value > 0 && (top == null || e.value > top.value)) top = e;
    }
    return top;
  }
}

/// Dashboard figures, each one from server-side aggregation queries (count / sum)
/// or a query that reads only today's documents.
class DashboardStats {
  final int totalUsers;
  final int newUsersToday;
  final int newUsersLast7Days;
  final int pendingSuggestions;

  /// Null for staff (admin-only queries)
  final ActivityStats? activity;

  final DateTime loadedAt;

  const DashboardStats({
    required this.totalUsers,
    required this.newUsersToday,
    required this.newUsersLast7Days,
    required this.pendingSuggestions,
    required this.activity,
    required this.loadedAt,
  });

  bool get isEmpty => totalUsers == 0;
}
