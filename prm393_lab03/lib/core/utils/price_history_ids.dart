import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Document ids of priceHistory/{productKey}/reports. The day is always the date in
/// Vietnam (UTC+7), whatever the phone's time zone, so firestore.rules computes the
/// same id from observedAt.
abstract final class PriceHistoryIds {
  static const vietnamOffset = Duration(hours: 7);

  /// `yyyyMMdd` of [date] in Vietnam time
  static String dayKey(DateTime date) {
    final vn = date.toUtc().add(vietnamOffset);
    return '${vn.year.toString().padLeft(4, '0')}'
        '${vn.month.toString().padLeft(2, '0')}'
        '${vn.day.toString().padLeft(2, '0')}';
  }

  /// sha256("uid|productKey|modelKey|yyyyMMdd") in lowercase hex: one report per person,
  /// product variant and day; the uid itself is never stored
  static String userReportId(
    String uid,
    String productKey,
    String modelKey,
    DateTime date,
  ) => sha256
      .convert(utf8.encode('$uid|$productKey|$modelKey|${dayKey(date)}'))
      .toString();

  /// Sample data: `demo<n>_<modelKey>_<yyyyMMdd>`, n = 1, 2, … within the day
  static String demoReportId(int n, String modelKey, DateTime date) =>
      'demo${n}_${modelKey}_${dayKey(date)}';
}
