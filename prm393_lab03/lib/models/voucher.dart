import '../core/utils/vietnamese_text.dart';

class Voucher {
  final String id;
  final String code;
  final String title;
  final int discountAmount; // VND (e.g. 50000)
  final int minOrder; // VND (e.g. 250000)
  final String validUntil;
  final String affiliateUrl;
  final bool isActive;
  final String category;
  final String? shopName; // Tên shop cụ thể (nếu là voucher riêng của shop)

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
    this.affiliateUrl = '',
    this.isActive = true,
    this.category = 'Tất cả',
    this.shopName,
    this.type = typeDiscount,
  });

  bool get isShopVoucher => shopName != null && shopName!.trim().isNotEmpty;

  bool get isFreeship => type == typeFreeship;

  factory Voucher.fromFirestore(Map<String, dynamic> data, String id) {
    return Voucher(
      id: id,
      code: data['code']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      minOrder: (data['minOrder'] as num?)?.toInt() ?? 0,
      validUntil: data['validUntil']?.toString() ?? '',
      affiliateUrl: data['affiliateUrl']?.toString() ?? '',
      isActive: data['isActive'] == true || data['isActive'] == null,
      category: data['category']?.toString() ?? 'Tất cả',
      shopName: data['shopName']?.toString(),
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
