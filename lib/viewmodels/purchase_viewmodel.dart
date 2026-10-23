import 'package:flutter/foundation.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../services/analytics_service.dart';

/// ViewModel managing Purchases, monthly budget, month navigation, and analytics
class PurchaseViewModel extends ChangeNotifier {
  final AppAnalyticsService? analyticsService;

  List<PurchaseItem> _purchases = [];
  BuyingMotive? _selectedMotiveFilter;
  DateTime _selectedMonth = DateTime(2026, 10, 1);
  double _monthlyBudget = 2000000; // Default: 2.000.000 ₫

  PurchaseViewModel({this.analyticsService}) {
    _seedDefaultData();
  }

  /// Initialize with realistic seed data exactly matching Figma "Why I Buy ver2"
  void _seedDefaultData() {
    _purchases = [
      // Tháng 10/2026 (5 khoản - 817.000 ₫)
      PurchaseItem(
        id: 'seed-1',
        userId: 'demo-user',
        title: 'Cơm tấm',
        amount: 40000,
        motive: BuyingMotive.convenience,
        dateTime: DateTime(2026, 10, 11, 12, 15),
        note: 'Trưa bận việc công ty nên ăn nhanh gần văn phòng',
      ),
      PurchaseItem(
        id: 'seed-2',
        userId: 'demo-user',
        title: 'Tai nghe Bluetooth',
        amount: 389000,
        motive: BuyingMotive.sale,
        dateTime: DateTime(2026, 10, 10, 23, 40),
        note: 'Săn sale lúc nửa đêm đợt flash sale giảm 35%',
      ),
      PurchaseItem(
        id: 'seed-3',
        userId: 'demo-user',
        title: 'Trà sữa nướng',
        amount: 45000,
        motive: BuyingMotive.emotion,
        dateTime: DateTime(2026, 10, 10, 15, 30),
        note: 'Buồn vì công việc nên muốn uống gì ngọt',
      ),
      PurchaseItem(
        id: 'seed-4',
        userId: 'demo-user',
        title: 'Sách Tâm lý học về tiền',
        amount: 143000,
        motive: BuyingMotive.want,
        dateTime: DateTime(2026, 10, 9, 9, 20),
        note: 'Thấy review hay trên diễn đàn đọc sách',
      ),
      PurchaseItem(
        id: 'seed-5',
        userId: 'demo-user',
        title: 'Áo khoác gió Uniqlo',
        amount: 200000,
        motive: BuyingMotive.sale,
        dateTime: DateTime(2026, 10, 8, 19, 45),
        note: 'Cửa hàng đang giảm giá cuối mùa',
      ),

      // Tháng 9/2026 (Figma 06/07 tháng 9/2026)
      PurchaseItem(
        id: 'seed-sep-1',
        userId: 'demo-user',
        title: 'Giày chạy bộ thể thao',
        amount: 1250000,
        motive: BuyingMotive.need,
        dateTime: DateTime(2026, 9, 28, 16, 20),
        note: 'Đổi giày mới để tập thể dục chuẩn bị giải chạy',
      ),
      PurchaseItem(
        id: 'seed-sep-2',
        userId: 'demo-user',
        title: 'Bàn phím cơ văn phòng',
        amount: 450000,
        motive: BuyingMotive.want,
        dateTime: DateTime(2026, 9, 15, 10, 0),
        note: 'Gõ êm tay hơn khi làm việc buổi tối',
      ),
      PurchaseItem(
        id: 'seed-sep-3',
        userId: 'demo-user',
        title: 'Cà phê & Bánh ngọt',
        amount: 85000,
        motive: BuyingMotive.emotion,
        dateTime: DateTime(2026, 9, 5, 14, 30),
        note: 'Hẹn bạn bè tâm sự cuối tuần',
      ),
    ];
    notifyListeners();
  }

  List<PurchaseItem> get allPurchases => List.unmodifiable(_purchases);

  List<PurchaseItem> get recentPurchases => _purchases.take(3).toList();

  BuyingMotive? get selectedMotiveFilter => _selectedMotiveFilter;
  DateTime get selectedMonth => _selectedMonth;

  /// Purchases belonging to currently selected month
  List<PurchaseItem> get monthPurchases {
    return _purchases.where((item) {
      return item.dateTime.year == _selectedMonth.year && item.dateTime.month == _selectedMonth.month;
    }).toList();
  }

  /// Filtered by both selected month and active motive filter
  List<PurchaseItem> get filteredPurchases {
    return _purchases.where((item) {
      final matchesMonth = item.dateTime.year == _selectedMonth.year && item.dateTime.month == _selectedMonth.month;
      if (!matchesMonth) return false;
      if (_selectedMotiveFilter != null && item.motive != _selectedMotiveFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Weekly total spent (Figma: 817.000 ₫)
  double get weeklyTotal {
    return monthPurchases.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Weekly count (Figma: 5)
  int get weeklyCount => monthPurchases.length;

  /// Monthly budget settings & calculations
  double get monthlyBudget => _monthlyBudget;
  double get monthlySpent => weeklyTotal;
  double get budgetProgress => _monthlyBudget > 0 ? (monthlySpent / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
  bool get isBudgetExceeded => monthlySpent > _monthlyBudget && _monthlyBudget > 0;
  double get budgetRemaining => _monthlyBudget - monthlySpent;

  void setMonthlyBudget(double amount) {
    _monthlyBudget = amount;
    notifyListeners();
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
    _selectedMonth = DateTime(month.year, month.month, 1);
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

  void addPurchase({
    required String title,
    required double amount,
    required BuyingMotive motive,
    DateTime? dateTime,
    String? note,
  }) {
    final newItem = PurchaseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current-user',
      title: title,
      amount: amount,
      motive: motive,
      dateTime: dateTime ?? DateTime.now(),
      note: note,
    );
    _purchases.insert(0, newItem);
    notifyListeners();

    analyticsService?.logPurchaseRecorded(
      itemId: newItem.id,
      price: newItem.amount,
      motive: newItem.motive.key,
    );
  }

  void deletePurchase(String id) {
    _purchases.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
