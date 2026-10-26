import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import 'buying_motive.dart';
import 'item_status.dart';
import 'purchase_item.dart';
import 'wishlist_item.dart';

/// Minimum purchases in a month before AI is asked to comment (spec 7.7: say when data is missing)
const int kMinPurchasesForAi = 3;

/// Late-night window used by the insight rules: 22:00–05:00
const int kLateNightStartHour = 22;
const int kLateNightEndHour = 5;

/// Observation types shown on Góc nhìn. The key is the card id exchanged with the AI.
enum InsightKind {
  dominantMotive(
    'dominant_motive',
    Icons.pie_chart_outline_rounded,
    AppColors.motiveSale,
  ),
  lateNight('late_night', Icons.nightlight_round, AppColors.motiveNeed),
  monthOverMonth(
    'month_over_month',
    Icons.compare_arrows_rounded,
    AppColors.motiveSocial,
  ),
  largestPurchase(
    'largest_purchase',
    Icons.receipt_long_outlined,
    AppColors.motiveEmotion,
  ),
  skippedItems(
    'skipped_items',
    Icons.do_not_disturb_on_outlined,
    AppColors.motiveConvenience,
  );

  final String key;
  final IconData icon;
  final Color color;

  const InsightKind(this.key, this.icon, this.color);
}

class MotiveStat {
  final BuyingMotive motive;
  final int count;
  final int amount;

  const MotiveStat({
    required this.motive,
    required this.count,
    required this.amount,
  });
}

/// Monthly numbers computed by code. AI only rephrases these and never adds new figures (spec 7.6).
class MonthlySpendingStats {
  final int year;
  final int month;
  final int purchaseCount;
  final int totalSpent;

  /// Sorted by count, then amount (descending)
  final List<MotiveStat> motives;
  final int lateNightCount;
  final int lateNightAmount;
  final PurchaseItem? largestPurchase;

  /// Null when the previous month has no recorded purchases
  final int? previousMonthTotal;

  /// Wishlist items the user decided not to buy this month (spec 7.8, never called "savings")
  final int skippedCount;
  final int skippedValue;

  /// Stable identity of the input data; used to cache AI output
  late final String cacheKey = jsonEncode(toPromptData());

  MonthlySpendingStats({
    required this.year,
    required this.month,
    required this.purchaseCount,
    required this.totalSpent,
    required this.motives,
    required this.lateNightCount,
    required this.lateNightAmount,
    required this.largestPurchase,
    required this.previousMonthTotal,
    required this.skippedCount,
    required this.skippedValue,
  });

  factory MonthlySpendingStats.compute({
    required DateTime month,
    required List<PurchaseItem> purchases,
    required List<WishlistItem> wishlistItems,
  }) {
    bool inMonth(DateTime d, int y, int m) => d.year == y && d.month == m;

    final monthPurchases = purchases
        .where((p) => inMonth(p.dateTime, month.year, month.month))
        .toList();
    final previous = DateTime(month.year, month.month - 1, 1);
    final previousPurchases = purchases.where(
      (p) => inMonth(p.dateTime, previous.year, previous.month),
    );

    final counts = <BuyingMotive, int>{};
    final sums = <BuyingMotive, int>{};
    var total = 0;
    var lateCount = 0;
    var lateAmount = 0;
    PurchaseItem? largest;

    for (final p in monthPurchases) {
      final amount = p.amount.round();
      total += amount;
      counts[p.motive] = (counts[p.motive] ?? 0) + 1;
      sums[p.motive] = (sums[p.motive] ?? 0) + amount;
      if (isLateNight(p.dateTime)) {
        lateCount++;
        lateAmount += amount;
      }
      if (largest == null || p.amount > largest.amount) largest = p;
    }

    final motives =
        counts.entries
            .map(
              (e) => MotiveStat(
                motive: e.key,
                count: e.value,
                amount: sums[e.key] ?? 0,
              ),
            )
            .toList()
          ..sort(
            (a, b) => b.count != a.count
                ? b.count.compareTo(a.count)
                : b.amount.compareTo(a.amount),
          );

    final previousTotal = previousPurchases.fold<int>(
      0,
      (sum, p) => sum + p.amount.round(),
    );

    final skipped = wishlistItems.where(
      (i) =>
          i.status == ItemStatus.dropped &&
          i.decidedAt != null &&
          inMonth(i.decidedAt!, month.year, month.month),
    );

    return MonthlySpendingStats(
      year: month.year,
      month: month.month,
      purchaseCount: monthPurchases.length,
      totalSpent: total,
      motives: motives,
      lateNightCount: lateCount,
      lateNightAmount: lateAmount,
      largestPurchase: largest,
      previousMonthTotal: previousPurchases.isEmpty ? null : previousTotal,
      skippedCount: skipped.length,
      skippedValue: skipped.fold<int>(0, (sum, i) => sum + i.price.round()),
    );
  }

  static bool isLateNight(DateTime d) =>
      d.hour >= kLateNightStartHour || d.hour < kLateNightEndHour;

  bool get hasPurchases => purchaseCount > 0;
  bool get hasEnoughDataForAi => purchaseCount >= kMinPurchasesForAi;

  MotiveStat? get dominantMotive => motives.isEmpty ? null : motives.first;

  int sharePercent(MotiveStat stat) =>
      purchaseCount == 0 ? 0 : (stat.count * 100 / purchaseCount).round();

  /// Change in total spent vs. previous month, in percent
  int? get changeVsPreviousPercent {
    final prev = previousMonthTotal;
    if (prev == null || prev == 0) return null;
    return ((totalSpent - prev) * 100 / prev).round();
  }

  DateTime get previousMonth => DateTime(year, month - 1, 1);

  /// Observations that apply to this month, in display order
  List<InsightKind> get applicableKinds => [
    if (hasPurchases) InsightKind.dominantMotive,
    if (lateNightCount > 0) InsightKind.lateNight,
    if (hasPurchases && previousMonthTotal != null) InsightKind.monthOverMonth,
    if (purchaseCount >= 2) InsightKind.largestPurchase,
    if (skippedCount > 0) InsightKind.skippedItems,
  ];

  /// Data sent to the model. Only names, amounts, motives and computed numbers; never notes or links (spec 7.6).
  Map<String, dynamic> toPromptData() {
    final largest = largestPurchase;
    return {
      'thang': '$month/$year',
      'soKhoanMua': purchaseCount,
      'tongDaChi': totalSpent,
      'tongDaChiText': formatVnd(totalSpent),
      'dongCo': [
        for (final m in motives)
          {
            'ten': m.motive.label,
            'soKhoan': m.count,
            'tyLePhanTram': sharePercent(m),
            'soTien': m.amount,
            'soTienText': formatVnd(m.amount),
          },
      ],
      'muaKhungDem': {
        'khungGio': '22:00-05:00',
        'soKhoan': lateNightCount,
        'soTien': lateNightAmount,
        'soTienText': formatVnd(lateNightAmount),
      },
      if (previousMonthTotal != null)
        'thangTruoc': {
          'thang': '${previousMonth.month}/${previousMonth.year}',
          'tongDaChi': previousMonthTotal,
          'tongDaChiText': formatVnd(previousMonthTotal!),
          'thayDoiPhanTram': changeVsPreviousPercent,
        },
      if (largest != null)
        'khoanLonNhat': {
          'ten': largest.title,
          'soTien': largest.amount.round(),
          'soTienText': formatVnd(largest.amount.round()),
          'dongCo': largest.motive.label,
          'gio': formatTime(largest.dateTime),
        },
      'monDaQuyetDinhKhongMua': {
        'soMon': skippedCount,
        'tongGiaDaGhi': skippedValue,
        'tongGiaDaGhiText': formatVnd(skippedValue),
      },
    };
  }

  /// Every integer the generated text may mention. Anything else is treated as invented.
  Set<int> get allowedNumbers {
    final numbers = <int>{
      0,
      year,
      month,
      previousMonth.month,
      previousMonth.year,
      purchaseCount,
      totalSpent,
      kLateNightStartHour,
      kLateNightEndHour,
      lateNightCount,
      lateNightAmount,
      skippedCount,
      skippedValue,
      BuyingMotive.values.length,
    };
    for (final m in motives) {
      numbers.addAll([m.count, m.amount, sharePercent(m)]);
    }
    if (previousMonthTotal != null) numbers.add(previousMonthTotal!);
    final change = changeVsPreviousPercent;
    if (change != null) numbers.add(change.abs());
    final largest = largestPurchase;
    if (largest != null) {
      numbers.addAll([
        largest.amount.round(),
        largest.dateTime.hour,
        largest.dateTime.minute,
      ]);
      numbers.addAll(extractNumbers(largest.title));
    }
    return numbers;
  }

  static final RegExp _numberPattern = RegExp(r'\d+(?:[.,]\d+)*');

  /// Integers written in [text]; "1.250.000" and "1,250,000" both read as 1250000
  static List<int> extractNumbers(String text) => _numberPattern
      .allMatches(text)
      .map((m) => int.tryParse(m.group(0)!.replaceAll(RegExp(r'[.,]'), '')))
      .whereType<int>()
      .toList();
}

class InsightCard {
  final InsightKind kind;
  final String title;
  final String body;

  /// False when the card is the template sentence (AI off, failed, or rejected)
  final bool fromAi;

  const InsightCard({
    required this.kind,
    required this.title,
    required this.body,
    required this.fromAi,
  });
}

enum InsightSource { ai, template }

/// Góc nhìn cards plus the Chiêm nghiệm tháng summary, produced in one pass
class InsightReport {
  final String summary;
  final bool summaryFromAi;
  final List<InsightCard> cards;

  const InsightReport({
    required this.summary,
    required this.summaryFromAi,
    required this.cards,
  });

  InsightSource get source => summaryFromAi || cards.any((c) => c.fromAi)
      ? InsightSource.ai
      : InsightSource.template;
}
