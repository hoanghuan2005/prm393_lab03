class Voucher {
  final String id;
  final String code;
  final String title;
  final String platform; // 'Shopee', 'Lazada', 'Tất cả'
  final int discountAmount; // VND (e.g. 50000)
  final int minOrder; // VND (e.g. 250000)
  final String validUntil;
  final String affiliateUrl;
  final bool isActive;
  final String category;
  final String? shopName; // Tên shop cụ thể (nếu là voucher riêng của shop)

  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.platform,
    required this.discountAmount,
    required this.minOrder,
    required this.validUntil,
    this.affiliateUrl = '',
    this.isActive = true,
    this.category = 'Tất cả',
    this.shopName,
  });

  bool get isShopVoucher => shopName != null && shopName!.trim().isNotEmpty;

  factory Voucher.fromFirestore(Map<String, dynamic> data, String id) {
    return Voucher(
      id: id,
      code: data['code']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      platform: data['platform']?.toString() ?? 'Shopee',
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      minOrder: (data['minOrder'] as num?)?.toInt() ?? 0,
      validUntil: data['validUntil']?.toString() ?? '',
      affiliateUrl: data['affiliateUrl']?.toString() ?? '',
      isActive: data['isActive'] == true || data['isActive'] == null,
      category: data['category']?.toString() ?? 'Tất cả',
      shopName: data['shopName']?.toString(),
    );
  }

  /// Checks if this voucher can be applied to an item based on price, platform and shopName
  bool canApplyTo({
    required int priceVnd,
    String? itemPlatform,
    String? itemShopName,
  }) {
    if (!isActive) return false;
    if (priceVnd < minOrder) return false;

    // Platform check
    if (platform != 'Tất cả' && itemPlatform != null && itemPlatform.trim().isNotEmpty) {
      final p1 = platform.toLowerCase();
      final p2 = itemPlatform.toLowerCase();
      if (!p1.contains(p2) && !p2.contains(p1)) {
        return false;
      }
    }

    // Shop name check: if voucher belongs to a specific shop, item must match
    if (isShopVoucher) {
      if (itemShopName == null || itemShopName.trim().isEmpty) return false;
      final s1 = shopName!.toLowerCase().trim();
      final s2 = itemShopName.toLowerCase().trim();
      if (!s1.contains(s2) && !s2.contains(s1)) {
        return false;
      }
    }

    return true;
  }
}
