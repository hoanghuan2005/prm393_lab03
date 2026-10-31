/// Where a tapped push notification leads. Set in the FCM message's custom data
/// (Firebase Console → Messaging → Additional options → Custom data):
/// `type` = `sale` | `review` | `reflection`; for a sale also
/// `sale_type` = `double_day` | `mid_month` | `payday`.
enum NotificationTarget {
  /// Wishlist filtered to "Đang cân nhắc", to look at items before a sale
  saleConsidering,

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

  static const String typeSale = 'sale';
  static const String typeReview = 'review';
  static const String typeReflection = 'reflection';

  /// Values of the `sale_type` Analytics parameter (analytics-plan.md)
  static const List<String> saleTypes = ['double_day', 'mid_month', 'payday'];

  static bool isSale(Map<String, dynamic> data) => data[typeKey] == typeSale;

  static NotificationTarget targetFor(
    Map<String, dynamic> data, {
    required bool saleRemindersEnabled,
  }) => switch (data[typeKey]) {
    typeSale when saleRemindersEnabled => NotificationTarget.saleConsidering,
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
