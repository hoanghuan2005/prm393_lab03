/// Every Analytics event name used by the app (docs/analytics-plan.md).
/// AppAnalyticsService only logs these names.
abstract final class AnalyticsEvents {
  static const login = 'login';
  static const logout = 'logout';
  static const search = 'search';
  static const addToWishlist = 'add_to_wishlist';
  static const viewItemDetail = 'view_item_detail';
  static const makeDecision = 'make_decision';
  static const purchaseRecorded = 'purchase_recorded';
  static const budgetSet = 'budget_set';
  static const exportReport = 'export_report';
  static const clickSaleReminder = 'click_sale_reminder';
}

/// Parameter names. No PII: never email, display name, item title, search text or exact
/// amounts — money is sent as [AmountBucket].
abstract final class AnalyticsParams {
  static const method = 'method';
  static const sessionDurationSec = 'session_duration_sec';
  static const queryLength = 'query_length';
  static const resultCount = 'result_count';
  static const motive = 'motive';
  static const hasPrice = 'has_price';
  static const amountBucket = 'amount_bucket';
  static const daysInCooldown = 'days_in_cooldown';
  static const decision = 'decision';
  static const budgetGroup = 'budget_group';
  static const month = 'month';
  static const fileFormat = 'file_format';
  static const itemCount = 'item_count';
  static const saleType = 'sale_type';
}

/// Values of [AnalyticsParams.decision]
abstract final class AnalyticsDecisions {
  static const buy = 'buy';
  static const wait = 'wait';
  static const skip = 'skip';
}

/// Rough size of an amount, so exact prices never leave the device
enum AmountBucket {
  lt100k('lt_100k'),
  from100kTo500k('100k_500k'),
  gt500k('gt_500k');

  final String value;

  const AmountBucket(this.value);

  /// < 100.000 ₫ · 100.000–500.000 ₫ · > 500.000 ₫
  static AmountBucket of(int amountVnd) {
    if (amountVnd < 100000) return AmountBucket.lt100k;
    if (amountVnd <= 500000) return AmountBucket.from100kTo500k;
    return AmountBucket.gt500k;
  }
}
