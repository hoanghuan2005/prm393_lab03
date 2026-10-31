import 'dart:convert';

import 'package:flutter/foundation.dart';

enum SaleType {
  doubleDay('double_day'),
  midMonth('mid_month'),
  payday('payday'),
  other('other');

  final String key;

  const SaleType(this.key);

  static SaleType fromKey(Object? key) => SaleType.values.firstWhere(
    (t) => t.key == key,
    orElse: () => SaleType.other,
  );
}

/// A public sale day (spec 8.2). The team enters announced sales in Remote Config
/// `sale_calendar` as confirmed (Shopee published it) or expected. Days that follow the
/// public pattern (double days, the 15th, the 25th) are added as expected. Only
/// confirmed sales count in the Decision Card.
class SaleEvent {
  final String id;
  final String name;
  final DateTime date;
  final SaleType type;
  final bool confirmed;

  const SaleEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.confirmed,
  });

  /// 0 on the sale day itself
  int daysUntil(DateTime now) => DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;

  static String dayId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class SaleCalendar {
  SaleCalendar._();

  /// How far ahead "Lịch sale" looks
  static const int horizonDays = 60;

  /// Spec 7.4 S6: a confirmed sale within this many days makes "Có thể chờ"
  static const int decisionWindowDays = 7;

  /// Remote Config `sale_calendar`: `[{"date":"2026-11-11","name":"11.11",
  /// "type":"double_day","confirmed":true}]`. Invalid entries are skipped.
  static List<SaleEvent> parse(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map<String, dynamic>) ?_fromJson(e),
      ];
    } on FormatException catch (e) {
      debugPrint('sale_calendar is not valid JSON: $e');
      return const [];
    }
  }

  static SaleEvent? _fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse('${json['date']}');
    final name = json['name'];
    if (date == null || name is! String || name.trim().isEmpty) return null;
    final day = DateTime(date.year, date.month, date.day);
    return SaleEvent(
      id: json['id'] is String ? json['id'] as String : SaleEvent.dayId(day),
      name: name.trim(),
      date: day,
      type: SaleType.fromKey(json['type']),
      confirmed: json['confirmed'] == true,
    );
  }

  /// Expected sales from the public pattern: m.m, the 15th and the 25th of each month
  @visibleForTesting
  static List<SaleEvent> generated(DateTime from, DateTime to) {
    final events = <SaleEvent>[];
    var month = DateTime(from.year, from.month);
    while (!month.isAfter(to)) {
      final m = month.month;
      for (final (day, type, name) in [
        (m, SaleType.doubleDay, '$m.$m'),
        (15, SaleType.midMonth, 'Sale giữa tháng 15.$m'),
        (25, SaleType.payday, 'Sale ngày lương 25.$m'),
      ]) {
        final date = DateTime(month.year, m, day);
        if (date.isBefore(from) || date.isAfter(to)) continue;
        events.add(
          SaleEvent(
            id: SaleEvent.dayId(date),
            name: name,
            date: date,
            type: type,
            confirmed: false,
          ),
        );
      }
      month = DateTime(month.year, month.month + 1);
    }
    return events;
  }

  /// Sales from today to [days] ahead; an event from Remote Config replaces the
  /// generated one on the same day
  static List<SaleEvent> upcoming({
    required List<SaleEvent> configured,
    required DateTime now,
    int days = horizonDays,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(Duration(days: days));
    final byDay = <String, SaleEvent>{
      for (final e in generated(today, end)) SaleEvent.dayId(e.date): e,
    };
    for (final e in configured) {
      if (e.date.isBefore(today) || e.date.isAfter(end)) continue;
      byDay[SaleEvent.dayId(e.date)] = e;
    }
    return byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// First confirmed sale from today, optionally within [withinDays]
  static SaleEvent? nextConfirmed(
    List<SaleEvent> events,
    DateTime now, {
    int? withinDays,
  }) {
    for (final e in events) {
      final days = e.daysUntil(now);
      if (!e.confirmed || days < 0) continue;
      if (withinDays != null && days > withinDays) continue;
      return e;
    }
    return null;
  }
}
