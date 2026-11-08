import 'dart:math' as math;

import '../models/daily_price.dart';
import '../models/price_snapshot.dart';
import 'price_history_viewmodel.dart';

/// Key of the user's own prices in [ownPriceView]
const String ownPricesKey = 'mine';

/// "Giá bạn ghi" (G6b) drawn like one product of "Giá tham khảo": the user's own
/// prices of the item (priceSnapshots) over [range] ending on [now]'s Vietnamese day,
/// one point per day with the lowest and highest price recorded that day. No
/// 2-person threshold: they are the user's own prices. After-voucher prices never
/// count (N8), nor a price taken from "Giá người khác ghi". [shopName] is the item's
/// shop, used when a price has none.
PriceHistoryView ownPriceView(
  List<PriceSnapshot> history, {
  required PriceHistoryRange range,
  required DateTime now,
  String? shopName,
}) {
  final days = vnDays(
    vnDate(now).subtract(Duration(days: range.days - 1)),
    now,
  );
  final byDay = <DateTime, List<PriceSnapshot>>{};
  for (final s in history) {
    if (s.amountVnd <= 0 ||
        s.priceType == PriceType.afterVoucher ||
        s.source == PriceSource.community) {
      continue;
    }
    (byDay[vnDate(s.observedAt)] ??= []).add(s);
  }
  int low(PriceSnapshot s) => s.isRange ? s.minVnd! : s.amountVnd;
  int high(PriceSnapshot s) => s.isRange ? s.maxVnd! : s.amountVnd;
  final points = [
    for (final day in days)
      switch (byDay[day]) {
        final list? => DailyPricePoint(
          day: day,
          minVnd: list.map(low).reduce(math.min),
          maxVnd: list.map(high).reduce(math.max),
          reportCount: list.length,
          hasSale: list.any(
            (s) =>
                s.priceType == PriceType.sale ||
                s.priceType == PriceType.flash,
          ),
          shopName: list.map((s) => s.shopName).nonNulls.firstOrNull ?? shopName,
        ),
        null => DailyPricePoint(day: day),
      },
  ];
  return PriceHistoryView(
    range: range,
    days: days,
    products: const {ownPricesKey: null},
    points: {ownPricesKey: points},
    summary: PeriodSummary(
      daysWithData: points.where((p) => p.hasPrice).length,
    ),
  );
}

/// "Giá bạn ghi" as hollow dots on the community chart [view]: day index → the
/// user's lowest price that day, from [own] ([ownPriceView] of the same period)
Map<int, int> ownPriceDots(PriceHistoryView view, PriceHistoryView own) {
  final mine = {
    for (final p in own.points[ownPricesKey] ?? const <DailyPricePoint>[])
      if (p.minVnd case final vnd?) p.day: vnd,
  };
  return {
    for (final (i, day) in view.days.indexed)
      if (mine[day] case final vnd?) i: vnd,
  };
}
