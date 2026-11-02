import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../firebase/platform_support.dart';
import '../models/available_budget.dart';
import '../models/budget_group.dart';
import '../models/decision_rules.dart';
import '../models/owned_item.dart';
import '../models/price_insights.dart';
import '../models/price_snapshot.dart';
import '../models/purchase_item.dart';
import '../models/sale_event.dart';
import '../models/sale_plan.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/ai_decision_service.dart';
import '../services/budget_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';
import '../services/review_reminder_service.dart';
import '../services/wishlist_service.dart';
import 'deferred_notify.dart';

/// Label sentence of the Decision Card and where it came from
class DecisionReason {
  final String text;
  final bool fromAi;

  const DecisionReason(this.text, {required this.fromAi});
}

/// Decision Card labels (spec 7.4), their AI reason (AI feature 2), Lịch sale (8.2)
/// and the sale plan (7.5). Budgets are always this calendar month's, whatever month
/// Lịch sử / Ngân sách is showing.
class DecisionSupportViewModel extends ChangeNotifier with DeferredNotify {
  final BudgetService budgetService;
  final WishlistService wishlistService;
  final AiDecisionService aiDecisionService;
  final RemoteConfigService remoteConfigService;
  final PreferencesService preferencesService;

  /// Local "Nhắc đợt sale" notifications (Android/iOS); null in tests that skip them
  final ReviewReminderService? reminderService;
  final bool Function() _platformSupportsAi;
  final DateTime Function() _now;

  String? _uid;
  StreamSubscription<dynamic>? _budgetSubscription;
  Map<String, int> _limits = const {};
  List<PurchaseItem> _purchases = const [];
  List<WishlistItem> _items = const [];
  List<BudgetGroup> _groups = const [];
  List<OwnedItem> _ownedItems = const [];

  /// itemId|latestPriceAt → recorded prices; loaded once per latest price
  final Map<String, List<PriceSnapshot>?> _histories = {};

  DecisionSupportViewModel({
    required this.budgetService,
    required this.wishlistService,
    required this.aiDecisionService,
    required this.remoteConfigService,
    required this.preferencesService,
    this.reminderService,
    bool Function()? platformSupportsAi,
    DateTime Function()? now,
  }) : _platformSupportsAi =
           platformSupportsAi ?? (() => PlatformSupport.supportsFirebaseAi),
       _now = now ?? DateTime.now {
    _loadSaleReminderLevel();
  }

  DateTime get now => _now();

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _histories.clear();
    _subscribeBudget();
    // Signed out: the previous account's sale reminders must not fire
    if (uid == null) _syncSaleReminders();
  }

  /// Month whose limits are loaded; a new month (app left open overnight) re-subscribes
  String? _budgetMonth;

  void _subscribeBudget() {
    _budgetSubscription?.cancel();
    _budgetSubscription = null;
    _limits = const {};
    final uid = _uid;
    _budgetMonth = uid == null ? null : monthKey(now);
    if (uid == null) return;
    _budgetSubscription = budgetService
        .watchMonthlyBudget(uid, _budgetMonth!)
        .listen(
          (budget) {
            _limits = budget.limits;
            notifyListeners();
          },
          // No limits means "Chưa đủ dữ liệu", never a wrong number
          onError: (Object e) => debugPrint('Decision budget unavailable: $e'),
        );
  }

  /// Fed by the ProxyProvider during build
  void updateSources({
    required List<PurchaseItem> purchases,
    required List<WishlistItem> wishlistItems,
    required List<BudgetGroup> groups,
    List<OwnedItem> ownedItems = const [],
  }) {
    _purchases = purchases;
    _items = wishlistItems;
    _groups = groups;
    _ownedItems = ownedItems;
    if (_uid != null && monthKey(now) != _budgetMonth) _subscribeBudget();
    _syncSaleReminders();
    notifyLater();
  }

  // ---------- Nhắc đợt sale (spec 8.2, A-13) ----------

  SaleReminderLevel _saleReminderLevel = SaleReminderLevel.bigOnly;

  /// Reminders already handed to the plugin; the same list is not scheduled twice
  String? _scheduledSaleKey;

  SaleReminderLevel get saleReminderLevel => _saleReminderLevel;

  /// Local notifications exist on Android/iOS only; elsewhere Lịch sale is the fallback
  bool get supportsSaleReminders => reminderService?.isSupported ?? false;

  Future<void> _loadSaleReminderLevel() async {
    _saleReminderLevel = SaleReminderLevel.fromKey(
      await preferencesService.getSaleReminderLevel(),
    );
    if (isDisposed) return;
    _scheduledSaleKey = null;
    _syncSaleReminders();
    notifyListeners();
  }

  /// Saves the level; a level other than "Tắt" asks for notification permission
  /// (from the user's tap). Returns false when the permission was refused.
  Future<bool> setSaleReminderLevel(SaleReminderLevel level) async {
    _saleReminderLevel = level;
    notifyListeners();
    await preferencesService.setSaleReminderLevel(level.key);
    var granted = true;
    final reminders = reminderService;
    if (level != SaleReminderLevel.off &&
        reminders != null &&
        reminders.isSupported) {
      granted = await reminders.requestPermission();
    }
    _scheduledSaleKey = null;
    _syncSaleReminders();
    return granted;
  }

  /// One notification at 20:00 the evening before each confirmed sale, only while
  /// the list has items being considered: "Mai là 11.11. Bạn có 3 món trong danh sách."
  @visibleForTesting
  List<({String saleId, String saleType, String body, DateTime at})>
  plannedSaleReminders() {
    final count = _uid == null ? 0 : consideringItems.length;
    if (count == 0 || !remoteConfigService.saleReminderEnabled) return const [];
    return [
      for (final r in SaleCalendar.remindersFor(
        upcomingSales,
        _saleReminderLevel,
        now,
      ))
        (
          saleId: r.sale.id,
          saleType: r.sale.type.key,
          body:
              'Mai là ${r.sale.name}. Bạn có $count món trong danh sách. Mở xem nhé?',
          at: r.at,
        ),
    ];
  }

  void _syncSaleReminders() {
    final reminders = reminderService;
    if (reminders == null || !reminders.isSupported) return;
    final planned = plannedSaleReminders();
    final key = planned.map((r) => '${r.saleId}|${r.body}').join(';');
    if (key == _scheduledSaleKey) return;
    _scheduledSaleKey = key;
    unawaited(reminders.scheduleSaleReminders(planned));
  }

  List<BudgetGroup> get groups => _groups;

  String? groupName(String? groupId) => groupId == null
      ? null
      : _groups.where((g) => g.id == groupId).firstOrNull?.name;

  // ---------- Lịch sale ----------

  List<SaleEvent> get upcomingSales => SaleCalendar.upcoming(
    configured: SaleCalendar.parse(remoteConfigService.saleCalendarJson),
    now: now,
  );

  /// Confirmed sale close enough to count in the Decision Card (S6)
  SaleEvent? get saleForDecision => SaleCalendar.nextConfirmed(
    upcomingSales,
    now,
    withinDays: SaleCalendar.decisionWindowDays,
  );

  /// "Chờ – đến đợt sale": the next confirmed sale after today
  SaleEvent? get nextConfirmedSale {
    for (final e in upcomingSales) {
      if (e.confirmed && e.daysUntil(now) >= 1) return e;
    }
    return null;
  }

  SaleEvent? saleById(String? id) =>
      upcomingSales.where((e) => e.id == id).firstOrNull;

  /// Items still being considered, highest priority first ("Danh sách cho đợt sale")
  List<WishlistItem> get consideringItems =>
      _items.where((i) => i.status == WishlistStatus.considering).toList()
        ..sort((a, b) {
          final byPriority = b.priority.compareTo(a.priority);
          return byPriority != 0
              ? byPriority
              : a.createdAt.compareTo(b.createdAt);
        });

  // ---------- Ngân sách tháng này ----------

  /// "Phần khả dụng" of [groupId] this month; null when the group has no limit
  AvailableBudget? availableFor(String? groupId) {
    final limit = groupId == null ? null : _limits[groupId];
    if (limit == null) return null;
    DateTime? first;
    for (final p in _purchases) {
      if (first == null || p.occurredAt.isBefore(first)) first = p.occurredAt;
    }
    final current = now;
    return AvailableBudget.compute(
      limit: limit,
      month: DateTime(current.year, current.month),
      groupPurchases: [
        for (final p in _purchases)
          if (p.budgetGroupId == groupId) p,
      ],
      firstPurchaseAt: first,
      now: current,
    );
  }

  // ---------- Decision Card ----------

  DecisionAssessment assess(WishlistItem item) {
    final groupId = item.budgetGroupId;
    return DecisionRules.assess(
      DecisionInput(
        item: item,
        now: now,
        groupName: groupName(groupId),
        available: availableFor(groupId),
        savedPriceVnd: priceInsightsFor(item)?.saved?.amountVnd,
        sameGroupCount: groupId == null
            ? 0
            : _items
                  .where(
                    (i) =>
                        i.id != item.id &&
                        i.budgetGroupId == groupId &&
                        i.status == WishlistStatus.considering,
                  )
                  .length,
        upcomingSale: saleForDecision,
        ownedMatches: [
          for (final o in _ownedItems)
            if (o.matches(title: item.title, budgetGroupId: groupId)) o,
        ],
      ),
    );
  }

  /// A-15: items still being considered in the item's group, the item itself first
  List<WishlistItem> sameGroupItems(WishlistItem item) {
    final groupId = item.budgetGroupId;
    if (groupId == null) return [item];
    return [
      item,
      for (final i in consideringItems)
        if (i.id != item.id && i.budgetGroupId == groupId) i,
    ];
  }

  static String _priceKey(WishlistItem item) =>
      '${item.id}|${item.latestPriceAt?.millisecondsSinceEpoch}';

  /// A-14: price history of [item]; null until [loadPriceHistory] has finished
  PriceInsights? priceInsightsFor(WishlistItem item) {
    final history = _histories[_priceKey(item)];
    return history == null ? null : PriceInsights(history, now: now);
  }

  /// Loads the history once per latest price; the card and the history redraw when it
  /// arrives (S3 compares with the first record, "giá lúc lưu")
  Future<void> loadPriceHistory(WishlistItem item) async {
    final uid = _uid;
    final key = _priceKey(item);
    if (uid == null || item.latestPriceVnd == null) return;
    if (_histories.containsKey(key)) return;
    _histories[key] = null;
    try {
      _histories[key] = await wishlistService.priceHistory(uid, item.id);
      if (!isDisposed) notifyListeners();
    } catch (e) {
      _histories.remove(key);
      debugPrint('Price history unavailable: $e');
    }
  }

  Future<bool> _aiAllowed() async =>
      _platformSupportsAi() &&
      remoteConfigService.enableAiSuggestions &&
      await preferencesService.getAiInsightEnabled();

  /// AI wording when allowed and acceptable; otherwise the label's template sentence
  Future<DecisionReason> reasonFor(DecisionAssessment assessment) async {
    if (await _aiAllowed()) {
      try {
        final text = await aiDecisionService.reasonFor(assessment);
        if (text != null) return DecisionReason(text, fromAi: true);
      } catch (e) {
        debugPrint('AI decision reason unavailable: $e');
      }
    }
    return DecisionReason(assessment.templateReason, fromAi: false);
  }

  // ---------- Lập kế hoạch cho đợt sale ----------

  /// Only run when the user asks for it (spec 7.5)
  SalePlanResult plan() {
    final available = <String, int>{
      for (final g in _groups)
        if (availableFor(g.id) case final a?) g.id: a.available,
    };
    return SalePlanner.plan(
      items: consideringItems,
      groups: _groups,
      available: available,
      now: now,
      fitByMotive: SalePlanner.fitByMotive(_purchases),
    );
  }

  /// AI feature 5: 1–2 sentences per plan; the template wherever AI is off or rejected
  Future<Map<PlanOption, DecisionReason>> explainPlans(
    SalePlanResult result,
  ) async {
    final explanations = {
      for (final p in result.plans)
        p.option: DecisionReason(p.templateExplanation, fromAi: false),
    };
    if (result.isEmpty || !await _aiAllowed()) return explanations;
    try {
      final fromAi = await aiDecisionService.explainPlans(result);
      for (final e in fromAi.entries) {
        explanations[e.key] = DecisionReason(e.value, fromAi: true);
      }
    } catch (e) {
      debugPrint('AI plan explanation unavailable: $e');
    }
    return explanations;
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
