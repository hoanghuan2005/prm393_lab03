import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../models/available_budget.dart';
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
  final BudgetService budgetService;
  final AppAnalyticsService? analyticsService;
  @override
  final CrashlyticsService? crashlyticsService;

  /// Injectable for tests of the available-amount formula
  final DateTime Function() _now;

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
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

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

  /// False until the selected month's limits arrive, so "chưa đặt" is not shown early
  bool get isBudgetLoaded => _budget != null;

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
              onRetry: _retryBudget,
            );
            notifyListeners();
          },
        );
  }

  void _retryBudget() {
    _state = _groups.isEmpty ? const UiLoading() : UiSuccess(groups);
    notifyListeners();
    _subscribeBudget();
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

  /// Spent in the groups that have a limit: the only spending [totalLimit] can be
  /// compared with (a group without a limit cannot "exceed" anything)
  int get limitedSpent => limits.keys.fold(0, (sum, id) => sum + spentFor(id));

  /// Spent in groups without a limit this month, shown separately
  int get unlimitedSpent => totalSpent - limitedSpent;

  double get progress =>
      totalLimit > 0 ? (limitedSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => totalLimit > 0 && limitedSpent > totalLimit;
  int get remaining => totalLimit - limitedSpent;

  /// Spec 7.1 "phần khả dụng cho Wishlist" with every step of the calculation;
  /// null when the group has no limit this month
  AvailableBudget? availableBreakdown(String groupId) {
    final limit = limitFor(groupId);
    if (limit == null) return null;
    DateTime? first;
    for (final p in _purchases) {
      if (first == null || p.occurredAt.isBefore(first)) first = p.occurredAt;
    }
    return AvailableBudget.compute(
      limit: limit,
      month: _month,
      groupPurchases: _purchases.where((p) => _groupOf(p) == groupId).toList(),
      firstPurchaseAt: first,
      now: _now(),
    );
  }

  int? available(String groupId) => availableBreakdown(groupId)?.available;

  /// Groups shown on the budget screen: those with a limit or with spending this month
  List<BudgetGroup> get visibleGroups => groups
      .where((g) => limitFor(g.id) != null || spentFor(g.id) > 0)
      .toList();

  /// [limit] null removes the group's limit for the selected month
  Future<bool> setGroupLimit(String groupId, int? limit) =>
      setGroupLimits({groupId: limit});

  /// Saves several group limits for the selected month in one write.
  /// The month total is always the sum of the group limits, so it can never be
  /// lower than the groups it contains.
  Future<bool> setGroupLimits(Map<String, int?> changes) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để lưu ngân sách.';
      return false;
    }
    if (changes.isEmpty) return true;
    try {
      await budgetService.setGroupLimits(uid, monthKeyValue, changes);
      _actionError = null;
      for (final e in changes.entries) {
        final limit = e.value;
        if (limit == null || limit <= 0) continue;
        unawaited(
          analyticsService?.logBudgetSet(
                budgetGroupId: e.key,
                amountVnd: limit,
                month: monthKeyValue,
              ) ??
              Future<void>.value(),
        );
      }
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'setGroupLimits');
      return false;
    }
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
