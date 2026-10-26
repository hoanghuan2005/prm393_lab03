import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_group.dart';
import '../models/monthly_budget.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}/budgetGroups and users/{uid}/budgets/{yyyy-MM}
abstract interface class BudgetService {
  /// Sorted by `order`
  Stream<List<BudgetGroup>> watchGroups(String uid);

  /// Creates the 6 default groups only when the user has none yet; safe to call repeatedly
  Future<void> ensureDefaultGroups(String uid);

  /// Emits an empty budget (no limits) while the month document does not exist
  Stream<MonthlyBudget> watchMonthlyBudget(String uid, String monthKey);

  /// [limit] null (or ≤ 0) removes the group's limit for that month
  Future<void> setGroupLimit(
    String uid,
    String monthKey,
    String groupId,
    int? limit,
  );

  /// Several groups in one write; a null (or ≤ 0) value removes that group's limit
  Future<void> setGroupLimits(
    String uid,
    String monthKey,
    Map<String, int?> limits,
  );
}

class FirestoreBudgetService implements BudgetService {
  final FirestorePaths _paths;

  FirestoreBudgetService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<List<BudgetGroup>> watchGroups(String uid) => guardStream(
    _paths
        .budgetGroups(uid)
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(BudgetGroup.fromFirestore).toList()),
  );

  @override
  Future<void> ensureDefaultGroups(String uid) => guard(() async {
    final existing = await _paths.budgetGroups(uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _paths.db.batch();
    for (final group in defaultBudgetGroups) {
      batch.set(_paths.budgetGroup(uid, group.id), group.toMap());
    }
    await batch.commit();
  });

  @override
  Stream<MonthlyBudget> watchMonthlyBudget(String uid, String monthKey) =>
      guardStream(
        _paths
            .budget(uid, monthKey)
            .snapshots()
            .map(
              (doc) => doc.exists
                  ? MonthlyBudget.fromFirestore(doc)
                  : MonthlyBudget(month: monthKey),
            ),
      );

  @override
  Future<void> setGroupLimit(
    String uid,
    String monthKey,
    String groupId,
    int? limit,
  ) => setGroupLimits(uid, monthKey, {groupId: limit});

  @override
  Future<void> setGroupLimits(
    String uid,
    String monthKey,
    Map<String, int?> limits,
  ) => guard(
    () => _paths.budget(uid, monthKey).set({
      'limits': {
        for (final e in limits.entries)
          e.key: e.value != null && e.value! > 0 ? e.value : FieldValue.delete(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );
}
