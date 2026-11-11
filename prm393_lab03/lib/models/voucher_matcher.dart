import 'voucher.dart';
import 'wishlist_item.dart';

/// The one place that decides whether a voucher applies to a wishlist item.
/// Pure: the caller passes `now` (DateTime.now() in the widget/ViewModel), so tests
/// can fix the date.
class VoucherMatcher {
  VoucherMatcher._();

  /// Vouchers last until the end of `validUntil` in Vietnam time (UTC+7)
  static const Duration _vietnamOffset = Duration(hours: 7);

  static final RegExp _dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static bool canApply(
    Voucher v,
    WishlistItem item,
    int priceVnd,
    DateTime now,
  ) {
    // Shopee vouchers only fit items saved from a Shopee product
    // (`shopee:<shopId>:<itemId>`); typed-in items and Tiki/TikTok/Lazada links
    // have no such key. Demo items never get vouchers.
    if (!(item.productKey?.startsWith('shopee:') ?? false)) return false;
    if (item.isDemo) return false;
    if (!v.isActive) return false;
    final endsAt = _endsAt(v.validUntil);
    if (endsAt == null || !now.toUtc().isBefore(endsAt)) return false;
    if (priceVnd < v.minOrder) return false;

    // Shop name check (unchanged from the old Voucher.canApplyTo): a shop voucher
    // needs the item's shop to match
    if (v.isShopVoucher) {
      final itemShopName = item.shopName;
      if (itemShopName == null || itemShopName.trim().isEmpty) return false;
      final s1 = v.shopName!.toLowerCase().trim();
      final s2 = itemShopName.toLowerCase().trim();
      if (!s1.contains(s2) && !s2.contains(s1)) return false;
    }

    return true;
  }

  /// Discount vouchers that apply, shop vouchers first, then the biggest discount.
  /// Free-shipping vouchers never change the item's price, so they are left out
  /// (see [hasFreeship]).
  /// Empty when the item has no price yet (null or ≤ 0): never treated as 0 ₫.
  static List<Voucher> applicable(
    List<Voucher> all,
    WishlistItem item,
    int? priceVnd,
    DateTime now,
  ) {
    if (priceVnd == null || priceVnd <= 0) return [];
    return all
        .where((v) => !v.isFreeship && canApply(v, item, priceVnd, now))
        .toList()
      ..sort(_shopFirstThenBiggest);
  }

  static int _shopFirstThenBiggest(Voucher a, Voucher b) {
    if (a.isShopVoucher && !b.isShopVoucher) return -1;
    if (!a.isShopVoucher && b.isShopVoucher) return 1;
    return b.discountAmount.compareTo(a.discountAmount);
  }

  /// First of [applicable], or null when none applies or the item has no price
  static Voucher? best(
    List<Voucher> all,
    WishlistItem item,
    int? priceVnd,
    DateTime now,
  ) {
    final list = applicable(all, item, priceVnd, now);
    return list.isEmpty ? null : list.first;
  }

  /// True when a free-shipping voucher passes [canApply] for this item.
  /// False when the item has no price yet (null or ≤ 0).
  static bool hasFreeship(
    List<Voucher> all,
    WishlistItem item,
    int? priceVnd,
    DateTime now,
  ) => freeshipFor(all, item, priceVnd, now) != null;

  /// The free-shipping voucher to show (shop vouchers first, then the biggest
  /// amount), or null when none applies or the item has no price
  static Voucher? freeshipFor(
    List<Voucher> all,
    WishlistItem item,
    int? priceVnd,
    DateTime now,
  ) {
    if (priceVnd == null || priceVnd <= 0) return null;
    final list =
        all
            .where((v) => v.isFreeship && canApply(v, item, priceVnd, now))
            .toList()
          ..sort(_shopFirstThenBiggest);
    return list.isEmpty ? null : list.first;
  }

  /// Midnight Vietnam time after the day `validUntil` (yyyy-MM-dd), as a UTC instant.
  /// Null when empty or not a real date, so the voucher never applies.
  static DateTime? _endsAt(String validUntil) {
    final match = _dateOnly.firstMatch(validUntil.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    // DateTime rolls 2026-02-30 over to March; treat it as invalid
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return DateTime.utc(year, month, day + 1).subtract(_vietnamOffset);
  }
}
