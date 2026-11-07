import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/daily_price.dart';
import '../models/sale_event.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_viewmodel.dart';
import 'demo_data_badge.dart';

/// "Biểu đồ giá tham khảo" (SteamDB style): a light band from the lowest to the highest
/// price of each day (between the shops of a group, between the reports of one
/// product) and ONE step line of the lowest price, each day flat across its own column.
/// A day without a new price keeps the latest ones for at most [maxHeldDays] days, the
/// line dashed and fainter; after that the chart breaks. A dashed horizontal line
/// marks "Giá lúc bạn lưu" when given. Dots only on the lowest point (with its price)
/// and the latest one; sale days are faint vertical lines. Under the chart: the day
/// touched (or picked in the list) and the price milestones of the period. Below
/// [minChartDays] days with a price, only the milestones are shown.
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
  final double chartHeight;

  const PriceHistoryChart({
    super.key,
    required this.view,
    this.onRangeChanged,
    this.savedPrice,
    this.initialSelectedDay,
    this.chartHeight = 220,
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

/// Width of the price labels on the left; the plot starts there
const double _leftAxisWidth = 44;
const double _bottomAxisHeight = 24;

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

/// A day without a price keeps the latest earlier one for at most [maxDays] days (a
/// held day); later days stay null so the line breaks. Nothing comes from before the
/// first of [points]: the line never reaches across the start of the period.
List<FilledPrice?> fillForward(
  List<DailyPricePoint> points, {
  int maxDays = PriceHistoryChart.maxHeldDays,
}) {
  final filled = <FilledPrice?>[];
  FilledPrice? last;
  for (var i = 0; i < points.length; i++) {
    if (points[i].minVnd case final vnd?) {
      last = FilledPrice(vnd, i);
      filled.add(last);
    } else if (last != null && i - last.sourceIndex <= maxDays) {
      filled.add(FilledPrice(last.vnd, last.sourceIndex, held: true));
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

/// A day of the price band
class BandDay {
  /// Vietnamese date (UTC fields)
  final DateTime day;

  /// Lowest and highest list price (null: no band that day) and their shops
  final int? lowVnd;
  final String? lowShop;
  final int? highVnd;
  final String? highShop;

  /// Shops with a list price on the day the prices were recorded
  final int shopCount;

  /// No new price this day: the band of day [sourceIndex] is kept
  final bool isCarried;

  /// Index of the day the prices were recorded; null without a band
  final int? sourceIndex;

  const BandDay({
    required this.day,
    this.lowVnd,
    this.lowShop,
    this.highVnd,
    this.highShop,
    this.shopCount = 0,
    this.isCarried = false,
    this.sourceIndex,
  });

  /// A band recorded this day (not carried)
  bool get isRecorded => lowVnd != null && !isCarried;

  BandDay _carriedTo(DateTime other, int source) => BandDay(
    day: other,
    lowVnd: lowVnd,
    lowShop: lowShop,
    highVnd: highVnd,
    highShop: highShop,
    shopCount: shopCount,
    isCarried: true,
    sourceIndex: source,
  );
}

/// The band of each day from [pointsByShop] ([aggregateDaily] of each shop over the
/// same days). Several shops: from the lowest to the highest shop price (each shop's
/// minVnd, ties to the earlier shop). One shop (a single product): from the lowest to
/// the highest kept report. A day without any price keeps the latest band for at most
/// [maxCarryDays] days ([fillForward]), then has none. [shopNames]: names for points
/// without one. List prices only: afterVoucher never enters.
List<BandDay> computeBand(
  Map<String, List<DailyPricePoint>> pointsByShop, {
  Map<String, String> shopNames = const {},
  int maxCarryDays = PriceHistoryChart.maxHeldDays,
}) {
  final length = pointsByShop.values.fold(0, (n, p) => math.max(n, p.length));
  final single = pointsByShop.length == 1;
  DateTime dayOf(int i) =>
      pointsByShop.values.firstWhere((p) => i < p.length)[i].day;

  BandDay recorded(int i) {
    final picks = [
      for (final MapEntry(:key, :value) in pointsByShop.entries)
        if (value.elementAtOrNull(i) case final p? when p.minVnd != null)
          (p.minVnd!, p.shopName ?? shopNames[key], p),
    ];
    if (picks.isEmpty) return BandDay(day: dayOf(i));
    if (single) {
      final (low, shop, p) = picks.single;
      return BandDay(
        day: p.day,
        lowVnd: low,
        lowShop: shop,
        highVnd: p.maxVnd ?? low,
        highShop: shop,
        shopCount: 1,
        sourceIndex: i,
      );
    }
    var low = picks.first, high = picks.first;
    for (final p in picks.skip(1)) {
      if (p.$1 < low.$1) low = p;
      if (p.$1 > high.$1) high = p;
    }
    return BandDay(
      day: low.$3.day,
      lowVnd: low.$1,
      lowShop: low.$2,
      highVnd: high.$1,
      highShop: high.$2,
      shopCount: picks.length,
      sourceIndex: i,
    );
  }

  final days = [for (var i = 0; i < length; i++) recorded(i)];
  // Same rule as the line of G5b: at most [maxCarryDays], never before the start
  final filled = fillForward([
    for (final d in days) DailyPricePoint(day: d.day, minVnd: d.lowVnd),
  ], maxDays: maxCarryDays);
  return [
    for (var i = 0; i < length; i++)
      switch (filled[i]) {
        FilledPrice(held: true, :final sourceIndex) =>
          days[sourceIndex]._carriedTo(days[i].day, sourceIndex),
        _ => days[i],
      },
  ];
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

/// At most 4 rows, in this order: "Thấp nhất", "Cao nhất" (days with a recorded price
/// only, ties to the most recent day), "Lúc bạn lưu" (when [savedPrice] is given) and
/// "Hiện tại thấp nhất" (the most recent day with a recorded price). Facts only.
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

  int? lowest, highest, latest;
  for (var i = 0; i < band.length; i++) {
    final b = band[i];
    if (!b.isRecorded) continue;
    if (lowest == null || b.lowVnd! <= band[lowest].lowVnd!) lowest = i;
    if (highest == null || b.highVnd! >= band[highest].highVnd!) highest = i;
    latest = i;
  }
  final savedDay = savedPrice == null ? null : vnDate(savedPrice.savedAt);
  final savedIndex = band.indexWhere((b) => b.day == savedDay);
  return [
    if (lowest case final i?)
      row(
        PriceMilestoneKind.lowest,
        band[i].lowVnd!,
        band[i].day,
        i,
        band[i].lowShop,
      ),
    if (highest case final i?)
      row(
        PriceMilestoneKind.highest,
        band[i].highVnd!,
        band[i].day,
        i,
        band[i].highShop,
      ),
    if ((savedPrice, savedDay) case (final saved?, final day?))
      row(
        PriceMilestoneKind.saved,
        saved.vnd,
        day,
        savedIndex < 0 ? null : savedIndex,
      ),
    if (latest case final i?)
      row(
        PriceMilestoneKind.latest,
        band[i].lowVnd!,
        band[i].day,
        i,
        band[i].lowShop,
      ),
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
    final accent = theme.colorScheme.tertiary;
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
        if (drawn) ...[
          Wrap(
            key: const ValueKey('price-legend'),
            spacing: AppDimens.space16,
            runSpacing: AppDimens.space4,
            children: [
              _LegendItem(
                swatch: _Swatch.line,
                color: accent,
                text: 'Giá thấp nhất',
              ),
              _LegendItem(
                swatch: _Swatch.band,
                color: accent,
                text: _view.isGroup
                    ? 'Khoảng giá các shop'
                    : 'Khoảng giá ghi được',
              ),
              if (widget.savedPrice != null)
                _LegendItem(
                  swatch: _Swatch.dashed,
                  color: theme.colorScheme.onSurfaceVariant,
                  text: 'Giá lúc bạn lưu',
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          ExcludeSemantics(
            child: SizedBox(
              height: widget.chartHeight,
              child: LayoutBuilder(
                builder: (context, box) => _touchArea(
                  box,
                  _chart(theme, band, milestones, accent, muted),
                ),
              ),
            ),
          ),
        ] else
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

  /// The whole height of a day's column selects that day; dragging sideways moves
  /// along the days
  Widget _touchArea(BoxConstraints box, Widget chart) {
    final n = _view.days.length;
    void select(Offset p) {
      final plot = box.maxWidth - _leftAxisWidth;
      if (n == 0 || plot <= 0) return;
      _select(((p.dx - _leftAxisWidth) / plot * n).floor().clamp(0, n - 1));
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
    Color accent,
    TextStyle muted,
  ) {
    final days = _view.days;
    final saved = widget.savedPrice;
    final values = [
      for (final b in band) ...[?b.lowVnd, ?b.highVnd],
      ?saved?.vnd,
    ];
    if (values.isEmpty || days.isEmpty) return const SizedBox.shrink();
    final axis = priceAxis(values.reduce(math.min), values.reduce(math.max));
    final step = math.max(1, (days.length / 5).ceil());
    final low = [
      for (final b in band)
        if (b.lowVnd case final vnd?)
          FilledPrice(vnd, b.sourceIndex!, held: b.isCarried)
        else
          null,
    ];

    // Invisible edges of the band, filled in between
    LineChartBarData edge(int? Function(BandDay) value) => LineChartBarData(
      spots: _bandSpots(band, value),
      barWidth: 0,
      color: Colors.transparent,
      dotData: const FlDotData(show: false),
    );
    final marks = <(FlSpot, PriceDotPainter)>[
      for (final m in milestones)
        if (m.dayIndex case final i?
            when m.kind == PriceMilestoneKind.latest ||
                m.kind == PriceMilestoneKind.lowest)
          (
            FlSpot(i.toDouble(), m.vnd.toDouble()),
            PriceDotPainter(
              color: accent,
              ringColor: theme.colorScheme.surface,
              label: m.kind == PriceMilestoneKind.lowest
                  ? formatVnd(m.vnd)
                  : null,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface,
              ),
              // Kept inside the plot near its edges
              labelAlign: i < days.length * 0.2
                  ? -1
                  : i > days.length * 0.8
                  ? 1
                  : 0,
            ),
          ),
    ];
    final bars = <LineChartBarData>[
      edge((b) => b.lowVnd),
      edge((b) => b.highVnd),
      if (stepSpots(low, held: true) case final spots when spots.isNotEmpty)
        LineChartBarData(
          spots: spots,
          color: accent.withValues(alpha: 0.45),
          barWidth: 1.5,
          dashArray: _heldDash,
          dotData: const FlDotData(show: false),
        ),
      LineChartBarData(
        spots: stepSpots(low),
        color: accent,
        barWidth: 2,
        dotData: const FlDotData(show: false),
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

    final verticalLines = <VerticalLine>[
      for (final e in _view.saleEvents)
        if (days.indexOf(vnDate(e.date)) case final i when i >= 0)
          VerticalLine(
            x: i.toDouble(),
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [3, 3],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(left: 2, top: 0),
              style: muted.copyWith(fontSize: 10),
              labelResolver: (_) => saleShortLabel(e),
            ),
          ),
      if (_selected case final i?)
        VerticalLine(
          x: i.toDouble(),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          strokeWidth: 1,
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
            color: accent.withValues(alpha: 0.16),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: verticalLines,
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
                  style: muted.copyWith(fontSize: 10),
                  labelResolver: (_) => 'Lúc bạn lưu',
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
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: axis.step,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _leftAxisWidth,
              interval: axis.step,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, meta) => Text(_axisVnd(v), style: muted),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomAxisHeight,
              interval: 1,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                final show =
                    v == i &&
                    (i == days.length - 1 || i % step == 0) &&
                    !(i != days.length - 1 && days.length - 1 - i < step / 2);
                return show && i >= 0 && i < days.length
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(formatDayMonth(days[i]), style: muted),
                      )
                    : const SizedBox.shrink();
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
/// from the line; [label] is written small under it
class PriceDotPainter extends FlDotPainter {
  final Color color;
  final Color ringColor;
  final double radius;
  final bool hollow;
  final String? label;
  final TextStyle? labelStyle;

  /// -1: the label starts at the dot, 0: centered, 1: ends at the dot
  final int labelAlign;

  const PriceDotPainter({
    required this.color,
    required this.ringColor,
    this.radius = 3.5,
    this.hollow = false,
    this.label,
    this.labelStyle,
    this.labelAlign = 0,
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
      final left = switch (labelAlign) {
        < 0 => offsetInCanvas.dx - radius,
        > 0 => offsetInCanvas.dx + radius - painter.width,
        _ => offsetInCanvas.dx - painter.width / 2,
      };
      final topLeft = Offset(left, offsetInCanvas.dy + radius + _ring + 2);
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
    labelAlign,
  ];
}

enum _Swatch { line, band, dashed }

class _LegendItem extends StatelessWidget {
  final _Swatch swatch;
  final Color color;
  final String text;

  const _LegendItem({
    required this.swatch,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: _SwatchPainter(swatch, color),
        ),
        const SizedBox(width: AppDimens.space4),
        // Wraps instead of overflowing on narrow screens
        Flexible(child: Text(text, style: AppTextStyles.labelMedium)),
      ],
    );
  }
}

class _SwatchPainter extends CustomPainter {
  final _Swatch swatch;
  final Color color;

  const _SwatchPainter(this.swatch, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = swatch == _Swatch.line ? 2 : 1;
    switch (swatch) {
      case _Swatch.band:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
          Paint()..color = color.withValues(alpha: 0.16),
        );
      case _Swatch.line:
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      case _Swatch.dashed:
        for (var x = 0.0; x < size.width; x += 10) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 6, size.width), y),
            paint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.swatch != swatch || old.color != color;
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
/// differs; how many shops had a price (reports for a single product); for a carried
/// day the day the prices were recorded; the sale of that day; the after-voucher price
/// as a faint reference line
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

  final lines = <DayDetailLine>[DayDetailLine(formatDate(b.day))];
  if (b.lowVnd case final low?) {
    lines.add(DayDetailLine('Thấp nhất: ${formatVnd(low)}${at(b.lowShop)}'));
    if (b.highVnd case final high? when high != low) {
      lines.add(DayDetailLine('Cao nhất: ${formatVnd(high)}${at(b.highShop)}'));
    }
    if (b.isCarried) {
      lines.add(
        DayDetailLine(
          'Chưa có giá mới · giá ghi ngày '
          '${formatDayMonth(band[b.sourceIndex!].day)}',
        ),
      );
      if (reports > 0) {
        lines.add(DayDetailLine('Chưa đủ dữ liệu ($reports báo cáo)'));
      }
    } else {
      lines.add(
        DayDetailLine(
          view.isGroup ? '${b.shopCount} shop có giá' : '$reports báo cáo',
        ),
      );
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
