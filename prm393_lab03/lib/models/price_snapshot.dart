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

  /// "Giá đang giảm" read by the extension; only the main price when the item has
  /// no other price (see [PriceInsights.comparable])
  sale('sale'),

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

  /// Sale name / voucher code the extension saved with the price ("11.11")
  final String? saleLabel;

  /// Shop and ratings on the page when the extension read this price
  final String? shopName;
  final double? productRating;
  final int? productRatingCount;
  final double? shopRating;

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
    this.saleLabel,
    this.shopName,
    this.productRating,
    this.productRatingCount,
    this.shopRating,
  });

  bool get isRange =>
      priceType == PriceType.range && minVnd != null && maxVnd != null;

  /// Discount from the crossed-out price, 0 when there is none
  int get discountPercent {
    final orig = originalVnd;
    if (orig == null || orig <= amountVnd) return 0;
    return ((orig - amountVnd) * 100 / orig).round();
  }

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
      saleLabel: readText(data['saleLabel']),
      shopName: readText(data['shopName']),
      productRating: readRating(data['productRating']),
      productRatingCount: readCount(data['productRatingCount']),
      shopRating: readRating(data['shopRating']),
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
    if (saleLabel != null) 'saleLabel': saleLabel,
    if (shopName != null) 'shopName': shopName,
    if (productRating != null) 'productRating': productRating,
    if (productRatingCount != null) 'productRatingCount': productRatingCount,
    if (shopRating != null) 'shopRating': shopRating,
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
    String? saleLabel,
    String? shopName,
    double? productRating,
    int? productRatingCount,
    double? shopRating,
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
      saleLabel: saleLabel ?? this.saleLabel,
      shopName: shopName ?? this.shopName,
      productRating: productRating ?? this.productRating,
      productRatingCount: productRatingCount ?? this.productRatingCount,
      shopRating: shopRating ?? this.shopRating,
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
          other.variantLabel == variantLabel &&
          other.saleLabel == saleLabel &&
          other.shopName == shopName &&
          other.productRating == productRating &&
          other.productRatingCount == productRatingCount &&
          other.shopRating == shopRating;

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
    saleLabel,
    shopName,
    productRating,
    productRatingCount,
    shopRating,
  );
}
