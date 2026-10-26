import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../core/utils/time_slot.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../models/ui_state.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/purchase_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Count and total of the selected month's purchases in one part of the day
class TimeSlotStat {
  final TimeSlot slot;
  final int count;
  final int totalVnd;

  const TimeSlotStat(this.slot, this.count, this.totalVnd);
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

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  String? get uid => _uid;

  /// Load state of all purchases of the signed-in user
  UiState<List<PurchaseItem>> get state => _state;

  /// Called by the provider whenever the signed-in user changes
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
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
            _purchases = items;
            _state = items.isEmpty
                ? const UiEmpty(message: 'Chưa có khoản mua nào được ghi')
                : UiSuccess(items);
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
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

  /// Selected month
  int get monthTotal =>
      monthPurchases.fold(0, (sum, item) => sum + item.amountVnd);
  int get monthCount => monthPurchases.length;

  /// Selected month split by part of the day, in TimeSlot order
  List<TimeSlotStat> get timeSlotStats {
    final counts = <TimeSlot, int>{};
    final totals = <TimeSlot, int>{};
    for (final p in monthPurchases) {
      final slot = TimeSlot.fromDateTime(p.occurredAt);
      counts[slot] = (counts[slot] ?? 0) + 1;
      totals[slot] = (totals[slot] ?? 0) + p.amountVnd;
    }
    return [
      for (final slot in TimeSlot.values)
        TimeSlotStat(slot, counts[slot] ?? 0, totals[slot] ?? 0),
    ];
  }

  /// Current calendar week, Monday 00:00 to Sunday 23:59 (independent of the selected month)
  List<PurchaseItem> get weekPurchases {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    return _purchases
        .where(
          (p) =>
              !p.occurredAt.isBefore(monday) &&
              p.occurredAt.isBefore(nextMonday),
        )
        .toList();
  }

  int get weekTotal =>
      weekPurchases.fold(0, (sum, item) => sum + item.amountVnd);
  int get weekCount => weekPurchases.length;

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
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final saved = await purchaseService.add(
        uid,
        PurchaseItem(
          id: '',
          title: title,
          amountVnd: amount,
          motive: motive,
          occurredAt: dateTime ?? DateTime.now(),
          note: note,
        ),
      );
      unawaited(
        analyticsService?.logPurchaseRecorded(
              motive: saved.motive.key,
              amountVnd: saved.amountVnd,
              budgetGroupId: saved.budgetGroupId,
            ) ??
            Future<void>.value(),
      );
      _actionError = null;
      return saved;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'addPurchase');
      return null;
    }
  }

  /// Update an existing purchase
  Future<void> updatePurchase({
    required String id,
    required String title,
    required int amount,
    required BuyingMotive motive,
    required DateTime dateTime,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final index = _purchases.indexWhere((p) => p.id == id);
    final base = index != -1
        ? _purchases[index]
        : PurchaseItem(
            id: id,
            title: title,
            amountVnd: amount,
            motive: motive,
            occurredAt: dateTime,
          );
    try {
      await purchaseService.update(
        uid,
        base.copyWith(
          title: title,
          amountVnd: amount,
          motive: motive,
          occurredAt: dateTime,
          note: note,
        ),
      );
      _actionError = null;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'updatePurchase');
    }
  }

  /// Delete a purchase
  Future<void> deletePurchase(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await purchaseService.delete(uid, id);
      _actionError = null;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'deletePurchase');
    }
  }

  @override
  void dispose() {
    _purchasesSubscription?.cancel();
    super.dispose();
  }
}
