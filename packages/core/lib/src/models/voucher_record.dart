import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Discount off the item price, or free shipping (never taken off the price)
enum VoucherKind {
  discount('discount', 'Giảm giá'),
  freeship('freeship', 'Miễn phí vận chuyển');

  final String key;
  final String label;

  const VoucherKind(this.key, this.label);

  static VoucherKind fromKey(Object? key) =>
      key == freeship.key ? freeship : discount;
}

/// Which items a voucher fits. The labels are what the app compares with the
/// item's budget group (VoucherMatcher.categoryToBudgetGroup in the app).
enum VoucherCategory {
  all('Tất cả'),
  food('Ăn uống'),
  fashion('Thời trang'),
  tech('Công nghệ'),
  beauty('Làm đẹp'),
  study('Học tập');

  final String label;

  const VoucherCategory(this.label);

  static VoucherCategory fromLabel(Object? label) => VoucherCategory.values
      .firstWhere((c) => c.label == label, orElse: () => VoucherCategory.all);
}

/// What staff type in the voucher form (`vouchers/{id}`, decision D-3: real
/// Shopee vouchers only, entered by the team from Shopee's own pages).
class VoucherDraft {
  static const int maxCode = 30;
  static const int maxTitle = 120;
  static const int maxShopName = 100;
  static const int maxSourceUrl = 500;
  static const int maxVnd = 999999999;

  final String code;
  final String title;
  final VoucherKind kind;
  final int discountVnd;
  final int minOrderVnd;
  final VoucherCategory category;

  /// Shopee shop id: a shop voucher only fits that shop's items
  final String? shopId;
  final String? shopName;
  final DateTime validUntil;

  /// Shopee page where the voucher is announced
  final String? sourceUrl;

  const VoucherDraft({
    required this.code,
    required this.title,
    required this.kind,
    required this.discountVnd,
    required this.minOrderVnd,
    required this.category,
    required this.validUntil,
    this.shopId,
    this.shopName,
    this.sourceUrl,
  });

  /// Day only, as "yyyy-MM-dd" (the app reads it in Vietnam time)
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Fields as firestore.rules expects them (without isActive / updatedAt / updatedBy)
  Map<String, dynamic> toMap() {
    String? clean(String? s) {
      final t = s?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return {
      'code': code.trim().toUpperCase(),
      'title': title.trim(),
      'type': kind.key,
      'discountAmount': discountVnd,
      'minOrder': minOrderVnd,
      'category': category.label,
      'shopId': ?clean(shopId),
      'shopName': ?clean(shopName),
      'validUntil': dayKey(validUntil),
      'sourceUrl': ?clean(sourceUrl),
    };
  }
}

/// A voucher as stored in `vouchers/{id}`
class VoucherRecord {
  final String id;
  final VoucherDraft draft;
  final bool isActive;
  final DateTime? updatedAt;

  /// Written by the old admin screen (extra or missing fields): it can only be
  /// archived, or replaced by saving the form
  final bool isLegacy;

  const VoucherRecord({
    required this.id,
    required this.draft,
    required this.isActive,
    this.updatedAt,
    this.isLegacy = false,
  });

  static const _fields = {
    'code',
    'title',
    'type',
    'discountAmount',
    'minOrder',
    'category',
    'shopId',
    'shopName',
    'validUntil',
    'sourceUrl',
    'isActive',
    'updatedAt',
    'updatedBy',
  };

  factory VoucherRecord.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final until = DateTime.tryParse('${data['validUntil'] ?? ''}');
    return VoucherRecord(
      id: doc.id,
      draft: VoucherDraft(
        code: readText(data['code']) ?? '',
        title: readText(data['title']) ?? '',
        kind: VoucherKind.fromKey(data['type']),
        discountVnd: readInt(data['discountAmount']) ?? 0,
        minOrderVnd: readInt(data['minOrder']) ?? 0,
        category: VoucherCategory.fromLabel(data['category']),
        shopId: readText(data['shopId']),
        shopName: readText(data['shopName']),
        validUntil: until == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime(until.year, until.month, until.day),
        sourceUrl:
            readText(data['sourceUrl']) ?? readText(data['affiliateUrl']),
      ),
      isActive: data['isActive'] == true || data['isActive'] == null,
      updatedAt: readDate(data['updatedAt']),
      isLegacy: !data.keys.every(_fields.contains) || until == null,
    );
  }

  /// Usable until the end of [VoucherDraft.validUntil]
  bool isExpired(DateTime now) {
    final d = draft.validUntil;
    return !now.isBefore(DateTime(d.year, d.month, d.day + 1));
  }
}

final RegExp _productLink = RegExp(r'-i\.(\d{1,20})\.(\d{1,20})');
final RegExp _productPath = RegExp(r'shopee\.vn/product/(\d{1,20})/(\d{1,20})');
final RegExp _shopPath = RegExp(r'shopee\.vn/shop/(\d{1,20})');
final RegExp _digitsOnly = RegExp(r'^\d{1,20}$');

/// Shopee shop id from what staff paste: a product link (`…-i.<shop>.<item>`,
/// `shopee.vn/product/<shop>/<item>`), a shop link (`shopee.vn/shop/<shop>`) or
/// the id itself. Null when none of these (a `shopee.vn/<username>` page has
/// no id in its address: open one of its products instead).
String? shopIdFromShopeeLink(String input) {
  final text = input.trim();
  if (_digitsOnly.hasMatch(text)) return text;
  for (final re in [_productLink, _productPath, _shopPath]) {
    final m = re.firstMatch(text);
    if (m != null) return m.group(1);
  }
  return null;
}
