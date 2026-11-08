import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';

abstract class DashboardService {
  /// [includeActivity]: the admin-only figures over every user's data
  Future<DashboardStats> load({required bool includeActivity, DateTime? now});
}

/// Counts and sums run on the server (no document is downloaded), except
/// "active today", which reads only today's new items and purchases.
class FirestoreDashboardService implements DashboardService {
  /// Above this many users, "dormant" is not checked user by user
  static const int maxUsersForDormant = 300;

  final FirebaseFirestore _db;
  final SharedPaths _paths;

  FirestoreDashboardService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance,
      _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<DashboardStats> load({
    required bool includeActivity,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final today = Timestamp.fromDate(_startOfDay(at));
    final weekAgo = Timestamp.fromDate(at.subtract(const Duration(days: 7)));
    final users = _paths.users();

    final counts = await Future.wait([
      users.count().get(),
      users.where('createdAt', isGreaterThanOrEqualTo: today).count().get(),
      users.where('createdAt', isGreaterThanOrEqualTo: weekAgo).count().get(),
      _paths
          .saleSuggestions()
          .where('status', isEqualTo: SuggestionStatus.pending.key)
          .count()
          .get(),
    ]);
    final totalUsers = counts[0].count ?? 0;

    return DashboardStats(
      totalUsers: totalUsers,
      newUsersToday: counts[1].count ?? 0,
      newUsersLast7Days: counts[2].count ?? 0,
      pendingSuggestions: counts[3].count ?? 0,
      activity: includeActivity ? await _activity(today, totalUsers) : null,
      loadedAt: at,
    );
  }

  Future<ActivityStats> _activity(Timestamp today, int totalUsers) async {
    final items = _db.collectionGroup('wishlistItems');
    final purchases = _db.collectionGroup('purchases');
    Query<JsonMap> byStatus(String s) => items.where('status', isEqualTo: s);

    final results = await Future.wait<AggregateQuerySnapshot>([
      byStatus('considering').count().get(),
      byStatus('purchased').count().get(),
      byStatus('skipped').count().get(),
      // Kept apart from the count above: with sum() the query only sees items
      // that have a price (it runs on the status + latestPriceVnd index)
      byStatus('skipped').aggregate(count(), sum('latestPriceVnd')).get(),
      purchases.aggregate(count(), sum('amountVnd')).get(),
      for (final motive in motiveLabels.keys)
        purchases.where('motive', isEqualTo: motive).count().get(),
    ]);
    final priced = results[3];
    final spending = results[4];
    final motives = {
      for (final (i, motive) in motiveLabels.keys.indexed)
        motive: results[5 + i].count ?? 0,
    };

    // Today's new items and purchases only: their owner is the parent user doc
    final todayDocs = await Future.wait([
      items.where('createdAt', isGreaterThanOrEqualTo: today).get(),
      purchases.where('createdAt', isGreaterThanOrEqualTo: today).get(),
    ]);
    final activeToday = {
      for (final snapshot in todayDocs)
        for (final doc in snapshot.docs) doc.reference.parent.parent?.id,
    }..remove(null);

    return ActivityStats(
      considering: results[0].count ?? 0,
      purchased: results[1].count ?? 0,
      skipped: results[2].count ?? 0,
      skippedWithPrice: priced.count ?? 0,
      skippedValueVnd: (priced.getSum('latestPriceVnd') ?? 0).round(),
      purchaseCount: spending.count ?? 0,
      totalSpendingVnd: (spending.getSum('amountVnd') ?? 0).round(),
      motives: motives,
      activeUsersToday: activeToday.length,
      dormantUsers: totalUsers > maxUsersForDormant ? null : await _dormant(),
    );
  }

  /// Users with no item and no purchase: two count() reads per user
  Future<int> _dormant() async {
    final users = await _paths.users().get();
    final empty = await Future.wait(
      users.docs.map((u) async {
        final c = await Future.wait([
          u.reference.collection('wishlistItems').count().get(),
          u.reference.collection('purchases').count().get(),
        ]);
        return (c[0].count ?? 0) + (c[1].count ?? 0) == 0;
      }),
    );
    return empty.where((e) => e).length;
  }
}
