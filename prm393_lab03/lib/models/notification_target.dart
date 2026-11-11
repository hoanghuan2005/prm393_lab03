/// Where a tapped push notification leads. Set in the FCM message's custom data
/// (Firebase Console → Messaging → Additional options → Custom data):
/// `type` = `sale` | `review` | `reflection`; for a sale also
/// `sale_type` = `double_day` | `mid_month` | `payday` and optionally `sale_id`
/// (the day, `yyyy-MM-dd`, as in Remote Config `sale_calendar`).
enum NotificationTarget {
  /// "Danh sách cho đợt sale" (spec 8.2): the sale in `sale_id`, else the next one
  saleList,

  /// Wishlist filtered to "Cần xem lại"
  reviewDue,

  /// Chiêm nghiệm tháng
  reflection,

  /// Unknown type, or a sale reminder while `sale_reminder_enabled` is off: just open the app
  none,
}

class NotificationRoute {
  NotificationRoute._();

  static const String typeKey = 'type';
  static const String saleTypeKey = 'sale_type';
  static const String saleIdKey = 'sale_id';

  /// `yyyy-MM` of the month a reflection notification is about (optional)
  static const String monthKey = 'month';

  static const String typeSale = 'sale';
  static const String typeReview = 'review';
  static const String typeReflection = 'reflection';

  /// Values of the `sale_type` Analytics parameter (analytics-plan.md)
  static const List<String> saleTypes = ['double_day', 'mid_month', 'payday'];

  static bool isSale(Map<String, dynamic> data) => data[typeKey] == typeSale;

  /// The month in `month` (`yyyy-MM`), or null when missing or malformed
  static DateTime? monthOf(Map<String, dynamic> data) {
    final value = data[monthKey];
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(int.parse(match.group(1)!), month);
  }

  static NotificationTarget targetFor(
    Map<String, dynamic> data, {
    required bool saleRemindersEnabled,
  }) => switch (data[typeKey]) {
    typeSale when saleRemindersEnabled => NotificationTarget.saleList,
    typeReview => NotificationTarget.reviewDue,
    typeReflection => NotificationTarget.reflection,
    _ => NotificationTarget.none,
  };

  /// Only the planned values reach Analytics; anything else is reported as `other`
  static String saleTypeOf(Map<String, dynamic> data) {
    final value = data[saleTypeKey];
    return value is String && saleTypes.contains(value) ? value : 'other';
  }
}
