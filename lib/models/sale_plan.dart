import 'budget_group.dart';
import 'buying_motive.dart';
import 'wishlist_item.dart';

/// Three ways to fit considered items into each group's "phần khả dụng" (spec 7.5).
/// Only computed when the user taps "Lập kế hoạch cho đợt sale"; never pushed.
enum PlanOption {
  balanced(
    'Cân bằng',
    'Cân bằng giữa mức ưu tiên, động cơ và thời gian bạn đã cân nhắc.',
  ),
  needsFirst('Cần trước', 'Đặt món có động cơ Nhu cầu, Tiện lợi lên trước.'),
  keepMore(
    'Giữ lại nhiều hơn',
    'Chỉ dùng tối đa một nửa phần khả dụng của mỗi nhóm.',
  );

  final String title;
  final String description;

  const PlanOption(this.title, this.description);
}

/// Why an item is not in any plan
enum PlanExclusion {
  noPrice('chưa có giá'),
  noGroup('chưa chọn nhóm ngân sách'),
  noLimit('nhóm chưa đặt hạn mức tháng này');

  final String reason;

  const PlanExclusion(this.reason);
}

class PlanGroup {
  final BudgetGroup group;

  /// The group's "phần khả dụng" this month
  final int available;

  /// What this option may spend in the group
  final int capacity;
  final List<WishlistItem> chosen;

  const PlanGroup({
    required this.group,
    required this.available,
    required this.capacity,
    required this.chosen,
  });

  int get total => chosen.fold(0, (sum, i) => sum + (i.latestPriceVnd ?? 0));
  int get left => available - total;
}

class SalePlan {
  final PlanOption option;
  final List<PlanGroup> groups;

  const SalePlan({required this.option, required this.groups});

  int get total => groups.fold(0, (sum, g) => sum + g.total);
  int get available => groups.fold(0, (sum, g) => sum + g.available);
  int get itemCount => groups.fold(0, (sum, g) => sum + g.chosen.length);
}

class SalePlanResult {
  final List<SalePlan> plans;
  final Map<WishlistItem, PlanExclusion> excluded;

  const SalePlanResult({required this.plans, required this.excluded});

  /// No group with a limit had a priced item: there is nothing to plan
  bool get isEmpty => plans.every((p) => p.groups.isEmpty);
}

class SalePlanner {
  SalePlanner._();

  /// Prices are rounded up to whole thousands before fitting (spec 7.5)
  static const int unitVnd = 1000;

  /// Motive factor of the score (spec 7.5, "đề xuất ban đầu" – an assumption to validate)
  static const Map<BuyingMotive, double> motiveFactor = {
    BuyingMotive.need: 1.0,
    BuyingMotive.convenience: 0.7,
    BuyingMotive.want: 0.6,
    BuyingMotive.other: 0.5,
    BuyingMotive.emotion: 0.4,
    BuyingMotive.social: 0.4,
    BuyingMotive.sale: 0.3,
    BuyingMotive.ads: 0.3,
  };

  /// Spec 7.7: satisfaction by motive is not collected yet, so hopGu uses 0.6
  static const double defaultFit = 0.6;

  /// diem = 0,30·uuTien + 0,25·dongCo + 0,20·gia + 0,10·daCho + 0,15·hopGu.
  /// gia (discount against a comparable earlier price) is 0: the plan does not read
  /// price history. Never shown to the user (spec 7.5).
  static double score(WishlistItem item, DateTime now) {
    final priority = (item.priority - 1) / 4;
    final motive = motiveFactor[item.displayMotive] ?? 0.5;
    final daysSaved = now.difference(item.createdAt).inDays;
    final waited = daysSaved >= 7 ? 1.0 : daysSaved / 7;
    return 0.30 * priority + 0.25 * motive + 0.10 * waited + 0.15 * defaultFit;
  }

  static double _value(PlanOption option, WishlistItem item, DateTime now) =>
      switch (option) {
        PlanOption.needsFirst =>
          0.7 * (motiveFactor[item.displayMotive] ?? 0.5) +
              0.3 * (item.priority - 1) / 4,
        _ => score(item, now),
      };

  /// [items]: items still being considered. [available]: groupId → this month's
  /// "phần khả dụng", only for groups with a limit.
  static SalePlanResult plan({
    required List<WishlistItem> items,
    required List<BudgetGroup> groups,
    required Map<String, int> available,
    required DateTime now,
  }) {
    final excluded = <WishlistItem, PlanExclusion>{};
    final byGroup = <String, List<WishlistItem>>{};
    for (final item in items) {
      final groupId = item.budgetGroupId;
      if (item.latestPriceVnd == null || item.latestPriceVnd! <= 0) {
        excluded[item] = PlanExclusion.noPrice;
      } else if (groupId == null) {
        excluded[item] = PlanExclusion.noGroup;
      } else if (!available.containsKey(groupId)) {
        excluded[item] = PlanExclusion.noLimit;
      } else {
        (byGroup[groupId] ??= []).add(item);
      }
    }

    final plans = [
      for (final option in PlanOption.values)
        SalePlan(
          option: option,
          groups: [
            for (final group in groups)
              if (byGroup[group.id] case final candidates?)
                _planGroup(
                  option,
                  group,
                  candidates,
                  available[group.id]!,
                  now,
                ),
          ],
        ),
    ];
    return SalePlanResult(plans: plans, excluded: excluded);
  }

  static PlanGroup _planGroup(
    PlanOption option,
    BudgetGroup group,
    List<WishlistItem> candidates,
    int available,
    DateTime now,
  ) {
    // Always one option that leaves part of the available amount unused (spec 7.5)
    final capacity = option == PlanOption.keepMore ? available ~/ 2 : available;
    final weights = [
      for (final i in candidates) (i.latestPriceVnd! + unitVnd - 1) ~/ unitVnd,
    ];
    final values = [
      for (final i in candidates)
        (_value(option, i, now) * 1000).round().clamp(1, 1 << 30),
    ];
    final chosen = knapsack(weights, values, capacity ~/ unitVnd);
    return PlanGroup(
      group: group,
      available: available,
      capacity: capacity,
      chosen: [for (final index in chosen) candidates[index]],
    );
  }

  /// 0/1 knapsack: indices of the items with the highest total value within [capacity]
  static List<int> knapsack(List<int> weights, List<int> values, int capacity) {
    final n = weights.length;
    if (n == 0 || capacity <= 0) return const [];
    final totalWeight = weights.fold(0, (a, b) => a + b);
    if (totalWeight <= capacity) return [for (var i = 0; i < n; i++) i];
    final cap = capacity;
    final best = List<int>.filled(cap + 1, 0);
    final keep = List.generate(n, (_) => List<bool>.filled(cap + 1, false));
    for (var i = 0; i < n; i++) {
      for (var w = cap; w >= weights[i]; w--) {
        final candidate = best[w - weights[i]] + values[i];
        if (candidate > best[w]) {
          best[w] = candidate;
          keep[i][w] = true;
        }
      }
    }
    final picked = <int>[];
    var w = cap;
    for (var i = n - 1; i >= 0; i--) {
      if (keep[i][w]) {
        picked.add(i);
        w -= weights[i];
      }
    }
    return picked.reversed.toList();
  }
}
