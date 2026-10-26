import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_fields.dart';

/// users/{uid}/budgets/{yyyy-MM} — document id is the month key
class MonthlyBudget {
  final String month;

  /// budgetGroupId → limit in VND
  final Map<String, int> limits;
  final DateTime? updatedAt;

  const MonthlyBudget({
    required this.month,
    this.limits = const {},
    this.updatedAt,
  });

  int get totalLimit => limits.values.fold(0, (total, v) => total + v);

  int? limitFor(String groupId) => limits[groupId];

  factory MonthlyBudget.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final raw = data['limits'];
    final limits = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        final v = readVnd(value);
        if (key is String && v != null) limits[key] = v;
      });
    }
    return MonthlyBudget(
      month: doc.id,
      limits: limits,
      updatedAt: readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'limits': limits,
    if (updatedAt != null) 'updatedAt': toTimestamp(updatedAt),
  };

  MonthlyBudget copyWith({
    String? month,
    Map<String, int>? limits,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      month: month ?? this.month,
      limits: limits ?? this.limits,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudget &&
          other.month == month &&
          mapEquals(other.limits, limits) &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    month,
    Object.hashAllUnordered(
      limits.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    updatedAt,
  );
}
