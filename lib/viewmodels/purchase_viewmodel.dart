import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';

/// ViewModel managing Purchases with real-time Firebase Cloud Firestore sync
class PurchaseViewModel extends ChangeNotifier {
  final PurchaseService? purchaseService;
  final AppAnalyticsService? analyticsService;

  StreamSubscription<List<PurchaseItem>>? _purchasesSubscription;
  StreamSubscription<Map<String, dynamic>?>? _budgetSubscription;
  List<PurchaseItem> _purchases = [];
  String _currentUserId = '';
  BuyingMotive? _selectedMotiveFilter;
  DateTime _selectedMonth = DateTime(2026, 10, 1);
  double _monthlyBudget = 2000000; // Default: 2.000.000 ₫
  Map<String, double> _categoryBudgets = {
    'Ăn uống': 500000,
    'Thời trang': 600000,
    'Công nghệ': 1000000,
  };
  bool _isSyncing = false;

  PurchaseViewModel({this.purchaseService, this.analyticsService}) {
    _seedDefaultData();
  }

  bool get isSyncing => _isSyncing;
  String get currentUserId => _currentUserId;

  /// Initialize with realistic seed data exactly matching Figma "Why I Buy ver2"
  void _seedDefaultData() {
    _purchases = [
      // Tháng 10/2026 (5 khoản - 817.000 ₫)
      PurchaseItem(
        id: 'seed-1',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Cơm tấm',
        amount: 40000,
        motive: BuyingMotive.convenience,
        dateTime: DateTime(2026, 10, 11, 12, 15),
        note: 'Trưa bận việc công ty nên ăn nhanh gần văn phòng',
      ),
      PurchaseItem(
        id: 'seed-2',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Tai nghe Bluetooth',
        amount: 389000,
        motive: BuyingMotive.sale,
        dateTime: DateTime(2026, 10, 10, 23, 40),
        note: 'Săn sale lúc nửa đêm đợt flash sale giảm 35%',
      ),
      PurchaseItem(
        id: 'seed-3',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Trà sữa nướng',
        amount: 45000,
        motive: BuyingMotive.emotion,
        dateTime: DateTime(2026, 10, 10, 15, 30),
        note: 'Buồn vì công việc nên muốn uống gì ngọt',
      ),
      PurchaseItem(
        id: 'seed-4',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Sách Tâm lý học về tiền',
        amount: 143000,
        motive: BuyingMotive.want,
        dateTime: DateTime(2026, 10, 9, 9, 20),
        note: 'Thấy review hay trên diễn đàn đọc sách',
      ),
      PurchaseItem(
        id: 'seed-5',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Áo khoác gió Uniqlo',
        amount: 200000,
        motive: BuyingMotive.sale,
        dateTime: DateTime(2026, 10, 8, 19, 45),
        note: 'Cửa hàng đang giảm giá cuối mùa',
      ),

      // Tháng 9/2026 (Figma 06/07 tháng 9/2026)
      PurchaseItem(
        id: 'seed-sep-1',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Giày chạy bộ thể thao',
        amount: 1250000,
        motive: BuyingMotive.need,
        dateTime: DateTime(2026, 9, 28, 16, 20),
        note: 'Đổi giày mới để tập thể dục chuẩn bị giải chạy',
      ),
      PurchaseItem(
        id: 'seed-sep-2',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Bàn phím cơ văn phòng',
        amount: 450000,
        motive: BuyingMotive.want,
        dateTime: DateTime(2026, 9, 15, 10, 0),
        note: 'Gõ êm tay hơn khi làm việc buổi tối',
      ),
      PurchaseItem(
        id: 'seed-sep-3',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'demo-user',
        title: 'Cà phê & Bánh ngọt',
        amount: 85000,
        motive: BuyingMotive.emotion,
        dateTime: DateTime(2026, 9, 5, 14, 30),
        note: 'Hẹn bạn bè tâm sự cuối tuần',
      ),
    ];
    notifyListeners();
  }

  /// Bind to user's Firestore purchases stream
  void setUserId(String userId) {
    if (_currentUserId == userId && _purchasesSubscription != null) return;
    _currentUserId = userId;
    _purchasesSubscription?.cancel();
    _budgetSubscription?.cancel();

    if (userId.isEmpty || purchaseService == null) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    _purchasesSubscription = purchaseService!
        .streamUserPurchases(userId)
        .listen(
          (cloudItems) {
            _isSyncing = false;
            if (cloudItems.isNotEmpty) {
              _purchases = cloudItems;
            } else if (_purchases.isEmpty) {
              _seedDefaultData();
            }
            notifyListeners();
          },
          onError: (err) {
            _isSyncing = false;
            debugPrint('Purchase Firestore stream error: $err');
            notifyListeners();
          },
        );

    _subscribeToBudget();
  }

  String get currentMonthKey => monthKey(_selectedMonth);

  void _subscribeToBudget() {
    _budgetSubscription?.cancel();
    if (_currentUserId.isEmpty || purchaseService == null) return;

    _budgetSubscription = purchaseService!
        .streamMonthlyBudget(_currentUserId, currentMonthKey)
        .listen(
          (data) {
            if (data != null) {
              if (data['monthlyLimit'] != null) {
                _monthlyBudget = (data['monthlyLimit'] as num).toDouble();
              }
              if (data['categoryBudgets'] != null) {
                final catData = data['categoryBudgets'] as Map<String, dynamic>;
                _categoryBudgets = catData.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                );
              }
              notifyListeners();
            }
          },
          onError: (err) {
            debugPrint('Budget Firestore stream error: $err');
          },
        );
  }

  List<PurchaseItem> get allPurchases => List.unmodifiable(_purchases);

  List<PurchaseItem> get recentPurchases => monthPurchases.take(3).toList();

  BuyingMotive? get selectedMotiveFilter => _selectedMotiveFilter;
  DateTime get selectedMonth => _selectedMonth;

  /// Purchases belonging to currently selected month
  List<PurchaseItem> get monthPurchases {
    return _purchases.where((item) {
      return item.dateTime.year == _selectedMonth.year &&
          item.dateTime.month == _selectedMonth.month;
    }).toList();
  }

  /// Filtered by both selected month and active motive filter
  List<PurchaseItem> get filteredPurchases {
    return _purchases.where((item) {
      final matchesMonth =
          item.dateTime.year == _selectedMonth.year &&
          item.dateTime.month == _selectedMonth.month;
      if (!matchesMonth) return false;
      if (_selectedMotiveFilter != null &&
          item.motive != _selectedMotiveFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Monthly total spent
  double get weeklyTotal {
    return monthPurchases.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Monthly count
  int get weeklyCount => monthPurchases.length;

  /// Monthly budget settings & calculations
  double get monthlyBudget => _monthlyBudget;
  double get monthlySpent => weeklyTotal;
  double get budgetProgress => _monthlyBudget > 0
      ? (monthlySpent / _monthlyBudget).clamp(0.0, 1.0)
      : 0.0;
  bool get isBudgetExceeded =>
      monthlySpent > _monthlyBudget && _monthlyBudget > 0;
  double get budgetRemaining => _monthlyBudget - monthlySpent;

  Map<String, double> get categoryBudgets => Map.unmodifiable(_categoryBudgets);

  /// Calculate spending per category based on item names/motives for Figma 31
  Map<String, double> get categorySpent {
    final map = <String, double>{
      'Ăn uống': 0,
      'Thời trang': 0,
      'Công nghệ': 0,
      'Khác': 0,
    };
    for (final p in monthPurchases) {
      final lower = p.title.toLowerCase();
      if (lower.contains('cơm') ||
          lower.contains('trà sữa') ||
          lower.contains('cà phê') ||
          lower.contains('bánh') ||
          lower.contains('ăn') ||
          lower.contains('uống') ||
          lower.contains('nước')) {
        map['Ăn uống'] = (map['Ăn uống'] ?? 0) + p.amount;
      } else if (lower.contains('áo') ||
          lower.contains('quần') ||
          lower.contains('giày') ||
          lower.contains('dép') ||
          lower.contains('uniqlo') ||
          lower.contains('túi')) {
        map['Thời trang'] = (map['Thời trang'] ?? 0) + p.amount;
      } else if (lower.contains('tai nghe') ||
          lower.contains('bàn phím') ||
          lower.contains('chuột') ||
          lower.contains('máy') ||
          lower.contains('điện thoại') ||
          lower.contains('laptop') ||
          lower.contains('loa')) {
        map['Công nghệ'] = (map['Công nghệ'] ?? 0) + p.amount;
      } else {
        map['Khác'] = (map['Khác'] ?? 0) + p.amount;
      }
    }
    return map;
  }

  /// Set and persist monthly budget + category budgets to Firestore
  Future<void> setMonthlyBudget(
    double amount, {
    Map<String, double>? categoryBudgets,
  }) async {
    _monthlyBudget = amount;
    if (categoryBudgets != null) {
      _categoryBudgets = Map.from(categoryBudgets);
    }
    notifyListeners();

    final monthKey = currentMonthKey;

    if (purchaseService != null && _currentUserId.isNotEmpty) {
      try {
        await purchaseService!.saveMonthlyBudget(
          userId: _currentUserId,
          month: monthKey,
          monthlyLimit: amount,
          categoryBudgets: _categoryBudgets,
        );
      } catch (e) {
        debugPrint('Firestore saveMonthlyBudget error: $e');
      }
    }

    unawaited(
      analyticsService?.logBudgetSet(amount: amount, month: monthKey) ??
          Future<void>.value(),
    );
  }

  /// Month navigation
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    _subscribeToBudget();
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    _subscribeToBudget();
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _subscribeToBudget();
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

  /// Most frequent motive (Figma: Khuyến mãi (2/5), 40%)
  String get dominantMotiveText {
    final list = monthPurchases;
    if (list.isEmpty) return 'Chưa có khoản chi';
    final dist = motiveDistribution;
    BuyingMotive? topMotive;
    double maxRatio = -1;
    for (final entry in dist.entries) {
      if (entry.value > maxRatio) {
        maxRatio = entry.value;
        topMotive = entry.key;
      }
    }
    if (topMotive == null) return '';
    final percent = (maxRatio * 100).round();
    return '$percent% do ${topMotive.label}';
  }

  String get dominantMotiveSummary {
    final list = monthPurchases;
    if (list.isEmpty) return 'Chưa có khoản chi';
    final dist = motiveDistribution;
    BuyingMotive? topMotive;
    double maxRatio = -1;
    for (final entry in dist.entries) {
      if (entry.value > maxRatio) {
        maxRatio = entry.value;
        topMotive = entry.key;
      }
    }
    if (topMotive == null) return '';
    final count = list.where((p) => p.motive == topMotive).length;
    return 'Nhiều nhất: ${topMotive.label} ($count/${list.length})';
  }

  void setMotiveFilter(BuyingMotive? motive) {
    _selectedMotiveFilter = motive;
    notifyListeners();
  }

  /// Add new purchase (Saves to Cloud Firestore + Local Cache + Analytics)
  Future<PurchaseItem> addPurchase({
    required String title,
    required double amount,
    required BuyingMotive motive,
    DateTime? dateTime,
    String? note,
  }) async {
    final effectiveTime = dateTime ?? DateTime.now();
    final effectiveUserId = _currentUserId.isNotEmpty
        ? _currentUserId
        : 'demo-user';

    PurchaseItem newItem;

    if (purchaseService != null && _currentUserId.isNotEmpty) {
      try {
        newItem = await purchaseService!.addPurchase(
          userId: effectiveUserId,
          title: title,
          amount: amount,
          motive: motive,
          dateTime: effectiveTime,
          note: note,
        );
      } catch (e) {
        debugPrint('Firestore addPurchase error, fallback to local: $e');
        newItem = PurchaseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: effectiveUserId,
          title: title,
          amount: amount,
          motive: motive,
          dateTime: effectiveTime,
          note: note,
        );
      }
    } else {
      newItem = PurchaseItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: effectiveUserId,
        title: title,
        amount: amount,
        motive: motive,
        dateTime: effectiveTime,
        note: note,
      );
    }

    _purchases.insert(0, newItem);
    notifyListeners();

    unawaited(
      analyticsService?.logPurchaseRecorded(
            itemId: newItem.id,
            price: newItem.amount,
            motive: newItem.motive.key,
          ) ??
          Future<void>.value(),
    );

    return newItem;
  }

  /// Update an existing purchase
  Future<void> updatePurchase({
    required String id,
    required String title,
    required double amount,
    required BuyingMotive motive,
    required DateTime dateTime,
    String? note,
  }) async {
    final index = _purchases.indexWhere((p) => p.id == id);
    if (index != -1) {
      _purchases[index] = _purchases[index].copyWith(
        title: title,
        amount: amount,
        motive: motive,
        dateTime: dateTime,
        note: note,
      );
      notifyListeners();
    }

    if (purchaseService != null &&
        _currentUserId.isNotEmpty &&
        !id.startsWith('seed-')) {
      try {
        await purchaseService!.updatePurchase(
          purchaseId: id,
          title: title,
          amount: amount,
          motive: motive,
          dateTime: dateTime,
          note: note,
        );
      } catch (e) {
        debugPrint('Firestore updatePurchase error: $e');
      }
    }
  }

  /// Delete a purchase
  Future<void> deletePurchase(String id) async {
    _purchases.removeWhere((p) => p.id == id);
    notifyListeners();

    if (purchaseService != null &&
        _currentUserId.isNotEmpty &&
        !id.startsWith('seed-')) {
      try {
        await purchaseService!.deletePurchase(id);
      } catch (e) {
        debugPrint('Firestore deletePurchase error: $e');
      }
    }
  }

  @override
  void dispose() {
    _purchasesSubscription?.cancel();
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
