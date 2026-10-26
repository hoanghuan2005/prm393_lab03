import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Mua · Chờ · Bỏ qua (equal weight) + undo of the previous choice
enum DecisionChoice {
  buy('buy', 'Mua'),
  wait('wait', 'Chờ'),
  skip('skip', 'Bỏ qua'),
  undo('undo', 'Hoàn tác');

  final String key;
  final String label;

  const DecisionChoice(this.key, this.label);

  static DecisionChoice? fromKey(String? key) {
    for (final c in DecisionChoice.values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// users/{uid}/decisions/{decisionId} — append-only
class Decision {
  final String id;
  final String itemId;
  final DecisionChoice choice;
  final DateTime at;
  final DateTime? reviewAt;

  const Decision({
    required this.id,
    required this.itemId,
    required this.choice,
    required this.at,
    this.reviewAt,
  });

  /// Unknown choices read as [DecisionChoice.undo] so they never count as buy/skip
  factory Decision.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return Decision(
      id: doc.id,
      itemId: readString(data['itemId']) ?? '',
      choice:
          DecisionChoice.fromKey(readString(data['choice'])) ??
          DecisionChoice.undo,
      at: readDate(data['at']) ?? DateTime.now(),
      reviewAt: readDate(data['reviewAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'choice': choice.key,
    'at': Timestamp.fromDate(at),
    'reviewAt': toTimestamp(reviewAt),
  };

  Decision copyWith({
    String? id,
    String? itemId,
    DecisionChoice? choice,
    DateTime? at,
    DateTime? reviewAt,
  }) {
    return Decision(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      choice: choice ?? this.choice,
      at: at ?? this.at,
      reviewAt: reviewAt ?? this.reviewAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Decision &&
          other.id == id &&
          other.itemId == itemId &&
          other.choice == choice &&
          other.at == at &&
          other.reviewAt == reviewAt;

  @override
  int get hashCode => Object.hash(id, itemId, choice, at, reviewAt);
}
