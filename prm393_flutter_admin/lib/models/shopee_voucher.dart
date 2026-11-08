import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';

/// Who gives the voucher (field `scope` written by the Chrome extension)
enum VoucherScope {
  shop('shop', 'Mã của shop'),
  platform('platform', 'Mã Shopee'),
  payment('payment', 'Ưu đãi thanh toán'),
  unknown('unknown', 'Khác');

  final String key;
  final String label;

  const VoucherScope(this.key, this.label);

  static VoucherScope fromKey(Object? key) => values.firstWhere(
    (s) => s.key == key,
    orElse: () => VoucherScope.unknown,
  );
}

/// One voucher scraped by an admin / staff from a Shopee page with the
/// extension (lab build), read from `shopeeVouchers/{id}`.
class ShopeeVoucher {
  final String id;

  /// Text as shown on the page
  final String raw;

  /// amount, percent, shipping, coin, bundle or unknown
  final String kind;
  final VoucherScope scope;

  /// Used up / out of uses when it was scraped
  final bool unavailable;
  final String sourceUrl;
  final String capturedBy;
  final DateTime? lastSeenAt;
  final int? amountVnd;
  final int? percent;
  final int? capVnd;
  final int? minSpendVnd;
  final int? usedPct;
  final int? minQty;
  final String? expiresText;

  /// "2026-10-31" when the page showed the full date
  final String? expiresDate;

  /// Not usable yet: "00:00 11/11" or "còn 2 giờ"
  final String? startsText;

  /// Sale the voucher belongs to: "11.11 · Siêu Sale"
  final String? saleLabel;

  /// "Áp dụng cho …" as written on the voucher
  final String? appliesText;
  final String? shopId;
  final String? shopName;
  final String? productTitle;

  const ShopeeVoucher({
    required this.id,
    required this.raw,
    this.kind = 'unknown',
    this.scope = VoucherScope.unknown,
    this.unavailable = false,
    this.sourceUrl = '',
    this.capturedBy = '',
    this.lastSeenAt,
    this.amountVnd,
    this.percent,
    this.capVnd,
    this.minSpendVnd,
    this.usedPct,
    this.minQty,
    this.expiresText,
    this.expiresDate,
    this.startsText,
    this.saleLabel,
    this.appliesText,
    this.shopId,
    this.shopName,
    this.productTitle,
  });

  factory ShopeeVoucher.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return ShopeeVoucher(
      id: doc.id,
      raw: readText(data['raw']) ?? '',
      kind: readText(data['kind']) ?? 'unknown',
      scope: VoucherScope.fromKey(data['scope']),
      unavailable: data['unavailable'] == true,
      sourceUrl: readText(data['sourceUrl']) ?? '',
      capturedBy: readText(data['capturedBy']) ?? '',
      lastSeenAt: readDate(data['lastSeenAt']),
      amountVnd: readInt(data['amountVnd']),
      percent: readInt(data['percent']),
      capVnd: readInt(data['capVnd']),
      minSpendVnd: readInt(data['minSpendVnd']),
      usedPct: readInt(data['usedPct']),
      minQty: readInt(data['minQty']),
      expiresText: readText(data['expiresText']),
      expiresDate: readText(data['expiresDate']),
      startsText: readText(data['startsText']),
      saleLabel: readText(data['saleLabel']),
      appliesText: readText(data['appliesText']),
      shopId: readText(data['shopId']),
      shopName: _realShopName(readText(data['shopName'])),
      productTitle: readText(data['productTitle']),
    );
  }

  /// Older extension builds could save a status line of the shop box
  /// ("Không có sẵn", "Online 5 phút trước"…) as the shop name: ignore it.
  static final _notAShopName = RegExp(
    r'có sẵn|hết hàng|online|hoạt động|truy cập|phản hồi|theo dõi|tham gia|'
    r'^(xem shop|chat ngay|chat|đánh giá|sản phẩm)$',
    caseSensitive: false,
  );

  static String? _realShopName(String? name) =>
      name == null || _notAShopName.hasMatch(name) ? null : name;

  /// "Giảm 20.000 ₫", "Giảm 10% tối đa 50.000 ₫", "Miễn phí vận chuyển"…
  String get valueLabel {
    switch (kind) {
      case 'amount' when amountVnd != null:
        return 'Giảm ${formatVnd(amountVnd!)}';
      case 'percent' when percent != null:
        return capVnd == null
            ? 'Giảm $percent%'
            : 'Giảm $percent% tối đa ${formatVnd(capVnd!)}';
      case 'shipping':
        return amountVnd == null
            ? 'Miễn phí vận chuyển'
            : 'Giảm ${formatVnd(amountVnd!)} phí vận chuyển';
      case 'coin':
        return percent == null ? 'Hoàn xu' : 'Hoàn $percent% xu';
      case 'bundle':
        return minQty == null ? 'Combo mua nhiều' : 'Combo từ $minQty món';
      default:
        return 'Voucher';
    }
  }

  /// Where the voucher can be used: the shop for a shop voucher, the whole
  /// platform for a Shopee voucher, or the "Áp dụng cho …" text if any.
  /// A voucher scraped from a product page is one Shopee offers for that
  /// product, so it can be used at that product's shop whatever its scope.
  String? get usableAt {
    if (shopName != null && (shopId != null || scope == VoucherScope.shop)) {
      return 'Dùng được tại shop $shopName';
    }
    if (appliesText != null) return appliesText;
    if (scope == VoucherScope.platform) return 'Toàn sàn Shopee';
    return null;
  }

  /// Same voucher text whatever shop it was scraped at (platform vouchers
  /// appear once per shop)
  String get sameVoucherKey => raw.toLowerCase();

  /// "Đơn tối thiểu 99.000 ₫ · HSD 30.11 · Đã dùng 80%"
  String get conditionLabel => [
    if (minSpendVnd != null && minSpendVnd! > 0)
      'Đơn tối thiểu ${formatVnd(minSpendVnd!)}',
    if (startsText != null) 'Bắt đầu $startsText',
    if (expiresDate != null)
      'HSD ${expiresDate!.split('-').reversed.join('/')}'
    else if (expiresText != null)
      'HSD $expiresText',
    if (usedPct != null) 'Đã dùng $usedPct%',
  ].join(' · ');
}
