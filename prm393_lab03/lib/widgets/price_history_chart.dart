import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/daily_price.dart';
import '../models/sale_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_viewmodel.dart';
import 'demo_data_badge.dart';

/// "Biểu đồ giá tham khảo", in a rounded card: a caption saying what the band is, a
/// light band from the lowest to the highest price of each day (between the shops of
/// a group, between the reports of one product) and ONE violet line of the lowest
/// price, each day flat over the middle of its column and eased into the next day's
/// price by a short S-curve ([smoothSteps]). A day without a new price keeps
/// the latest ones for at most [maxHeldDays] days, the line dashed and fainter; after
/// that the chart breaks. No price axis and no grid: one green dot on the lowest point
/// with its price in short ("490k"), a dashed "giá lúc bạn lưu" line labelled on the
/// right, sale days as dashed vertical lines named above the plot, and the first and
/// last day under it plus the days the price moved ([axisDayIndices]). Under the card: the day touched (or picked in the list) and the
/// price milestones of the period. Below [minChartDays] days with a price, only the
/// milestones are shown.
class PriceHistoryChart extends StatefulWidget {
  /// A day without a new price keeps the latest one this many days at most
  static const int maxHeldDays = 7;

  /// Fewer days with a price than this: no chart, only the milestones
  static const int minChartDays = 5;

  final PriceHistoryView view;
  final ValueChanged<PriceHistoryRange>? onRangeChanged;

  /// "Giá lúc bạn lưu": only when it can be compared (same variant, a list price)
  final SavedPrice? savedPrice;

  /// Day shown in the details panel at first (index in [PriceHistoryView.days])
  final int? initialSelectedDay;

  /// Height of the plot, sale names above it included (not the dates under it)
  final double chartHeight;

  /// "Giá bạn ghi" (G6b): the user's own price of a day (index in
  /// [PriceHistoryView.days]), drawn as a small hollow dot, never joined
  final Map<int, int> ownPrices;

  /// Line above the plot instead of what the band means (e.g. "Giá bạn đã ghi")
  final String? caption;

  const PriceHistoryChart({
    super.key,
    required this.view,
    this.onRangeChanged,
    this.savedPrice,
    this.initialSelectedDay,
    this.chartHeight = 150,
    this.ownPrices = const {},
    this.caption,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

/// The user's list price when saving the item, drawn as a reference line
class SavedPrice {
  final int vnd;
  final DateTime savedAt;

  const SavedPrice({required this.vnd, required this.savedAt});
}

/// Short range labels like SteamDB
const _rangeLabels = {
  PriceHistoryRange.week: '7N',
  PriceHistoryRange.month: '30N',
  PriceHistoryRange.quarter: '90N',
};

/// Dash of a held price (no new price that day), drawn fainter than the line
const List<int> _heldDash = [3, 4];

/// Dash of the "Giá lúc bạn lưu" line
const List<int> _savedDash = [6, 4];

/// Room above the plot for the names of the sale days
const double _saleLabelHeight = 18;

/// The lowest-price line and its band: violet, readable on both themes
Color priceLineColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? AppColors.purpleLight
    : AppColors.purple;

/// The dot on the lowest point of the period
Color lowestDotColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? AppColors.successLight
    : AppColors.onSuccessContainer;

/// "11.11" for a double day, else the name when short, else the day
String saleShortLabel(SaleEvent e) {
  final day = vnDate(e.date);
  if (e.type == SaleType.doubleDay) return '${day.day}.${day.month}';
  return e.name.length <= 8 ? e.name : '${day.day}/${day.month}';
}

/// 389000 → "389k", 1250000 → "1,25tr"
String _axisVnd(double v) {
  if (v >= 1e6) {
    final s = (v / 1e6).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '${s.replaceAll('.', ',')}tr';
  }
  return '${(v / 1000).round()}k';
}

/// Name of the sale on Vietnamese date [day], if any
String? _saleOn(DateTime day, List<SaleEvent> events) =>
    events.where((e) => vnDate(e.date) == day).firstOrNull?.name;

/// A price drawn on a day: recorded that day, or [held] from an earlier day
class FilledPrice {
  final int vnd;

  /// Index of the day the price was recorded; the day itself when not [held]
  final int sourceIndex;
  final bool held;

  const FilledPrice(this.vnd, this.sourceIndex, {this.held = false});
}

/// A day without a price keeps the latest earlier regular price for at most [maxDays]
/// days (a held day); later days stay null so the line breaks. A sale or Flash Sale
/// price ([DailyPricePoint.hasSale]) is drawn on its own day only: the days after it
/// keep the latest regular price instead, so a one-day sale never turns into a week
/// of low prices. Nothing comes from before the first of [points]: the line never
/// reaches across the start of the period.
List<FilledPrice?> fillForward(
  List<DailyPricePoint> points, {
  int maxDays = PriceHistoryChart.maxHeldDays,
}) {
  final filled = <FilledPrice?>[];
  FilledPrice? keep;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    if (p.minVnd case final vnd?) {
      filled.add(FilledPrice(vnd, i));
      if (!p.hasSale) keep = FilledPrice(vnd, i);
    } else if (keep != null && i - keep.sourceIndex <= maxDays) {
      filled.add(FilledPrice(keep.vnd, keep.sourceIndex, held: true));
    } else {
      filled.add(null);
    }
  }
  return filled;
}

/// Spots of a step line where day i is flat from i - 0.5 to i + 0.5 (its column):
/// only the recorded days, or only the [held] ones, each run ended by a null spot.
/// The rise from a held price to the next recorded one belongs to the recorded run.
List<FlSpot> stepSpots(List<FilledPrice?> filled, {bool held = false}) {
  final spots = <FlSpot>[];
  var open = false;
  for (var i = 0; i < filled.length; i++) {
    final f = filled[i];
    if (f == null || f.held != held) {
      if (open) spots.add(FlSpot.nullSpot);
      open = false;
      continue;
    }
    final y = f.vnd.toDouble();
    if (open && spots.last.y == y) {
      // Same price as the day before: stretch the flat part
      spots[spots.length - 1] = FlSpot(i + 0.5, y);
      continue;
    }
    final before = i > 0 ? filled[i - 1] : null;
    if (!open && !held && before != null && before.held) {
      spots.add(FlSpot(i - 0.5, before.vnd.toDouble()));
    }
    spots
      ..add(FlSpot(i - 0.5, y))
      ..add(FlSpot(i + 0.5, y));
    open = true;
  }
  return spots;
}

/// [spots] of a step line ([stepSpots], the band edges) with each rise or fall (two
/// spots on the same x) drawn as an S-curve (smoothstep, flat at both ends) from
/// [halfWidth] columns before that x to [halfWidth] after it, in [samples] segments,
/// so the line looks smooth. Everything else is kept: the flat parts, the ends of each
/// run and the breaks (null spots). With [halfWidth] below 0.5 every day stays flat
/// around the middle of its column, where its dot and the day touched are.
List<FlSpot> smoothSteps(
  List<FlSpot> spots, {
  double halfWidth = 0.4,
  int samples = 8,
}) {
  final smooth = <FlSpot>[];
  var k = 0;
  while (k < spots.length) {
    final a = spots[k];
    final b = spots.elementAtOrNull(k + 1);
    if (a.isNull() || b == null || b.isNull() || a.x != b.x || a.y == b.y) {
      smooth.add(a);
      k++;
      continue;
    }
    for (var s = 0; s <= samples; s++) {
      final t = s / samples;
      final eased = t * t * (3 - 2 * t);
      smooth.add(
        FlSpot(a.x - halfWidth + 2 * halfWidth * t, a.y + (b.y - a.y) * eased),
      );
    }
    k += 2;
  }
  return smooth;
}

/// Y axis for prices [low]–[high]: 10% padding on both sides and a round step
/// (1, 2 or 5 × 10^k đồng, such as 50.000 or 100.000) giving at most [maxTicks] labels
({double minY, double maxY, double step}) priceAxis(
  int low,
  int high, {
  int maxTicks = 5,
}) {
  final spread = (high - low).toDouble();
  // A flat line sits in the middle, 5% of the price above and below
  final pad = spread > 0 ? spread * 0.1 : math.max(high * 0.05, 1000.0);
  final minY = math.max(0.0, low - pad);
  final maxY = high + pad;
  int ticks(double step) => (maxY / step).floor() - (minY / step).ceil() + 1;
  var step = 1000.0;
  for (var k = 0; ticks(step) > maxTicks; k++) {
    // 1 → 2 → 5 → 10 → 20 → 50 …
    step *= const [2.0, 2.5, 2.0][k % 3];
  }
  return (minY: minY, maxY: maxY, step: step);
}

/// Days written under the chart, at most [maxLabels]: the first and last day, the
/// sale days, then the days the lowest price moved the most (on the day that price
/// was recorded). Labels stay at least [minGap] days apart (default: a sixth of the
/// period, at least 2) so they never overlap on a phone.
Set<int> axisDayIndices(
  List<BandDay> band,
  List<SaleEvent> saleEvents, {
  int maxLabels = 5,
  int? minGap,
}) {
  final n = band.length;
  if (n == 0) return {};
  final gap = minGap ?? math.max(2, (n / 6).ceil());
  // (day, priority): higher first
  final candidates = <(int, double)>[(n - 1, double.infinity), (0, 1e12)];
  for (final e in saleEvents) {
    final i = band.indexWhere((b) => b.day == vnDate(e.date));
    if (i >= 0) candidates.add((i, 1e11));
  }
  for (var i = 1; i < n; i++) {
    final b = band[i];
    if (!b.isRecorded || (b.lowFrom ?? i) != i) continue;
    if (band[i - 1].lowVnd case final before? when b.lowVnd != before) {
      candidates.add((i, (b.lowVnd! - before).abs().toDouble()));
    }
  }
  candidates.sort((a, b) => b.$2.compareTo(a.$2));
  final chosen = <int>{};
  for (final (i, _) in candidates) {
    if (chosen.length >= maxLabels) break;
    if (chosen.every((c) => (c - i).abs() >= gap)) chosen.add(i);
  }
  return chosen;
}

/// A day of the price band
class BandDay {
  /// Vietnamese date (UTC fields)
  final DateTime day;

  /// Lowest and highest list price (null: no band that day) and their shops
  final int? lowVnd;
  final String? lowShop;
  final int? highVnd;
  final String? highShop;

  /// Index of the day [lowVnd] / [highVnd] were recorded (this day, or earlier when
  /// the shop's price is kept); null means this day
  final int? lowFrom;
  final int? highFrom;

  /// Shops in the band: a new price this day or one kept from the last 7 days
  final int shopCount;

  /// No shop has a new price this day: every price is kept from before
  final bool isCarried;

  /// Index of the most recent day a price of the band was recorded; null without a
  /// band
  final int? sourceIndex;

  const BandDay({
    required this.day,
    this.lowVnd,
    this.lowShop,
    this.highVnd,
    this.highShop,
    this.lowFrom,
    this.highFrom,
    this.shopCount = 0,
    this.isCarried = false,
    this.sourceIndex,
  });

  /// At least one new price this day
  bool get isRecorded => lowVnd != null && !isCarried;
}

/// The band of each day from [pointsByShop] ([aggregateDaily] of each shop over the
/// same days). Each shop keeps its latest price for at most [maxCarryDays] days
/// ([fillForward], never before the start), so a shop that did not report today still
/// counts with its recent price and the band does not jump. Several shops: from the
/// lowest to the highest shop price (each shop's minVnd; on a tie the more recent
/// price, then the earlier shop). One shop (a single product): from the lowest to the
/// highest kept report. A day is [BandDay.isCarried] when no shop has a new price.
/// [shopNames]: names for points without one. List prices only: afterVoucher never
/// enters.
List<BandDay> computeBand(
  Map<String, List<DailyPricePoint>> pointsByShop, {
  Map<String, String> shopNames = const {},
  int maxCarryDays = PriceHistoryChart.maxHeldDays,
}) {
  final length = pointsByShop.values.fold(0, (n, p) => math.max(n, p.length));
  final single = pointsByShop.length == 1;
  DateTime dayOf(int i) =>
      pointsByShop.values.firstWhere((p) => i < p.length)[i].day;
  final filled = {
    for (final MapEntry(:key, :value) in pointsByShop.entries)
      key: fillForward(value, maxDays: maxCarryDays),
  };

  BandDay at(int i) {
    // (price, recorded on, shop name, point of that day) of each shop in the band
    final picks = [
      for (final MapEntry(:key, :value) in filled.entries)
        if (value.elementAtOrNull(i) case final f?)
          (
            f.vnd,
            f.sourceIndex,
            pointsByShop[key]![f.sourceIndex].shopName ?? shopNames[key],
            pointsByShop[key]![f.sourceIndex],
          ),
    ];
    if (picks.isEmpty) return BandDay(day: dayOf(i));
    final newest = picks.map((p) => p.$2).reduce(math.max);
    if (single) {
      final (low, from, shop, p) = picks.single;
      return BandDay(
        day: dayOf(i),
        lowVnd: low,
        lowShop: shop,
        highVnd: p.maxVnd ?? low,
        highShop: shop,
        lowFrom: from,
        highFrom: from,
        shopCount: 1,
        isCarried: from != i,
        sourceIndex: newest,
      );
    }
    var low = picks.first, high = picks.first;
    for (final p in picks.skip(1)) {
      if (p.$1 < low.$1 || (p.$1 == low.$1 && p.$2 > low.$2)) low = p;
      if (p.$1 > high.$1 || (p.$1 == high.$1 && p.$2 > high.$2)) high = p;
    }
    return BandDay(
      day: dayOf(i),
      lowVnd: low.$1,
      lowShop: low.$3,
      highVnd: high.$1,
      highShop: high.$3,
      lowFrom: low.$2,
      highFrom: high.$2,
      shopCount: picks.length,
      isCarried: newest != i,
      sourceIndex: newest,
    );
  }

  return [for (var i = 0; i < length; i++) at(i)];
}

/// [computeBand] of a view: shop names from the products, else from the reports
List<BandDay> bandOf(PriceHistoryView view) => computeBand(
  view.points,
  shopNames: {
    for (final MapEntry(:key, :value) in view.points.entries)
      key: ?switch (view.products[key]?.shopName) {
        final name? when name.isNotEmpty => name,
        _ => value.reversed.map((p) => p.shopName).nonNulls.firstOrNull,
      },
  },
);

/// Rows of the milestone list
enum PriceMilestoneKind {
  lowest('Thấp nhất', Icons.south_rounded),
  highest('Cao nhất', Icons.north_rounded),
  saved('Lúc bạn lưu', Icons.bookmark_border_rounded),
  latest('Hiện tại thấp nhất', Icons.schedule_rounded);

  final String label;
  final IconData icon;

  const PriceMilestoneKind(this.label, this.icon);
}

/// A price worth remembering in the period, with its day, shop and sale
class PriceMilestone {
  final PriceMilestoneKind kind;
  final int vnd;

  /// Vietnamese date (UTC fields)
  final DateTime day;

  /// "Hôm nay", "Hôm qua", "dd/MM" (or "dd/MM/yyyy" another year)
  final String dayLabel;

  /// Index in the band; null when the day is outside the period
  final int? dayIndex;
  final String? shop;
  final String? saleName;

  const PriceMilestone({
    required this.kind,
    required this.vnd,
    required this.day,
    required this.dayLabel,
    this.dayIndex,
    this.shop,
    this.saleName,
  });

  /// "11/11 · Shop A · 11.11"
  String get detail => [dayLabel, ?shop, ?saleName].join(' · ');
}

/// At most 4 rows, in this order: "Thấp nhất", "Cao nhất" (days with a new price only,
/// each price dated the day it was recorded, ties to the most recent one), "Lúc bạn
/// lưu" (when [savedPrice] is given) and "Hiện tại thấp nhất" (the lowest price of the
/// most recent day with a new price, dated the day it was recorded). Facts only.
List<PriceMilestone> buildPriceMilestones(
  List<BandDay> band,
  SavedPrice? savedPrice,
  List<SaleEvent> saleEvents,
  DateTime now,
) {
  final today = vnDate(now);
  String label(DateTime day) {
    if (day == today) return 'Hôm nay';
    if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return day.year == today.year ? formatDayMonth(day) : formatDate(day);
  }

  PriceMilestone row(
    PriceMilestoneKind kind,
    int vnd,
    DateTime day,
    int? i, [
    String? shop,
  ]) => PriceMilestone(
    kind: kind,
    vnd: vnd,
    day: day,
    dayLabel: label(day),
    dayIndex: i,
    shop: shop,
    saleName: _saleOn(day, saleEvents),
  );

  // (price, index of the day it was recorded, shop)
  (int, int, String?)? lowest, highest, latest;
  for (var i = 0; i < band.length; i++) {
    final b = band[i];
    if (!b.isRecorded) continue;
    final low = (b.lowVnd!, b.lowFrom ?? i, b.lowShop);
    final high = (b.highVnd!, b.highFrom ?? i, b.highShop);
    if (lowest == null ||
        low.$1 < lowest.$1 ||
        (low.$1 == lowest.$1 && low.$2 >= lowest.$2)) {
      lowest = low;
    }
    if (highest == null ||
        high.$1 > highest.$1 ||
        (high.$1 == highest.$1 && high.$2 >= highest.$2)) {
      highest = high;
    }
    latest = low;
  }
  final savedDay = savedPrice == null ? null : vnDate(savedPrice.savedAt);
  final savedIndex = band.indexWhere((b) => b.day == savedDay);
  return [
    if (lowest case (final vnd, final i, final shop))
      row(PriceMilestoneKind.lowest, vnd, band[i].day, i, shop),
    if (highest case (final vnd, final i, final shop))
      row(PriceMilestoneKind.highest, vnd, band[i].day, i, shop),
    if ((savedPrice, savedDay) case (final saved?, final day?))
      row(
        PriceMilestoneKind.saved,
        saved.vnd,
        day,
        savedIndex < 0 ? null : savedIndex,
      ),
    if (latest case (final vnd, final i, final shop))
      row(PriceMilestoneKind.latest, vnd, band[i].day, i, shop),
  ];
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedDay;
  }

  @override
  void didUpdateWidget(PriceHistoryChart old) {
    super.didUpdateWidget(old);
    if (old.initialSelectedDay != widget.initialSelectedDay) {
      _selected = widget.initialSelectedDay;
    } else if (old.view.days.length != widget.view.days.length) {
      _selected = null;
    }
  }

  PriceHistoryView get _view => widget.view;

  void _select(int i) {
    if (i != _selected) setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTextStyles.labelMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final band = bandOf(_view);
    final milestones = buildPriceMilestones(
      band,
      widget.savedPrice,
      _view.saleEvents,
      // The last day of the period is today
      _view.days.isEmpty ? DateTime.now() : _view.days.last,
    );
    final recordedDays = band.where((b) => b.isRecorded).length;
    final drawn = recordedDays >= PriceHistoryChart.minChartDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wrap: the badge and the range buttons share a line when they fit
        Wrap(
          alignment: _view.isDemo
              ? WrapAlignment.spaceBetween
              : WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          children: [
            if (_view.isDemo) const DemoDataBadge(),
            SegmentedButton<PriceHistoryRange>(
              key: const ValueKey('price-range'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final r in PriceHistoryRange.values)
                  ButtonSegment(
                    value: r,
                    label: Text(_rangeLabels[r]!),
                    tooltip: r.label,
                  ),
              ],
              selected: {_view.range},
              onSelectionChanged: widget.onRangeChanged == null
                  ? null
                  : (s) => widget.onRangeChanged!(s.single),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        if (drawn)
          _card(theme, band, milestones, muted)
        else
          Text(
            'Chưa đủ dữ liệu để vẽ biểu đồ ($recordedDays ngày có giá)',
            key: const ValueKey('price-too-few'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (_selected case final i? when i < band.length) ...[
          const SizedBox(height: AppDimens.space8),
          _DayDetails(lines: describeDay(_view, band, i)),
        ],
        const SizedBox(height: AppDimens.space12),
        _Milestones(milestones: milestones, onTap: _select),
      ],
    );
  }

  /// The chart in a rounded card: what the band means on top, the plot, then the
  /// first and last day and the days the price moved under it
  Widget _card(
    ThemeData theme,
    List<BandDay> band,
    List<PriceMilestone> milestones,
    TextStyle muted,
  ) {
    final days = _view.days;
    // Dates under the plot: first, last, sales and the days the price moved
    final labelDays = axisDayIndices(band, _view.saleEvents).toList()..sort();
    return Container(
      key: const ValueKey('price-chart-card'),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space12,
        AppDimens.space12,
        AppDimens.space12,
        AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.caption ??
                (_view.isGroup
                    ? 'Vùng tô: từ giá thấp nhất tới cao nhất giữa các shop mỗi ngày'
                    : 'Vùng tô: từ giá thấp nhất tới cao nhất ghi được mỗi ngày'),
            key: const ValueKey('price-chart-caption'),
            textAlign: TextAlign.center,
            style: muted,
          ),
          if (widget.ownPrices.isNotEmpty)
            Row(
              key: const ValueKey('price-chart-own-legend'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 12,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppDimens.space4),
                Text('Giá bạn ghi', style: muted),
              ],
            ),
          const SizedBox(height: AppDimens.space8),
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, box) => _touchArea(
                box,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: widget.chartHeight,
                      child: _chart(theme, band, milestones, muted),
                    ),
                    Padding(
                      key: const ValueKey('price-chart-dates'),
                      padding: const EdgeInsets.only(top: AppDimens.space6),
                      child: Stack(
                        children: [
                          for (final i in labelDays)
                            Align(
                              // Under its day; the first and last at the edges
                              alignment: Alignment(
                                i == 0
                                    ? -1
                                    : i == days.length - 1
                                    ? 1
                                    : (i + 0.5) / days.length * 2 - 1,
                                0,
                              ),
                              child: Text(formatDayMonth(days[i]), style: muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The whole height of a day's column, dates included, selects that day; dragging
  /// sideways moves along the days
  Widget _touchArea(BoxConstraints box, Widget chart) {
    final n = _view.days.length;
    void select(Offset p) {
      if (n == 0 || box.maxWidth <= 0) return;
      _select((p.dx / box.maxWidth * n).floor().clamp(0, n - 1));
    }

    return GestureDetector(
      key: const ValueKey('price-chart-touch'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => select(d.localPosition),
      onHorizontalDragStart: (d) => select(d.localPosition),
      onHorizontalDragUpdate: (d) => select(d.localPosition),
      child: chart,
    );
  }

  Widget _chart(
    ThemeData theme,
    List<BandDay> band,
    List<PriceMilestone> milestones,
    TextStyle muted,
  ) {
    final days = _view.days;
    final saved = widget.savedPrice;
    final own = widget.ownPrices.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final values = [
      for (final b in band) ...[?b.lowVnd, ?b.highVnd],
      ?saved?.vnd,
      for (final e in own) e.value,
    ];
    if (values.isEmpty || days.isEmpty) return const SizedBox.shrink();
    final axis = priceAxis(values.reduce(math.min), values.reduce(math.max));
    final line = priceLineColor(theme);
    final low = [
      for (final b in band)
        if (b.lowVnd case final vnd?)
          FilledPrice(vnd, b.sourceIndex!, held: b.isCarried)
        else
          null,
    ];
    final sales = {
      for (final e in _view.saleEvents)
        if (days.indexOf(vnDate(e.date)) case final i when i >= 0) i: e,
    };

    // Invisible edges of the band, filled in between
    LineChartBarData edge(int? Function(BandDay) value) => LineChartBarData(
      spots: smoothSteps(_bandSpots(band, value)),
      barWidth: 0,
      color: Colors.transparent,
      dotData: const FlDotData(show: false),
    );
    // One dot: the lowest point, with its price in short
    final marks = <(FlSpot, PriceDotPainter)>[
      for (final m in milestones)
        if (m.dayIndex case final i? when m.kind == PriceMilestoneKind.lowest)
          (
            FlSpot(i.toDouble(), m.vnd.toDouble()),
            PriceDotPainter(
              color: lowestDotColor(theme),
              ringColor: theme.colorScheme.surface,
              radius: 4,
              label: _axisVnd(m.vnd.toDouble()),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              // Kept inside the plot near the right edge
              labelOnLeft: i > days.length * 0.8,
            ),
          ),
    ];
    final bars = <LineChartBarData>[
      edge((b) => b.lowVnd),
      edge((b) => b.highVnd),
      if (stepSpots(low, held: true) case final spots when spots.isNotEmpty)
        LineChartBarData(
          spots: smoothSteps(spots),
          color: line.withValues(alpha: 0.45),
          barWidth: 1.5,
          isStrokeJoinRound: true,
          dashArray: _heldDash,
          dotData: const FlDotData(show: false),
        ),
      LineChartBarData(
        spots: smoothSteps(stepSpots(low)),
        color: line,
        barWidth: 2.5,
        isStrokeJoinRound: true,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
      ),
      // "Giá bạn ghi": small hollow dots, never joined
      if (own.isNotEmpty)
        LineChartBarData(
          spots: [
            for (final e in own) FlSpot(e.key.toDouble(), e.value.toDouble()),
          ],
          barWidth: 0,
          color: Colors.transparent,
          dotData: FlDotData(
            getDotPainter: (_, _, _, _) => PriceDotPainter(
              color: theme.colorScheme.onSurface,
              ringColor: theme.colorScheme.surface,
              radius: 3,
              hollow: true,
            ),
          ),
        ),
      if (marks.isNotEmpty)
        LineChartBarData(
          spots: [for (final m in marks) m.$1],
          barWidth: 0,
          color: Colors.transparent,
          dotData: FlDotData(
            getDotPainter: (_, _, _, index) => marks[index].$2,
          ),
        ),
    ];

    return LineChart(
      LineChartData(
        // Day i is the column i - 0.5 … i + 0.5
        minX: -0.5,
        maxX: days.length - 0.5,
        minY: axis.minY,
        maxY: axis.maxY,
        lineBarsData: bars,
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 0,
            toIndex: 1,
            color: line.withValues(alpha: 0.2),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            // Sale days; their names are written above the plot
            for (final i in sales.keys)
              VerticalLine(
                x: i.toDouble(),
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                strokeWidth: 1,
                dashArray: [3, 3],
              ),
            if (_selected case final i?)
              VerticalLine(
                x: i.toDouble(),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                strokeWidth: 1,
              ),
          ],
          horizontalLines: [
            if (saved != null)
              HorizontalLine(
                y: saved.vnd.toDouble(),
                color: theme.colorScheme.onSurfaceVariant,
                strokeWidth: 1,
                dashArray: _savedDash,
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 2, bottom: 2),
                  style: muted,
                  labelResolver: (_) => 'giá lúc bạn lưu',
                ),
              ),
          ],
        ),
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: [
            if (_selected case final i?)
              VerticalRangeAnnotation(
                x1: i - 0.5,
                x2: i + 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
          ],
        ),
        // No price axis and no grid: prices are on the dot, the lines and below
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          topTitles: sales.isEmpty
              ? const AxisTitles()
              : AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _saleLabelHeight,
                    interval: 1,
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (v, meta) => switch (sales[v.round()]) {
                      final e? when v == v.roundToDouble() => SideTitleWidget(
                        meta: meta,
                        space: 2,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(
                          meta,
                          distanceFromEdge: 0,
                        ),
                        child: Text(saleShortLabel(e), style: muted),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
        ),
        // Touches are handled by [_touchArea], over whole columns
        lineTouchData: const LineTouchData(enabled: false),
      ),
      duration: Duration.zero,
    );
  }
}

/// Step spots of one edge of the band, carried days included; the low and high edges
/// break on the same days, as [BetweenBarsData] needs
List<FlSpot> _bandSpots(List<BandDay> band, int? Function(BandDay) value) {
  final spots = <FlSpot>[];
  var open = false;
  for (var i = 0; i < band.length; i++) {
    final v = value(band[i]);
    if (v == null) {
      if (open) spots.add(FlSpot.nullSpot);
      open = false;
      continue;
    }
    final y = v.toDouble();
    if (open && spots.last.y == y) {
      spots[spots.length - 1] = FlSpot(i + 0.5, y);
      continue;
    }
    spots
      ..add(FlSpot(i - 0.5, y))
      ..add(FlSpot(i + 0.5, y));
    open = true;
  }
  return spots;
}

/// A chart dot: filled, or [hollow], on a ring of the surface color so it stands out
/// from the line; [label] is written beside it, on a faint surface-colored patch so
/// the line under it does not cross the text
class PriceDotPainter extends FlDotPainter {
  final Color color;
  final Color ringColor;
  final double radius;
  final bool hollow;
  final String? label;
  final TextStyle? labelStyle;

  /// The label on the left of the dot (near the right edge of the plot)
  final bool labelOnLeft;

  const PriceDotPainter({
    required this.color,
    required this.ringColor,
    this.radius = 3.5,
    this.hollow = false,
    this.label,
    this.labelStyle,
    this.labelOnLeft = false,
  });

  static const double _ring = 1.5;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawCircle(
      offsetInCanvas,
      radius + _ring,
      Paint()..color = ringColor,
    );
    canvas.drawCircle(
      offsetInCanvas,
      hollow ? radius - 0.75 : radius,
      Paint()
        ..color = color
        ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1.5,
    );
    if (label case final text?) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      const gap = 4.0;
      final topLeft = Offset(
        labelOnLeft
            ? offsetInCanvas.dx - radius - _ring - gap - painter.width
            : offsetInCanvas.dx + radius + _ring + gap,
        offsetInCanvas.dy - painter.height / 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (topLeft & painter.size).inflate(2),
          const Radius.circular(3),
        ),
        Paint()..color = ringColor.withValues(alpha: 0.85),
      );
      painter
        ..paint(canvas, topLeft)
        ..dispose();
    }
  }

  @override
  Size getSize(FlSpot spot) => Size.fromRadius(radius + _ring);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  List<Object?> get props => [
    color,
    ringColor,
    radius,
    hollow,
    label,
    labelStyle,
    labelOnLeft,
  ];
}

/// One line of the day details: [muted] for the after-voucher reference,
/// [tag] for the sale's name
class DayDetailLine {
  final String text;
  final bool muted;
  final bool tag;

  const DayDetailLine(this.text, {this.muted = false, this.tag = false});
}

/// Details of day [i]: date; lowest price and shop; highest price and shop when it
/// differs; how many shops are in the band (reports for a single product); for a
/// carried day the most recent day a price was recorded; the sale of that day; the
/// after-voucher price as a faint reference line. A price kept from another day than
/// the one the details speak of says when it was recorded.
List<DayDetailLine> describeDay(
  PriceHistoryView view,
  List<BandDay> band,
  int i,
) {
  final b = band[i];
  final points = [
    for (final p in view.points.values)
      if (i < p.length) p[i],
  ];
  final reports = points.fold(0, (n, p) => n + p.reportCount);
  final vouchers = [for (final p in points) ?p.afterVoucherMinVnd];
  String at(String? shop) => shop == null ? '' : ' · $shop';

  // The day the details speak of: this one, or the last day with a new price
  final ref = b.isCarried ? b.sourceIndex! : i;
  String from(int? recorded) => recorded == null || recorded == ref
      ? ''
      : ' · ghi ngày ${formatDayMonth(band[recorded].day)}';

  final lines = <DayDetailLine>[DayDetailLine(formatDate(b.day))];
  if (b.lowVnd case final low?) {
    lines.add(
      DayDetailLine(
        'Thấp nhất: ${formatVnd(low)}${at(b.lowShop)}${from(b.lowFrom)}',
      ),
    );
    if (b.highVnd case final high? when high != low) {
      lines.add(
        DayDetailLine(
          'Cao nhất: ${formatVnd(high)}${at(b.highShop)}${from(b.highFrom)}',
        ),
      );
    }
    if (view.isGroup) {
      lines.add(DayDetailLine('${b.shopCount} shop có giá'));
    } else if (!b.isCarried) {
      lines.add(DayDetailLine('$reports báo cáo'));
    }
    if (b.isCarried) {
      lines.add(
        DayDetailLine(
          'Chưa có giá mới · giá ghi ngày ${formatDayMonth(band[ref].day)}',
        ),
      );
      if (reports > 0) {
        lines.add(DayDetailLine('Chưa đủ dữ liệu ($reports báo cáo)'));
      }
    }
  } else if (reports > 0) {
    lines.add(DayDetailLine('Chưa đủ dữ liệu ($reports báo cáo)'));
  } else {
    lines.add(const DayDetailLine('Chưa có báo cáo'));
  }
  if (_saleOn(b.day, view.saleEvents) case final sale?) {
    lines.add(DayDetailLine(sale, tag: true));
  }
  if (vouchers.isNotEmpty) {
    lines.add(
      DayDetailLine(
        'Sau voucher (tham khảo): ${formatVnd(vouchers.reduce(math.min))}',
        muted: true,
      ),
    );
  }
  return lines;
}

/// The milestones under the chart: icon, label, day · shop · sale, price on the right.
/// Tapping a row inside the period marks that day.
class _Milestones extends StatelessWidget {
  final List<PriceMilestone> milestones;
  final ValueChanged<int> onTap;

  const _Milestones({required this.milestones, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = AppTextStyles.labelMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      key: const ValueKey('price-milestones'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in milestones)
          InkWell(
            key: ValueKey('price-milestone-${m.kind.name}'),
            borderRadius: AppDimens.borderSmall,
            onTap: m.dayIndex == null ? null : () => onTap(m.dayIndex!),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.space8,
                horizontal: AppDimens.space4,
              ),
              child: Row(
                children: [
                  Icon(m.kind.icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.kind.label, style: AppTextStyles.labelLarge),
                        Text(m.detail, style: muted),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Text(
                    formatVnd(m.vnd),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DayDetails extends StatelessWidget {
  final List<DayDetailLine> lines;

  const _DayDetails({required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('price-day-details'),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Semantics(
        liveRegion: true,
        child: Wrap(
          direction: Axis.vertical,
          spacing: AppDimens.space4,
          children: [
            for (final (k, line) in lines.indexed)
              if (line.tag)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: AppDimens.borderSmall,
                  ),
                  child: Text(line.text, style: AppTextStyles.labelMedium),
                )
              else
                Text(
                  line.text,
                  style:
                      (k == 0
                              ? AppTextStyles.labelLarge
                              : AppTextStyles.bodyMedium)
                          .copyWith(
                            color: line.muted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                ),
          ],
        ),
      ),
    );
  }
}
