import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Price kinds of "Biểu đồ giá tham khảo". Separate from [PriceType] of the
/// personal price snapshots, which has no [sale].
enum HistoryPriceType {
  single('single'),
  range('range'),
  flash('flash'),
  sale('sale'),

  /// Stored, but never in the lowest price, the median or a shop comparison;
  /// only shown on its own as "sau voucher, tham khảo"
  afterVoucher('afterVoucher');

  final String key;

  const HistoryPriceType(this.key);

  bool get countsAsListPrice => this != afterVoucher;

  static HistoryPriceType fromKey(String? key) => HistoryPriceType.values
      .firstWhere((t) => t.key == key, orElse: () => HistoryPriceType.single);
}

enum HistoryReportSource {
  manual('manual'),
  extensionPage('extensionPage'),

  /// Sample data: always labelled "Dữ liệu mẫu"
  demo('demo');

  final String key;

  const HistoryReportSource(this.key);

  static HistoryReportSource fromKey(String? key) =>
      HistoryReportSource.values.firstWhere(
        (s) => s.key == key,
        orElse: () => HistoryReportSource.manual,
      );
}

/// A rating in (0, 5] rounded to 1 decimal; anything else is null
double? _readRating(Object? value) {
  final v = value is num ? value.toDouble() : null;
  if (v == null || v <= 0 || v > 5) return null;
  return (v * 10).round() / 10;
}

/// priceHistory/{productKey}, productKey = `shopee:<shopId>:<itemId>`
class PriceHistoryProduct {
  final String productKey;
  final String title;
  final String shopId;
  final String itemId;
  final String shopName;
  final String? groupId;
  final bool isDemo;
  final DateTime createdAt;

  const PriceHistoryProduct({
    required this.productKey,
    required this.title,
    required this.shopId,
    required this.itemId,
    required this.shopName,
    this.groupId,
    this.isDemo = false,
    required this.createdAt,
  });

  factory PriceHistoryProduct.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return PriceHistoryProduct(
      productKey: doc.id,
      title: readString(data['title']) ?? '',
      shopId: readString(data['shopId']) ?? '',
      itemId: readString(data['itemId']) ?? '',
      shopName: readString(data['shopName']) ?? '',
      groupId: readText(data['groupId']),
      isDemo: data['isDemo'] == true,
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'shopId': shopId,
    'itemId': itemId,
    'shopName': shopName,
    if (groupId != null) 'groupId': groupId,
    'isDemo': isDemo,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// priceHistory/{productKey}/reports/{reportId}
class PriceHistoryReport {
  final String id;
  final int amountVnd;
  final HistoryPriceType priceType;

  /// `none` or the Shopee model id
  final String modelKey;
  final DateTime observedAt;
  final HistoryReportSource source;
  final String? shopName;
  final double? productRating;
  final int? productRatingCount;
  final double? shopRating;

  const PriceHistoryReport({
    required this.id,
    required this.amountVnd,
    this.priceType = HistoryPriceType.single,
    this.modelKey = 'none',
    required this.observedAt,
    this.source = HistoryReportSource.manual,
    this.shopName,
    this.productRating,
    this.productRatingCount,
    this.shopRating,
  });

  bool get countsAsListPrice => priceType.countsAsListPrice;

  bool get isDemo => source == HistoryReportSource.demo;

  factory PriceHistoryReport.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final count = readInt(data['productRatingCount']);
    return PriceHistoryReport(
      id: doc.id,
      amountVnd: readInt(data['amountVnd']) ?? 0,
      priceType: HistoryPriceType.fromKey(readString(data['priceType'])),
      modelKey: readText(data['modelKey']) ?? 'none',
      observedAt: readDate(data['observedAt']) ?? DateTime.now(),
      source: HistoryReportSource.fromKey(readString(data['source'])),
      shopName: readText(data['shopName']),
      productRating: _readRating(data['productRating']),
      productRatingCount: count == null || count < 0 ? null : count,
      shopRating: _readRating(data['shopRating']),
    );
  }

  Map<String, dynamic> toMap() => {
    'amountVnd': amountVnd,
    'priceType': priceType.key,
    'modelKey': modelKey,
    'observedAt': Timestamp.fromDate(observedAt),
    'source': source.key,
    if (shopName != null) 'shopName': shopName,
    if (productRating != null) 'productRating': productRating,
    if (productRatingCount != null) 'productRatingCount': productRatingCount,
    if (shopRating != null) 'shopRating': shopRating,
  };
}

/// productGroups/{groupId}: the same item sold by several shops (grouped by
/// hand, never by comparing titles)
class ProductGroup {
  final String id;
  final String name;
  final List<String> productKeys;
  final bool isDemo;

  const ProductGroup({
    required this.id,
    required this.name,
    this.productKeys = const [],
    this.isDemo = false,
  });

  factory ProductGroup.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final keys = data['productKeys'];
    return ProductGroup(
      id: doc.id,
      name: readString(data['name']) ?? '',
      productKeys: keys is List ? keys.whereType<String>().toList() : const [],
      isDemo: data['isDemo'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'productKeys': productKeys,
    'isDemo': isDemo,
  };
}
