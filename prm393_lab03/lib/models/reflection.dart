import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// users/{uid}/reflections/{yyyy-MM} — document id is the month key
class Reflection {
  final String month;

  /// 1–5
  final int rating;

  /// ≤ 200 characters
  final String? goal;
  final DateTime? updatedAt;

  const Reflection({
    required this.month,
    required this.rating,
    this.goal,
    this.updatedAt,
  });

  factory Reflection.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return Reflection(
      month: doc.id,
      rating: (readInt(data['rating']) ?? 3).clamp(1, 5),
      goal: readText(data['goal']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'rating': rating,
    'goal': goal,
    if (updatedAt != null) 'updatedAt': toTimestamp(updatedAt),
  };

  Reflection copyWith({
    String? month,
    int? rating,
    String? goal,
    DateTime? updatedAt,
  }) {
    return Reflection(
      month: month ?? this.month,
      rating: rating ?? this.rating,
      goal: goal ?? this.goal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reflection &&
          other.month == month &&
          other.rating == rating &&
          other.goal == goal &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(month, rating, goal, updatedAt);
}
