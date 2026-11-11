import 'package:flutter/foundation.dart';

import '../core/utils/vietnamese_text.dart';
import 'price_snapshot.dart';
import 'shopee_link.dart';
import 'voucher.dart';
import 'wishlist_item.dart';

/// The price vouchers are computed on: the latest list price, the lowest one for a
/// range ([isRange]: show the price after voucher as "từ …")
typedef ListPrice = ({int amountVnd, bool isRange});

/// The one place that decides whether a voucher applies to a wishlist item.
/// Pure: the caller passes `now` (DateTime.now() in the widget/ViewModel), so tests
/// can fix the date.
class VoucherMatcher {
  VoucherMatcher._();

  /// Vouchers last until the end of `validUntil` in Vietnam time (UTC+7)
  static const Duration _vietnamOffset = Duration(hours: 7);

  static final RegExp _dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Voucher.category for vouchers that fit every item
  static const String allCategories = 'Tất cả';

  /// Voucher.category → the item's budgetGroupId it fits. Items in 'other' or
  /// without a group only get [allCategories] vouchers.
  static const Map<String, String> categoryToBudgetGroup = {
    'Ăn uống': 'food',
    'Thời trang': 'fashion',
    'Công nghệ': 'tech',
    'Làm đẹp': 'beauty',
    'Học tập': 'study',
  };

  /// Unknown categories already logged, so each is logged once
  static final Set<String> _loggedCategories = {};

  /// Latest list price of [item] for voucher maths.
  ///
  /// [history] is the item's price snapshots (any order), e.g.
  /// `DecisionSupportViewModel.priceInsightsFor(item)?.history`:
  /// - Not loaded (null): null, the list price is not known yet.
  /// - Loaded but empty (an item priced before snapshots existed):
  ///   [WishlistItem.latestPriceVnd] as a single price when > 0.
  /// - Otherwise "sau voucher" prices are skipped and a range gives its lowest
  ///   price, isRange; only "sau voucher" prices: null.
  static ListPrice? listPriceFor(
    WishlistItem item, {
    List<PriceSnapshot>? history,
  }) {
    if (history == null) return null;
    if (history.isEmpty) {
      final price = item.latestPriceVnd;
      return price == null || price <= 0
          ? null
          : (amountVnd: price, isRange: false);
    }
    final listed =
        history
            .where(
              (s) => s.priceType != PriceType.afterVoucher && s.amountVnd > 0,
            )
            .toList()
          ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    if (listed.isEmpty) return null;
    final latest = listed.first;
    final isRange = latest.priceType == PriceType.range;
    return (
      amountVnd: isRange
          ? (latest.minVnd ?? latest.amountVnd)
          : latest.amountVnd,
      isRange: isRange,
    );
  }

  /// List price for a wishlist card, which never loads the price history itself:
  /// [listPriceFor] when the history is loaded, otherwise the saved
  /// [WishlistItem.latestPriceVnd]. That field is never a "sau voucher" price: the
  /// app saves list prices only and the extension skips them (`latestPriceOf` in
  /// `chrome_extension/lib/firebaseMap.ts`), so no voucher is taken off twice.
  /// Whether it is a range is unknown here, so isRange is false.
  static ListPrice? cardListPrice(
    WishlistItem item, {
    List<PriceSnapshot>? history,
  }) {
    if (history != null) return listPriceFor(item, history: history);
    final price = item.latestPriceVnd;
    return price == null || price <= 0
        ? null
        : (amountVnd: price, isRange: false);
  }

  /// Price after [voucher] on [listPriceVnd], never below 0
  static int priceAfter(int listPriceVnd, Voucher voucher) {
    final after = listPriceVnd - voucher.discountAmount;
    return after < 0 ? 0 : after;
  }

  static bool canApply(
    Voucher v,
    WishlistItem item,
    int priceVnd,
    DateTime now,
  ) {
    // Shopee vouchers only fit items saved from a Shopee product: a well-formed
    // `shopee:<shopId>:<itemId>` key. Typed-in items, Tiki/TikTok/Lazada links
    // and malformed keys never match. Demo items never get vouchers.
    final link = ShopeeLink.fromProductKey(item.productKey);
    if (link == null) return false;
    if (item.isDemo) return false;
    if (!v.isActive) return false;
    final endsAt = _endsAt(v.validUntil);
    if (endsAt == null || !now.toUtc().isBefore(endsAt)) return false;
    if (priceVnd < v.minOrder) return false;
    if (!_categoryFits(v.category, item.budgetGroupId)) return false;

    if (v.isShopVoucher && !_shopFits(v, link.shopId, item.shopName)) {
      return false;
    }

    return true;
  }

  /// A shop voucher fits only its own shop: the same Shopee shop id when the
  /// voucher has one, otherwise exactly the same shop name (after
  /// [normalizeShopName]). Never a partial name: "Perseper" is not
  /// "Perseper Official".
  static bool _shopFits(Voucher v, String itemShopId, String? itemShopName) {
    final shopId = v.shopId?.trim();
    if (shopId != null && shopId.isNotEmpty) return shopId == itemShopId;
    final wanted = normalizeShopName(v.shopName ?? '');
    final actual = normalizeShopName(itemShopName ?? '');
    return wanted.isNotEmpty && wanted == actual;
  }

  /// Lowercase, no Vietnamese diacritics, single spaces, trimmed:
  /// " Mây  Decor " → "may decor"
  static String normalizeShopName(String name) => removeVietnameseDiacritics(
    name,
  ).toLowerCase().trim().replaceAll(_spaces, ' ');

  static final RegExp _spaces = RegExp(r'\s+');

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

  /// [allCategories], or the category maps to the item's budget group.
  /// An unknown category never fits.
  static bool _categoryFits(String category, String? budgetGroupId) {
    if (category == allCategories) return true;
    final group = categoryToBudgetGroup[category];
    if (group == null) {
      if (_loggedCategories.add(category)) {
        debugPrint('VoucherMatcher: unknown voucher category "$category"');
      }
      return false;
    }
    return group == budgetGroupId;
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
