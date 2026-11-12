import '../core/utils/vietnamese_text.dart';

/// A Shopee voucher the team entered on the web admin ("Mã giảm giá"), read
/// from `vouchers/{id}`. Only real codes: the app has no built-in sample list.
class Voucher {
  final String id;
  final String code;
  final String title;
  final int discountAmount; // VND (e.g. 50000)
  final int minOrder; // VND (e.g. 250000)
  final String validUntil;

  /// Where the team saw the voucher announced (Shopee page); may be empty
  final String sourceUrl;
  final bool isActive;
  final String category;

  /// Shopee shop id (`shopee:<shopId>:<itemId>`): a shop voucher matches by it
  final String? shopId;

  /// Shop name, shown as "Mã của shop …"; matches only when it is exactly the
  /// item's shop name and the voucher has no [shopId]
  final String? shopName;

  /// [typeDiscount] (giảm vào giá món) hoặc [typeFreeship] (miễn phí vận chuyển,
  /// không trừ vào giá món)
  final String type;

  static const String typeDiscount = 'discount';
  static const String typeFreeship = 'freeship';

  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.discountAmount,
    required this.minOrder,
    required this.validUntil,
    this.sourceUrl = '',
    this.isActive = true,
    this.category = 'Tất cả',
    this.shopId,
    this.shopName,
    this.type = typeDiscount,
  });

  bool get isShopVoucher =>
      (shopId != null && shopId!.trim().isNotEmpty) ||
      (shopName != null && shopName!.trim().isNotEmpty);

  bool get isFreeship => type == typeFreeship;

  factory Voucher.fromFirestore(Map<String, dynamic> data, String id) {
    String? text(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    return Voucher(
      id: id,
      code: data['code']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      minOrder: (data['minOrder'] as num?)?.toInt() ?? 0,
      validUntil: data['validUntil']?.toString() ?? '',
      // `affiliateUrl`: documents written by the old admin screen
      sourceUrl: text(data['sourceUrl']) ?? text(data['affiliateUrl']) ?? '',
      isActive: data['isActive'] == true || data['isActive'] == null,
      category: data['category']?.toString() ?? 'Tất cả',
      shopId: text(data['shopId']),
      shopName: text(data['shopName']),
      type: _readType(data),
    );
  }

  static String _readType(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase();
    if (type == typeFreeship || type == typeDiscount) return type!;
    // TẠM THỜI, chỉ cho tài liệu cũ thiếu "type" (hoặc type lạ): đoán freeship
    // từ code/title. Bỏ khi mọi voucher trên Firestore đã có "type".
    final text = removeVietnameseDiacritics(
      '${data['code'] ?? ''} ${data['title'] ?? ''}',
    ).toLowerCase();
    const freeshipHints = ['freeship', 'free ship', 'mien phi van chuyen'];
    return freeshipHints.any(text.contains) ? typeFreeship : typeDiscount;
  }
}
