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
      shopId: readText(data['shopId']),
      shopName: readText(data['shopName']),
      productTitle: readText(data['productTitle']),
    );
  }

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

  /// "Đơn tối thiểu 99.000 ₫ · HSD 30.11 · Đã dùng 80%"
  String get conditionLabel => [
    if (minSpendVnd != null && minSpendVnd! > 0)
      'Đơn tối thiểu ${formatVnd(minSpendVnd!)}',
    if (expiresText != null) 'HSD $expiresText',
    if (usedPct != null) 'Đã dùng $usedPct%',
  ].join(' · ');
}
