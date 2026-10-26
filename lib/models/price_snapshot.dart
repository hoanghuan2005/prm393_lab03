import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum PriceSource {
  manual('manual'),
  demo('demo');

  final String key;

  const PriceSource(this.key);

  static PriceSource fromKey(String? key) => PriceSource.values.firstWhere(
    (s) => s.key == key,
    orElse: () => PriceSource.manual,
  );
}

/// users/{uid}/wishlistItems/{itemId}/priceSnapshots/{snapshotId} — append-only
class PriceSnapshot {
  final String id;
  final int amountVnd;
  final PriceSource source;
  final DateTime observedAt;

  const PriceSnapshot({
    required this.id,
    required this.amountVnd,
    this.source = PriceSource.manual,
    required this.observedAt,
  });

  factory PriceSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return PriceSnapshot(
      id: doc.id,
      amountVnd: readInt(data['amountVnd']) ?? 0,
      source: PriceSource.fromKey(readString(data['source'])),
      observedAt: readDate(data['observedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'amountVnd': amountVnd,
    'source': source.key,
    'observedAt': Timestamp.fromDate(observedAt),
  };

  PriceSnapshot copyWith({
    String? id,
    int? amountVnd,
    PriceSource? source,
    DateTime? observedAt,
  }) {
    return PriceSnapshot(
      id: id ?? this.id,
      amountVnd: amountVnd ?? this.amountVnd,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceSnapshot &&
          other.id == id &&
          other.amountVnd == amountVnd &&
          other.source == source &&
          other.observedAt == observedAt;

  @override
  int get hashCode => Object.hash(id, amountVnd, source, observedAt);
}
