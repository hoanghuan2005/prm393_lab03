import 'dart:convert';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import 'available_budget.dart';
import 'owned_item.dart';
import 'sale_event.dart';
import 'spending_insight.dart';
import 'wishlist_item.dart';
import 'wishlist_status.dart';

/// Summary label of the Decision Card (spec 7.4). An observation only: there is no
/// "Nên mua" / "Không nên mua", and Mua · Chờ · Bỏ qua stay equally prominent.
enum DecisionLabel {
  needsRecentPrice('needs_recent_price', 'Cần giá gần đây'),
  waitCooldown('wait_cooldown', 'Có thể chờ'),
  waitSale('wait_sale', 'Có thể chờ'),
  overAvailable('over_available', 'Vượt phần khả dụng'),
  considerSkipping('consider_skipping', 'Có thể cân nhắc bỏ'),
  withinBudget('within_budget', 'Trong ngân sách'),
  notEnoughData('not_enough_data', 'Chưa đủ dữ liệu');

  final String key;
  final String text;

  const DecisionLabel(this.key, this.text);
}

/// Everything the rules look at, computed by code
class DecisionInput {
  final WishlistItem item;
  final DateTime now;
  final String? groupName;

  /// This month's "phần khả dụng" of the item's group; null when the group has no limit
  final AvailableBudget? available;

  /// First recorded price ("giá lúc lưu"); null when unknown
  final int? savedPriceVnd;

  /// Other items still being considered in the same group
  final int sameGroupCount;

  /// Confirmed sale within [SaleCalendar.decisionWindowDays]
  final SaleEvent? upcomingSale;

  /// S5: things the user owns in the same group or with a matching tag (spec 7.2)
  final List<OwnedItem> ownedMatches;

  const DecisionInput({
    required this.item,
    required this.now,
    this.groupName,
    this.available,
    this.savedPriceVnd,
    this.sameGroupCount = 0,
    this.upcomingSale,
    this.ownedMatches = const [],
  });
}

class DecisionRules {
  DecisionRules._();

  /// A price is "giá mới" for this many days (spec 7.4 label 1)
  static const int recentPriceDays = 3;
  static const int staleItemDays = 60;
  static const int lowPriority = 2;

  /// Checks the labels in the spec's order and stops at the first match
  static DecisionAssessment assess(DecisionInput input) {
    final item = input.item;
    final price = item.latestPriceVnd;
    final pricedAt = item.latestPriceAt;
    final hasRecentPrice =
        price != null &&
        pricedAt != null &&
        input.now.difference(pricedAt) <= const Duration(days: recentPriceDays);
    final available = input.available?.available;
    final daysSaved = input.now.difference(item.createdAt).inDays;
    final inCooldown =
        item.status == WishlistStatus.considering &&
        !item.displayMotive.skipsCooldown &&
        item.cooldownUntil != null &&
        input.now.isBefore(item.cooldownUntil!);

    // S1–S3 need a recent price (spec 7.7)
    final percent = hasRecentPrice && available != null && available > 0
        ? (price * 100 / available).round()
        : null;
    final overBy = hasRecentPrice && available != null && price > available
        ? price - available
        : null;
    final saved = input.savedPriceVnd;
    final change =
        hasRecentPrice && saved != null && saved > 0 && saved != price
        ? ((price - saved) * 100 / saved).round()
        : null;

    final label = !hasRecentPrice
        ? DecisionLabel.needsRecentPrice
        : inCooldown
        ? DecisionLabel.waitCooldown
        : input.upcomingSale != null
        ? DecisionLabel.waitSale
        : overBy != null
        ? DecisionLabel.overAvailable
        : (daysSaved > staleItemDays && item.priority <= lowPriority) ||
              item.confirmedDuplicate
        ? DecisionLabel.considerSkipping
        : available != null && (change == null || change <= 0)
        ? DecisionLabel.withinBudget
        : DecisionLabel.notEnoughData;

    return DecisionAssessment._(
      input: input,
      label: label,
      hasRecentPrice: hasRecentPrice,
      inCooldown: inCooldown,
      percentOfAvailable: percent,
      overBy: overBy,
      priceChangePercent: change,
      daysSaved: daysSaved,
    );
  }
}

class DecisionAssessment {
  final DecisionInput input;
  final DecisionLabel label;
  final bool hasRecentPrice;
  final bool inCooldown;

  /// S1: price ÷ khaDung × 100
  final int? percentOfAvailable;

  /// S2: price − khaDung when above it
  final int? overBy;

  /// S3: signed change from the price when saved
  final int? priceChangePercent;
  final int daysSaved;

  const DecisionAssessment._({
    required this.input,
    required this.label,
    required this.hasRecentPrice,
    required this.inCooldown,
    required this.percentOfAvailable,
    required this.overBy,
    required this.priceChangePercent,
    required this.daysSaved,
  });

  WishlistItem get item => input.item;
  String get _group => input.groupName ?? 'này';
  int? get _saleDays => input.upcomingSale?.daysUntil(input.now);

  /// S8: what is missing for a full assessment
  List<String> get missing => [
    if (!hasRecentPrice) 'giá gần đây',
    if (input.available == null)
      item.budgetGroupId == null
          ? 'nhóm ngân sách của món'
          : 'hạn mức tháng của nhóm',
  ];

  String get _savedDaysText => daysSaved == 0 ? 'hôm nay' : '$daysSaved ngày';

  String get _saleText {
    final sale = input.upcomingSale!;
    return _saleDays == 0
        ? 'Đợt ${sale.name} diễn ra hôm nay'
        : 'Đợt ${sale.name} còn $_saleDays ngày';
  }

  /// S5: "Bạn đã ghi có AirPods (dùng 2 năm). Bạn muốn thay hay mua thêm?"
  String? get ownedSentence {
    final owned = input.ownedMatches;
    if (owned.isEmpty) return null;
    if (owned.length == 1) {
      return 'Bạn đã ghi có ${owned.single.label}. Bạn muốn thay hay mua thêm?';
    }
    final names = owned.take(3).map((o) => o.name).join(', ');
    return 'Bạn đã ghi có ${owned.length} đồ đang dùng cùng nhóm hoặc cùng thẻ: $names.';
  }

  /// S1–S8 sentences that have data
  List<String> get signals => [
    if (percentOfAvailable != null)
      'Chiếm khoảng $percentOfAvailable% phần khả dụng của nhóm $_group tháng này.',
    if (overBy != null)
      'Vượt phần khả dụng của nhóm $_group khoảng ${formatVnd(overBy)}.',
    if (priceChangePercent != null)
      priceChangePercent! < 0
          ? 'Thấp hơn lúc lưu ${-priceChangePercent!}%.'
          : 'Cao hơn lúc lưu $priceChangePercent%.',
    if (input.sameGroupCount > 0)
      'Bạn đang cân nhắc thêm ${input.sameGroupCount} món cùng nhóm.',
    ?ownedSentence,
    if (item.confirmedDuplicate)
      'Bạn đã đánh dấu món này trùng với đồ đang có hoặc khoản mua gần đây.',
    if (input.upcomingSale != null) '$_saleText, có thể có giá tốt hơn.',
    if (inCooldown) 'Bạn mới lưu $_savedDaysText.',
    if (missing.isNotEmpty) 'Chưa đủ dữ liệu về ${missing.join(' và ')}.',
  ];

  /// Shown when AI is off, unavailable or writes something not allowed
  String get templateReason => switch (label) {
    DecisionLabel.needsRecentPrice =>
      item.latestPriceVnd == null
          ? 'Món chưa có giá nên chưa so được với ngân sách.'
          : item.latestPriceAt == null
          ? 'Chưa rõ giá được ghi từ ngày nào; nhập giá mới để so với ngân sách.'
          : 'Giá đã ghi từ ${formatDate(item.latestPriceAt!)}, có thể đã thay đổi; nhập giá mới để so với ngân sách.',
    DecisionLabel.waitCooldown =>
      'Món vẫn trong thời gian cân nhắc; bạn mới lưu $_savedDaysText.',
    DecisionLabel.waitSale => '$_saleText, có thể có giá tốt hơn.',
    DecisionLabel.overAvailable =>
      'Giá ${formatVnd(item.latestPriceVnd)} vượt phần khả dụng của nhóm $_group khoảng ${formatVnd(overBy)}.',
    DecisionLabel.considerSkipping =>
      item.confirmedDuplicate
          ? 'Bạn đã đánh dấu món này trùng với đồ đang có hoặc khoản mua gần đây.'
          : 'Món đã lưu $daysSaved ngày và đang ở mức ưu tiên ${item.priority} sao.',
    DecisionLabel.withinBudget =>
      percentOfAvailable == null
          ? 'Giá nằm trong phần khả dụng của nhóm $_group tháng này.'
          : 'Món chiếm khoảng $percentOfAvailable% phần khả dụng của nhóm $_group tháng này.',
    DecisionLabel.notEnoughData =>
      'Chưa đủ thông tin ngân sách để đánh giá. Bạn vẫn có thể tự quyết định.',
  };

  /// Minimal data for AI (spec 7.6): title, price, group, motive and computed numbers; no link
  Map<String, dynamic> toPromptData() {
    final price = item.latestPriceVnd;
    final available = input.available?.available;
    final sale = input.upcomingSale;
    return {
      'nhan': label.text,
      'tenMon': item.title,
      'nhom': input.groupName,
      'dongCo': item.displayMotive.label,
      'uuTienSao': item.priority,
      'daLuuNgay': daysSaved,
      'giaGanDay': hasRecentPrice,
      if (price != null) 'giaText': formatVnd(price),
      if (available != null) 'khaDungText': formatVnd(available),
      'phanTramKhaDung': ?percentOfAvailable,
      if (overBy != null) 'vuotKhaDungText': formatVnd(overBy),
      'doiGiaSoVoiLucLuuPhanTram': ?priceChangePercent,
      'soMonCungNhomDangCanNhac': input.sameGroupCount,
      'dangTrongThoiGianCanNhac': inCooldown,
      if (sale != null) 'dotSale': {'ten': sale.name, 'conNgay': _saleDays},
      if (missing.isNotEmpty) 'thieuDuLieu': missing,
      if (input.ownedMatches.isNotEmpty)
        'doDangCo': [for (final o in input.ownedMatches.take(3)) o.label],
      if (item.confirmedDuplicate) 'nguoiDungXacNhanTrung': true,
    };
  }

  /// Stable identity of the input; unchanged data is never sent to AI twice
  String get cacheKey => jsonEncode(toPromptData());

  /// Every integer an AI sentence may contain; anything else counts as invented
  Set<int> get allowedNumbers {
    final pricedAt = item.latestPriceAt;
    final sale = input.upcomingSale;
    final available = input.available;
    return {
      0,
      daysSaved,
      item.priority,
      input.sameGroupCount,
      DecisionRules.recentPriceDays,
      ?item.latestPriceVnd,
      ?input.savedPriceVnd,
      ?percentOfAvailable,
      ?overBy,
      if (priceChangePercent != null) ...[
        priceChangePercent!,
        priceChangePercent!.abs(),
      ],
      if (available != null) ...[
        available.available,
        available.limit,
        available.spent,
      ],
      if (pricedAt != null) ...[pricedAt.day, pricedAt.month, pricedAt.year],
      if (sale != null) ...[
        ?_saleDays,
        sale.date.day,
        sale.date.month,
        ...MonthlySpendingStats.extractNumbers(sale.name),
      ],
      ...MonthlySpendingStats.extractNumbers(item.title),
      ...MonthlySpendingStats.extractNumbers(input.groupName ?? ''),
      input.ownedMatches.length,
      for (final o in input.ownedMatches)
        ...MonthlySpendingStats.extractNumbers(o.label),
    };
  }
}
