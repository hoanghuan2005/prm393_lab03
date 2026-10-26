import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../models/budget_group.dart';
import '../models/monthly_budget.dart';
import '../models/purchase_item.dart';
import '../models/ui_state.dart';
import '../services/analytics_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Budget groups, this month's limits and what has been spent per group.
/// uid comes from AuthViewModel; purchases and the selected month come from PurchaseViewModel.
class BudgetViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  /// Safety margin of handoff 9.4 (bienDo)
  static const int safetyMarginPercent = 10;

  /// Below this much purchase history the daily-spending buffer is 0
  static const int historyDaysRequired = 30;

  final BudgetService budgetService;
  final AppAnalyticsService? analyticsService;
  @override
  final CrashlyticsService? crashlyticsService;

  StreamSubscription<List<BudgetGroup>>? _groupsSubscription;
  StreamSubscription<MonthlyBudget>? _budgetSubscription;
  String? _uid;
  List<BudgetGroup> _groups = [];
  MonthlyBudget? _budget;
  String? _actionError;
  UiState<List<BudgetGroup>> _state = const UiInitial();
  List<PurchaseItem> _purchases = const [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  BudgetViewModel({
    required this.budgetService,
    this.analyticsService,
    this.crashlyticsService,
  });

  UiState<List<BudgetGroup>> get state => _state;

  /// Message of the last failed save, for a SnackBar
  String? get actionError => _actionError;
  DateTime get month => _month;
  String get monthKeyValue => monthKey(_month);

  /// Groups of the user; the 6 defaults until Firestore has returned them
  List<BudgetGroup> get groups =>
      _groups.isEmpty ? defaultBudgetGroups : List.unmodifiable(_groups);

  Map<String, int> get limits => _budget?.limits ?? const {};
  bool get hasBudget => limits.isNotEmpty;
  int? limitFor(String groupId) => limits[groupId];
  int get totalLimit => _budget?.totalLimit ?? 0;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _groupsSubscription?.cancel();
    _groupsSubscription = null;
    _budgetSubscription?.cancel();
    _budgetSubscription = null;
    _groups = [];
    _budget = null;

    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }

    _state = const UiLoading();
    notifyLater();
    _groupsSubscription = budgetService
        .watchGroups(uid)
        .listen(
          (groups) {
            _groups = groups;
            _state = UiSuccess(this.groups);
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
            _state = UiError(
              message: messageFor(error, stack, reason: 'watchGroups'),
              onRetry: () => _retry(uid),
            );
            notifyListeners();
          },
        );
    _subscribeBudget();
  }

  /// Purchases and selected month, fed by PurchaseViewModel
  void updateSources({
    required List<PurchaseItem> purchases,
    required DateTime month,
  }) {
    final normalized = DateTime(month.year, month.month, 1);
    final monthChanged = normalized != _month;
    _purchases = purchases;
    _month = normalized;
    if (monthChanged) _subscribeBudget();
    notifyLater();
  }

  void _subscribeBudget() {
    _budgetSubscription?.cancel();
    _budget = null;
    final uid = _uid;
    if (uid == null) return;
    _budgetSubscription = budgetService
        .watchMonthlyBudget(uid, monthKeyValue)
        .listen(
          (budget) {
            _budget = budget;
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
            _state = UiError(
              message: messageFor(error, stack, reason: 'watchMonthlyBudget'),
              onRetry: _subscribeBudget,
            );
            notifyListeners();
          },
        );
  }

  void _retry(String uid) {
    _uid = null;
    updateUid(uid);
  }

  List<PurchaseItem> get _monthPurchases => _purchases
      .where(
        (p) =>
            p.occurredAt.year == _month.year &&
            p.occurredAt.month == _month.month,
      )
      .toList();

  /// Group a purchase counts towards; unknown or missing groups count as "other"
  String _groupOf(PurchaseItem p) {
    final ids = groups.map((g) => g.id).toSet();
    return ids.contains(p.budgetGroupId)
        ? p.budgetGroupId
        : BudgetGroup.otherId;
  }

  /// Spent in the selected month per group (only recorded purchases)
  Map<String, int> get spentByGroup {
    final map = <String, int>{};
    for (final p in _monthPurchases) {
      final id = _groupOf(p);
      map[id] = (map[id] ?? 0) + p.amountVnd;
    }
    return map;
  }

  int spentFor(String groupId) => spentByGroup[groupId] ?? 0;

  /// All purchases of the selected month
  int get totalSpent => _monthPurchases.fold(0, (sum, p) => sum + p.amountVnd);

  double get progress =>
      totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => totalLimit > 0 && totalSpent > totalLimit;
  int get remaining => totalLimit - totalSpent;

  /// At least [historyDaysRequired] days between the first recorded purchase and today
  bool get hasEnoughHistory {
    if (_purchases.isEmpty) return false;
    final first = _purchases
        .map((p) => p.occurredAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(first).inDays >= historyDaysRequired;
  }

  /// Days after today in the selected month (0 for past months, full month for future ones)
  int get daysLeftInMonth {
    final now = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    if (_month.year == now.year && _month.month == now.month) {
      return daysInMonth - now.day;
    }
    return _month.isAfter(now) ? daysInMonth : 0;
  }

  /// Average daily spending of the group over the last [historyDaysRequired] days
  int dailyAverageFor(String groupId) {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: historyDaysRequired));
    final total = _purchases
        .where(
          (p) =>
              _groupOf(p) == groupId &&
              p.occurredAt.isAfter(since) &&
              !p.occurredAt.isAfter(now),
        )
        .fold(0, (sum, p) => sum + p.amountVnd);
    return total ~/ historyDaysRequired;
  }

  /// "Dự phòng chi thường ngày": 0 while history is shorter than 30 days
  int bufferFor(String groupId) =>
      hasEnoughHistory ? dailyAverageFor(groupId) * daysLeftInMonth : 0;

  /// Handoff 9.4: floor(max(0, limit − spent − buffer) × 0.9); null when the group has no limit
  int? available(String groupId) {
    final limit = limitFor(groupId);
    if (limit == null) return null;
    final left = limit - spentFor(groupId) - bufferFor(groupId);
    if (left <= 0) return 0;
    return left * (100 - safetyMarginPercent) ~/ 100;
  }

  /// [limit] null removes the group's limit for the selected month
  Future<bool> setGroupLimit(String groupId, int? limit) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await budgetService.setGroupLimit(uid, monthKeyValue, groupId, limit);
      if (limit != null && limit > 0) {
        unawaited(
          analyticsService?.logBudgetSet(
                budgetGroupId: groupId,
                amountVnd: limit,
                month: monthKeyValue,
              ) ??
              Future<void>.value(),
        );
      }
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'setGroupLimit');
      return false;
    }
  }

  /// TODO(budget screen): the current sheet edits one overall amount. It is stored as the
  /// limit of group "other" = amount − limits of the other groups, so totalLimit == amount.
  Future<bool> setOverallLimit(int amount) {
    final others = limits.entries
        .where((e) => e.key != BudgetGroup.otherId)
        .fold(0, (sum, e) => sum + e.value);
    return setGroupLimit(BudgetGroup.otherId, amount - others);
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
