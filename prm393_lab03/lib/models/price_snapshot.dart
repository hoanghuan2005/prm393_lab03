import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum PriceSource {
  manual('manual'),
  demo('demo'),

  /// Read from the Shopee page by the Chrome extension
  extensionPage('extensionPage'),

  /// "Giá người khác ghi" the user chose to use as their own (spec 8.3); never shared again
  community('community');

  final String key;

  const PriceSource(this.key);

  static PriceSource fromKey(String? key) => PriceSource.values.firstWhere(
    (s) => s.key == key,
    orElse: () => PriceSource.manual,
  );
}

/// How the extension read the price; app-written snapshots are always [single]
enum PriceType {
  single('single'),
  range('range'),
  flash('flash'),

  /// Personal reference only: never the item's main price, never compared with list prices
  afterVoucher('afterVoucher');

  final String key;

  const PriceType(this.key);

  static PriceType fromKey(String? key) => PriceType.values.firstWhere(
    (t) => t.key == key,
    orElse: () => PriceType.single,
  );
}

/// users/{uid}/wishlistItems/{itemId}/priceSnapshots/{snapshotId} — append-only
class PriceSnapshot {
  final String id;

  /// Always present; the lowest price for a [PriceType.range]
  final int amountVnd;
  final PriceSource source;
  final DateTime observedAt;
  final PriceType priceType;
  final int? minVnd;
  final int? maxVnd;

  /// Crossed-out price shown on the page
  final int? originalVnd;

  /// false = read from the page and not yet confirmed by the user
  final bool confirmed;
  final String? variantLabel;

  const PriceSnapshot({
    required this.id,
    required this.amountVnd,
    this.source = PriceSource.manual,
    required this.observedAt,
    this.priceType = PriceType.single,
    this.minVnd,
    this.maxVnd,
    this.originalVnd,
    this.confirmed = true,
    this.variantLabel,
  });

  bool get isRange =>
      priceType == PriceType.range && minVnd != null && maxVnd != null;

  factory PriceSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return PriceSnapshot(
      id: doc.id,
      amountVnd: readInt(data['amountVnd']) ?? 0,
      source: PriceSource.fromKey(readString(data['source'])),
      observedAt: readDate(data['observedAt']) ?? DateTime.now(),
      priceType: PriceType.fromKey(readString(data['priceType'])),
      minVnd: readVnd(data['minVnd']),
      maxVnd: readVnd(data['maxVnd']),
      originalVnd: readVnd(data['originalVnd']),
      confirmed: readString(data['confirmation']) != 'unconfirmed',
      variantLabel: readText(data['variantLabel']),
    );
  }

  Map<String, dynamic> toMap() => {
    'amountVnd': amountVnd,
    'source': source.key,
    'observedAt': Timestamp.fromDate(observedAt),
    'priceType': priceType.key,
    if (minVnd != null) 'minVnd': minVnd,
    if (maxVnd != null) 'maxVnd': maxVnd,
    if (originalVnd != null) 'originalVnd': originalVnd,
    'confirmation': confirmed ? 'userConfirmed' : 'unconfirmed',
    if (variantLabel != null) 'variantLabel': variantLabel,
  };

  PriceSnapshot copyWith({
    String? id,
    int? amountVnd,
    PriceSource? source,
    DateTime? observedAt,
    PriceType? priceType,
    int? minVnd,
    int? maxVnd,
    int? originalVnd,
    bool? confirmed,
    String? variantLabel,
  }) {
    return PriceSnapshot(
      id: id ?? this.id,
      amountVnd: amountVnd ?? this.amountVnd,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
      priceType: priceType ?? this.priceType,
      minVnd: minVnd ?? this.minVnd,
      maxVnd: maxVnd ?? this.maxVnd,
      originalVnd: originalVnd ?? this.originalVnd,
      confirmed: confirmed ?? this.confirmed,
      variantLabel: variantLabel ?? this.variantLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceSnapshot &&
          other.id == id &&
          other.amountVnd == amountVnd &&
          other.source == source &&
          other.observedAt == observedAt &&
          other.priceType == priceType &&
          other.minVnd == minVnd &&
          other.maxVnd == maxVnd &&
          other.originalVnd == originalVnd &&
          other.confirmed == confirmed &&
          other.variantLabel == variantLabel;

  @override
  int get hashCode => Object.hash(
    id,
    amountVnd,
    source,
    observedAt,
    priceType,
    minVnd,
    maxVnd,
    originalVnd,
    confirmed,
    variantLabel,
  );
}
