import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/month_key.dart';
import '../core/utils/time_slot.dart';
import '../core/validators/validators.dart';
import '../models/budget_group.dart';
import '../models/buying_motive.dart';
import '../models/purchase_draft.dart';
import '../models/purchase_item.dart';
import '../models/ui_state.dart';
import '../models/wishlist_item.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/purchase_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Count and total of one period's purchases in one part of the day
class TimeSlotStat {
  final TimeSlot slot;
  final int count;
  final int totalVnd;

  const TimeSlotStat(this.slot, this.count, this.totalVnd);
}

/// Count and total of one period's purchases with one motive
class MotiveTotal {
  final BuyingMotive motive;
  final int count;
  final int totalVnd;

  const MotiveTotal(this.motive, this.count, this.totalVnd);
}

/// Tuần / Tháng on the Mô hình screen
enum StatsPeriod { week, month }

/// Every number shown for one period, computed from the same purchases so totals,
/// counts, motives and shares can never disagree about the time range.
class PeriodStats {
  /// Inclusive start, exclusive end
  final DateTime from;
  final DateTime to;
  final List<PurchaseItem> purchases;

  PeriodStats(this.from, this.to, Iterable<PurchaseItem> all)
    : purchases = all
          .where(
            (p) => !p.occurredAt.isBefore(from) && p.occurredAt.isBefore(to),
          )
          .toList();

  late final int total = purchases.fold(0, (sum, p) => sum + p.amountVnd);
  int get count => purchases.length;

  /// Motives that occur in the period, largest amount first
  late final List<MotiveTotal> motives = () {
    final counts = <BuyingMotive, int>{};
    final totals = <BuyingMotive, int>{};
    for (final p in purchases) {
      counts[p.motive] = (counts[p.motive] ?? 0) + 1;
      totals[p.motive] = (totals[p.motive] ?? 0) + p.amountVnd;
    }
    return [for (final m in counts.keys) MotiveTotal(m, counts[m]!, totals[m]!)]
      ..sort((a, b) => b.totalVnd.compareTo(a.totalVnd));
  }();

  /// Every part of the day, in TimeSlot order (zero rows included)
  late final List<TimeSlotStat> timeSlots = () {
    final counts = <TimeSlot, int>{};
    final totals = <TimeSlot, int>{};
    for (final p in purchases) {
      final slot = TimeSlot.fromDateTime(p.occurredAt);
      counts[slot] = (counts[slot] ?? 0) + 1;
      totals[slot] = (totals[slot] ?? 0) + p.amountVnd;
    }
    return [
      for (final slot in TimeSlot.values)
        TimeSlotStat(slot, counts[slot] ?? 0, totals[slot] ?? 0),
    ];
  }();

  /// Share of this period's total amount, 0..1
  double shareOf(int amountVnd) => total > 0 ? amountVnd / total : 0;
}

/// ViewModel managing Purchases with real-time Firebase Cloud Firestore sync.
/// The uid comes from AuthViewModel through ChangeNotifierProxyProvider ([updateUid]).
class PurchaseViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final PurchaseService purchaseService;
  final AppAnalyticsService? analyticsService;
  @override
  final CrashlyticsService? crashlyticsService;

  /// Message of the last failed add / update / delete, for a SnackBar
  String? _actionError;
  Object? _writeToken;

  StreamSubscription<List<PurchaseItem>>? _purchasesSubscription;
  String? _uid;
  List<PurchaseItem> _purchases = [];
  UiState<List<PurchaseItem>> _state = const UiInitial();
  BuyingMotive? _selectedMotiveFilter;
  DateTime _selectedMonth = _firstOfMonth(DateTime.now());

  PurchaseViewModel({
    required this.purchaseService,
    this.analyticsService,
    this.crashlyticsService,
  });

  String? get actionError => _actionError;
  bool get isSaving => _writeToken != null;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  String? get uid => _uid;

  /// Load state of all purchases of the signed-in user
  UiState<List<PurchaseItem>> get state => _state;

  /// Called by the provider whenever the signed-in user changes
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _writeToken = null;
    _actionError = null;
    _purchasesSubscription?.cancel();
    _purchasesSubscription = null;
    _purchases = [];
    _selectedMotiveFilter = null;

    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }

    _state = const UiLoading();
    notifyLater();
    _purchasesSubscription = purchaseService
        .watchPurchases(uid)
        .listen(
          (items) {
            if (isDisposed || _uid != uid) return;
            _purchases = items;
            _state = items.isEmpty
                ? const UiEmpty(message: 'Chưa có khoản mua nào được ghi')
                : UiSuccess(items);
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
            if (isDisposed || _uid != uid) return;
            _state = UiError(
              message: messageFor(error, stack, reason: 'watchPurchases'),
              onRetry: () => _retry(uid),
            );
            notifyListeners();
          },
        );
  }

  void _retry(String uid) {
    _uid = null;
    updateUid(uid);
  }

  String get currentMonthKey => monthKey(_selectedMonth);

  List<PurchaseItem> get allPurchases => List.unmodifiable(_purchases);

  List<PurchaseItem> get recentPurchases => monthPurchases.take(3).toList();

  BuyingMotive? get selectedMotiveFilter => _selectedMotiveFilter;
  DateTime get selectedMonth => _selectedMonth;

  /// Purchases belonging to currently selected month
  List<PurchaseItem> get monthPurchases {
    return _purchases.where((item) {
      return item.occurredAt.year == _selectedMonth.year &&
          item.occurredAt.month == _selectedMonth.month;
    }).toList();
  }

  /// Filtered by both selected month and active motive filter
  List<PurchaseItem> get filteredPurchases {
    return monthPurchases.where((item) {
      return _selectedMotiveFilter == null ||
          item.motive == _selectedMotiveFilter;
    }).toList();
  }

  /// Monday 00:00 of the week containing [day]
  static DateTime weekStartOf(DateTime day) =>
      DateTime(day.year, day.month, day.day - (day.weekday - 1));

  /// Purchases with occurredAt in [from, to)
  PeriodStats statsBetween(DateTime from, DateTime to) =>
      PeriodStats(from, to, _purchases);

  /// Selected month
  PeriodStats get monthStats => statsBetween(
    _selectedMonth,
    DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1),
  );

  /// Week starting on [monday]
  PeriodStats weekStats(DateTime monday) =>
      statsBetween(monday, DateTime(monday.year, monday.month, monday.day + 7));

  int get monthTotal => monthStats.total;
  int get monthCount => monthStats.count;

  /// Selected month split by part of the day, in TimeSlot order
  List<TimeSlotStat> get timeSlotStats => monthStats.timeSlots;

  /// Current calendar week, Monday 00:00 to Sunday 23:59 (independent of the selected month)
  PeriodStats get currentWeekStats => weekStats(weekStartOf(DateTime.now()));

  List<PurchaseItem> get weekPurchases => currentWeekStats.purchases;
  int get weekTotal => currentWeekStats.total;
  int get weekCount => currentWeekStats.count;

  /// The selected month is the current calendar month ("Tuần này" only makes sense then)
  bool get isCurrentMonthSelected {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  /// Month navigation
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = _firstOfMonth(month);
    notifyListeners();
  }

  /// Distribution calculation for motive segmented bar
  Map<BuyingMotive, double> get motiveDistribution {
    final list = monthPurchases;
    if (list.isEmpty) return {};
    final Map<BuyingMotive, int> countMap = {};
    for (final p in list) {
      countMap[p.motive] = (countMap[p.motive] ?? 0) + 1;
    }
    final Map<BuyingMotive, double> result = {};
    for (final entry in countMap.entries) {
      result[entry.key] = entry.value / list.length;
    }
    return result;
  }

  BuyingMotive? get _topMotive {
    BuyingMotive? topMotive;
    double maxRatio = -1;
    for (final entry in motiveDistribution.entries) {
      if (entry.value > maxRatio) {
        maxRatio = entry.value;
        topMotive = entry.key;
      }
    }
    return topMotive;
  }

  /// Most frequent motive (Figma: Khuyến mãi (2/5), 40%)
  String get dominantMotiveText {
    if (monthPurchases.isEmpty) return 'Chưa có khoản chi';
    final top = _topMotive;
    if (top == null) return '';
    final percent = ((motiveDistribution[top] ?? 0) * 100).round();
    return '$percent% do ${top.label}';
  }

  String get dominantMotiveSummary {
    final list = monthPurchases;
    if (list.isEmpty) return 'Chưa có khoản chi';
    final top = _topMotive;
    if (top == null) return '';
    final count = list.where((p) => p.motive == top).length;
    return 'Nhiều nhất: ${top.label} ($count/${list.length})';
  }

  void setMotiveFilter(BuyingMotive? motive) {
    _selectedMotiveFilter = motive;
    notifyListeners();
  }

  /// Saves a new purchase. The Firestore stream updates the list.
  /// Returns null when there is no signed-in user or the write failed.
  Future<PurchaseItem?> addPurchase({
    required String title,
    required int amount,
    required BuyingMotive motive,
    DateTime? dateTime,
    String? note,
    String budgetGroupId = BudgetGroup.otherId,
    bool usedDiscountCode = false,
    WishlistItem? fromWishlist,
    String? requestId,
  }) async {
    final trimmedNote = note?.trim();
    final purchase = PurchaseItem(
      id: requestId ?? const Uuid().v4(),
      title: title.trim(),
      amountVnd: amount,
      motive: motive,
      occurredAt: dateTime ?? DateTime.now(),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      budgetGroupId: budgetGroupId,
      usedDiscountCode: usedDiscountCode,
    );
    final saved = await _runWrite<PurchaseItem>((uid) async {
      _validate(purchase);
      if (fromWishlist == null) return purchaseService.add(uid, purchase);
      return purchaseService.buyFromWishlist(
        uid,
        fromWishlist,
        PurchaseDraft(
          title: purchase.title,
          amountVnd: purchase.amountVnd,
          motive: purchase.motive,
          budgetGroupId: purchase.budgetGroupId,
          fromWishlistId: fromWishlist.id,
          occurredAt: purchase.occurredAt,
          note: purchase.note,
          usedDiscountCode: purchase.usedDiscountCode,
        ),
      );
    }, reason: 'addPurchase');
    if (saved != null) {
      unawaited(
        analyticsService?.logPurchaseRecorded(
              motive: saved.motive.key,
              amountVnd: saved.amountVnd,
              budgetGroupId: saved.budgetGroupId,
            ) ??
            Future<void>.value(),
      );
      if (fromWishlist != null) {
        unawaited(
          analyticsService?.logMakeDecision(
                decision: AnalyticsDecisions.buy,
                motive: saved.motive.key,
                priceVnd: saved.amountVnd,
              ) ??
              Future<void>.value(),
        );
      }
    }
    return saved;
  }

  /// Update an existing purchase
  Future<bool> updatePurchase({
    required String id,
    required String title,
    required int amount,
    required BuyingMotive motive,
    required DateTime dateTime,
    String? note,
    String? budgetGroupId,
    bool? usedDiscountCode,
    PurchaseItem? originalPurchase,
  }) async {
    final index = _purchases.indexWhere((p) => p.id == id);
    final base = index != -1 ? _purchases[index] : originalPurchase;
    final result = await _runWrite<bool>((uid) async {
      if (base == null || base.id != id) {
        throw const AppException(
          'not-found',
          'Không tìm thấy khoản mua cần sửa. Vui lòng tải lại lịch sử.',
        );
      }
      final trimmedNote = note?.trim();
      final updated = base.copyWith(
        title: title.trim(),
        amountVnd: amount,
        motive: motive,
        occurredAt: dateTime,
        note: trimmedNote,
        clearNote: trimmedNote == null || trimmedNote.isEmpty,
        budgetGroupId: budgetGroupId,
        usedDiscountCode: usedDiscountCode,
      );
      _validate(updated);
      await purchaseService.update(uid, updated);
      return true;
    }, reason: 'updatePurchase');
    return result ?? false;
  }

  Future<T?> _runWrite<T>(
    Future<T> Function(String uid) action, {
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập trước khi lưu khoản mua.';
      return null;
    }
    if (isSaving) return null;
    final token = Object();
    _writeToken = token;
    _actionError = null;
    notifyListeners();
    try {
      final result = await action(uid);
      if (isDisposed || _uid != uid || _writeToken != token) return null;
      return result;
    } catch (e, stack) {
      if (!isDisposed && _uid == uid && _writeToken == token) {
        _actionError = messageFor(e, stack, reason: reason);
      }
      return null;
    } finally {
      if (_writeToken == token) {
        _writeToken = null;
        if (!isDisposed) notifyListeners();
      }
    }
  }

  static void _validate(PurchaseItem purchase) {
    final error = Validators.validatePurchase(
      title: purchase.title,
      amountVnd: purchase.amountVnd,
      budgetGroupId: purchase.budgetGroupId,
      note: purchase.note,
    );
    if (error != null) throw AppException('invalid-purchase', error);
  }

  /// Delete a purchase (a linked wishlist item goes back to "Đang cân nhắc").
  /// false = not deleted, see [actionError].
  Future<bool> deletePurchase(String id) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập trước khi xoá khoản mua.';
      return false;
    }
    try {
      await purchaseService.delete(uid, id);
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'deletePurchase');
      return false;
    }
  }

  /// A-16: the most recent purchase whose satisfaction question is due (7–30 days old)
  PurchaseItem? satisfactionDue({DateTime? now}) {
    final at = now ?? DateTime.now();
    for (final p in _purchases) {
      if (p.isSatisfactionDue(at)) return p;
    }
    return null;
  }

  /// [stars] 1–5, or null for "Bỏ qua" (not asked again)
  Future<bool> rateSatisfaction(PurchaseItem purchase, int? stars) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để lưu mức hài lòng.';
      return false;
    }
    try {
      await purchaseService.setSatisfaction(uid, purchase.id, stars);
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'rateSatisfaction');
      return false;
    }
  }

  @override
  void dispose() {
    _writeToken = null;
    _purchasesSubscription?.cancel();
    super.dispose();
  }
}
