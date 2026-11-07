import 'package:flutter/foundation.dart';

import '../core/utils/price_history_ids.dart';
import '../models/daily_price.dart';
import '../models/price_history.dart';
import '../models/sale_event.dart';
import '../models/same_product.dart';
import '../models/ui_state.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/price_history_service.dart';
import 'error_reporting.dart';

/// Period of "Biểu đồ giá tham khảo"
enum PriceHistoryRange {
  week(7, '7 ngày'),
  month(30, '30 ngày'),
  quarter(90, '90 ngày');

  final int days;
  final String label;

  const PriceHistoryRange(this.days, this.label);

  static const PriceHistoryRange longest = quarter;
}

/// A list price on a given day, with where it was seen
class PriceOnDay {
  final int vnd;

  /// Vietnamese date (UTC fields)
  final DateTime day;
  final String productKey;

  /// From the reports, else the product; null only when neither has one
  final String? shopName;
  final double? productRating;

  const PriceOnDay({
    required this.vnd,
    required this.day,
    required this.productKey,
    this.shopName,
    this.productRating,
  });
}

/// Summary of the period, list prices only (never after-voucher)
class PeriodSummary {
  /// Lowest price of the period (earliest day on a tie)
  final PriceOnDay? lowest;

  /// Lowest price of the most recent day with a price, with its day and shop
  final PriceOnDay? latest;

  /// Each shop's most recent price (group: every shop that has one, group order)
  final List<PriceOnDay> latestByShop;
  final int daysWithData;

  const PeriodSummary({
    this.lowest,
    this.latest,
    this.latestByShop = const [],
    this.daysWithData = 0,
  });

  int? get lastPrice => latest?.vnd;
  DateTime? get lastPriceDate => latest?.day;
  String? get lastPriceShopName => latest?.shopName;
}

/// Everything the chart screen draws for the selected period
class PriceHistoryView {
  final PriceHistoryRange range;

  /// Vietnamese dates of the period, oldest first; every list below has this length
  final List<DateTime> days;

  /// Selected product, or the group's products in the group's order
  final Map<String, PriceHistoryProduct?> products;
  final Map<String, List<DailyPricePoint>> points;

  /// Group only: lowest price and highest rating of each day
  final List<GroupDayComparison?>? comparison;
  final ProductGroup? group;
  final List<SaleEvent> saleEvents;
  final PeriodSummary summary;

  const PriceHistoryView({
    required this.range,
    required this.days,
    required this.products,
    required this.points,
    this.comparison,
    this.group,
    this.saleEvents = const [],
    this.summary = const PeriodSummary(),
  });

  bool get isGroup => group != null;

  /// Shown with "Dữ liệu mẫu"
  bool get isDemo =>
      (group?.isDemo ?? false) ||
      products.values.any((p) => p?.isDemo ?? false);
}

/// "Biểu đồ giá tham khảo": one product, or every shop of a group, over 7 / 30 / 90
/// days. Data is shared (not per user), so there is no uid. Reports are loaded once
/// for the longest period; changing the period only recomputes.
class PriceHistoryViewModel extends ChangeNotifier with ErrorReporting {
  static const String notEnoughData = 'Chưa đủ dữ liệu';

  final PriceHistoryService service;
  @override
  final CrashlyticsService? crashlyticsService;
  final DateTime Function() _now;

  /// view_price_history after each result; null for previews (Chi tiết món card)
  final AppAnalyticsService? analytics;

  PriceHistoryViewModel({
    required this.service,
    this.crashlyticsService,
    this.analytics,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  UiState<PriceHistoryView> _state = const UiInitial();
  PriceHistoryRange _range = PriceHistoryRange.month;
  String? _productKey;
  String? _groupId;

  /// G8, real products: the item and the same item in other shops, one variant
  List<String>? _sameKeys;
  String? _sameVariant;
  String _sameName = '';
  int _load = 0;
  bool _disposed = false;

  // Loaded for the longest period
  ProductGroup? _group;
  Map<String, PriceHistoryProduct?> _products = const {};
  Map<String, List<PriceHistoryReport>> _reports = const {};
  List<SaleEvent> _saleEvents = const [];

  UiState<PriceHistoryView> get state => _state;
  PriceHistoryRange get range => _range;
  String? get productKey => _productKey;
  String? get groupId => _groupId;
  bool get isSameProduct => _sameKeys != null;

  /// Reports loaded (the longest period, after-voucher ones included), for "Chưa đủ
  /// người ghi giá để vẽ đường cộng đồng (n lần ghi)" (G6b)
  int get reportCount => _reports.values.fold(0, (n, r) => n + r.length);

  Future<void> openProduct(String productKey) {
    _productKey = productKey;
    _groupId = null;
    _sameKeys = null;
    return _fetch();
  }

  /// Sample data only (productGroups)
  Future<void> openGroup(String groupId) {
    _groupId = groupId;
    _productKey = null;
    _sameKeys = null;
    return _fetch();
  }

  /// "Cả nhóm" of a real product (G8): [productKeys] = the item and the shops of
  /// "Cùng món ở shop khác", same productCode. Only reports of [variantCode] count
  /// (null: listings without variants). Shown like a group named [name].
  Future<void> openSameProduct(
    List<String> productKeys, {
    String? variantCode,
    required String name,
  }) {
    _sameKeys = productKeys;
    _sameVariant = variantCode;
    _sameName = name;
    _productKey = null;
    _groupId = null;
    return _fetch();
  }

  void setRange(PriceHistoryRange range) {
    if (range == _range) return;
    _range = range;
    if (_state is UiSuccess || _state is UiEmpty) _publish();
  }

  Future<void> retry() => _fetch();

  /// First instant of the Vietnamese day [daysBack] days before today
  DateTime _startOf(int daysBack) =>
      vnDate(_now())
          .subtract(Duration(days: daysBack))
          .subtract(PriceHistoryIds.vietnamOffset);

  Future<void> _fetch() async {
    if (_productKey == null && _groupId == null && _sameKeys == null) return;
    final load = ++_load;
    _set(const UiLoading());
    try {
      final now = _now();
      final from = _startOf(PriceHistoryRange.longest.days - 1);
      ProductGroup? group;
      List<String> keys;
      if (_groupId case final id?) {
        group = await service.fetchGroup(id);
        keys = group?.productKeys ?? const [];
      } else if (_sameKeys case final same?) {
        keys = same;
      } else {
        keys = [_productKey!];
      }
      var results = await Future.wait([
        for (final k in keys) service.fetchReports(k, from),
      ]);
      final products = await Future.wait([
        for (final k in keys) service.watchProduct(k).first,
      ]);
      if (_sameKeys != null) {
        // The same variant in every shop; drawn like a group
        results = [
          for (var i = 0; i < keys.length; i++)
            [
              for (final r in results[i])
                if (products[i] case final p?
                    when SameProduct.matchesVariant(
                      p,
                      r.modelKey,
                      _sameVariant,
                    ))
                  r,
            ],
        ];
        group = ProductGroup(
          id: '',
          name: _sameName,
          productKeys: keys,
          isDemo: products.any((p) => p?.isDemo ?? false),
        );
      }
      final sales = await service.fetchSaleEvents(from, now);
      if (load != _load || _disposed) return;
      _group = group;
      _reports = {for (var i = 0; i < keys.length; i++) keys[i]: results[i]};
      _products = {for (var i = 0; i < keys.length; i++) keys[i]: products[i]};
      _saleEvents = sales;
      _publish();
    } catch (e, stack) {
      if (load != _load || _disposed) return;
      _set(
        UiError(
          message: messageFor(e, stack, reason: 'price history load'),
          onRetry: retry,
        ),
      );
    }
  }

  void _publish() {
    final now = _now();
    final from = _startOf(_range.days - 1);
    final days = vnDays(from, now);
    final points = {
      for (final MapEntry(:key, :value) in _reports.entries)
        key: aggregateDaily(value, from, now),
    };
    final comparison = _group == null ? null : compareGroup(points);
    final summary = _summarize(days, points, _products);
    final isDemo =
        (_group?.isDemo ?? false) ||
        _products.values.any((p) => p?.isDemo ?? false);
    analytics?.logViewPriceHistory(
      mode: _group == null ? 'product' : 'group',
      rangeDays: _range.days,
      isDemo: isDemo,
    );
    if (summary.daysWithData == 0) {
      final longer = _range != PriceHistoryRange.longest;
      _set(
        UiEmpty(
          message: notEnoughData,
          actionTitle: longer ? 'Xem ${PriceHistoryRange.longest.label}' : null,
          onAction: longer ? () => setRange(PriceHistoryRange.longest) : null,
        ),
      );
      return;
    }
    final firstDay = days.first;
    _set(
      UiSuccess(
        PriceHistoryView(
          range: _range,
          days: days,
          products: _products,
          points: points,
          comparison: comparison,
          group: _group,
          saleEvents: [
            for (final e in _saleEvents)
              if (!vnDate(e.date).isBefore(firstDay)) e,
          ],
          summary: summary,
        ),
      ),
    );
  }

  static PeriodSummary _summarize(
    List<DateTime> days,
    Map<String, List<DailyPricePoint>> points,
    Map<String, PriceHistoryProduct?> products,
  ) {
    PriceOnDay? at(String key, DailyPricePoint p) => switch (p.minVnd) {
      final vnd? => PriceOnDay(
        vnd: vnd,
        day: p.day,
        productKey: key,
        // A user's product may not have its shop name yet ('')
        shopName:
            p.shopName ??
            switch (products[key]?.shopName) {
              final name? when name.isNotEmpty => name,
              _ => null,
            },
        productRating: p.productRating,
      ),
      null => null,
    };
    PriceOnDay? lowest, latest;
    var daysWithData = 0;
    for (var i = 0; i < days.length; i++) {
      PriceOnDay? dayLow;
      for (final MapEntry(:key, :value) in points.entries) {
        if (i >= value.length) continue;
        final price = at(key, value[i]);
        if (price != null && (dayLow == null || price.vnd < dayLow.vnd)) {
          dayLow = price;
        }
      }
      if (dayLow == null) continue;
      daysWithData++;
      latest = dayLow;
      if (lowest == null || dayLow.vnd < lowest.vnd) lowest = dayLow;
    }
    return PeriodSummary(
      lowest: lowest,
      latest: latest,
      latestByShop: [
        for (final MapEntry(:key, :value) in points.entries)
          ?_lastPrice(key, value, at),
      ],
      daysWithData: daysWithData,
    );
  }

  static PriceOnDay? _lastPrice(
    String key,
    List<DailyPricePoint> points,
    PriceOnDay? Function(String, DailyPricePoint) at,
  ) {
    for (final p in points.reversed) {
      if (p.hasPrice) return at(key, p);
    }
    return null;
  }

  void _set(UiState<PriceHistoryView> state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
