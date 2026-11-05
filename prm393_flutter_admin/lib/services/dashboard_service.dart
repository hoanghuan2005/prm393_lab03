import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';

abstract class DashboardService {
  Future<DashboardStats> load({DateTime? now});
}

/// Every figure is a server-side aggregation (`count()` / `sum()`), allowed to
/// admins only by firestore.rules (`/{path=**}/wishlistItems` list rule).
class FirestoreDashboardService implements DashboardService {
  final FirebaseFirestore _db;
  final SharedPaths _paths;

  FirestoreDashboardService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance,
      _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  Query<JsonMap> _items(String status) =>
      _db.collectionGroup('wishlistItems').where('status', isEqualTo: status);

  @override
  Future<DashboardStats> load({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final weekAgo = Timestamp.fromDate(at.subtract(const Duration(days: 7)));

    final results = await Future.wait([
      _paths.users().count().get(),
      _paths
          .users()
          .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
          .count()
          .get(),
      _paths
          .saleSuggestions()
          .where('status', isEqualTo: SuggestionStatus.pending.key)
          .count()
          .get(),
      _items('considering').count().get(),
      _items('purchased').count().get(),
      _items('skipped').count().get(),
      // Kept apart from the count above: with sum() the query only sees items
      // that have a price (it runs on the status + latestPriceVnd index)
      _items('skipped').aggregate(count(), sum('latestPriceVnd')).get(),
    ]);

    final priced = results[6];
    return DashboardStats(
      totalUsers: results[0].count ?? 0,
      newUsersLast7Days: results[1].count ?? 0,
      pendingSuggestions: results[2].count ?? 0,
      considering: results[3].count ?? 0,
      purchased: results[4].count ?? 0,
      skipped: results[5].count ?? 0,
      skippedWithPrice: priced.count ?? 0,
      skippedValueVnd: (priced.getSum('latestPriceVnd') ?? 0).round(),
      loadedAt: at,
    );
  }
}
