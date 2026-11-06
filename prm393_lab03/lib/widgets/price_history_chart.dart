import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/formatters/rating_format.dart';
import '../models/daily_price.dart';
import '../models/sale_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_viewmodel.dart';
import 'demo_data_badge.dart';

/// "Biểu đồ giá tham khảo" (SteamDB style): a step line of the day's lowest list price,
/// a dot on each day with data and a gap on days without enough reports. Group mode
/// draws one line per shop (at most [maxShops]), told apart by name, color and dash.
/// Sale days are faint vertical lines. Tapping a day shows its details under the chart;
/// a short text summary follows for people who cannot see the chart.
class PriceHistoryChart extends StatefulWidget {
  static const int maxShops = 4;

  final PriceHistoryView view;
  final ValueChanged<PriceHistoryRange>? onRangeChanged;

  /// Small hollow dots for "sau voucher, tham khảo" prices; never a line
  final bool showAfterVoucherDots;

  /// Day shown in the details panel at first (index in [PriceHistoryView.days])
  final int? initialSelectedDay;
  final double chartHeight;

  const PriceHistoryChart({
    super.key,
    required this.view,
    this.onRangeChanged,
    this.showAfterVoucherDots = false,
    this.initialSelectedDay,
    this.chartHeight = 220,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

/// Short range labels like SteamDB
const _rangeLabels = {
  PriceHistoryRange.week: '7N',
  PriceHistoryRange.month: '30N',
  PriceHistoryRange.quarter: '90N',
};

/// Dash of each shop's line, so lines differ by more than color
const List<List<int>?> _dashes = [
  null,
  [8, 4],
  [2, 3],
  [10, 3, 2, 3],
];

/// Line colors from the theme tokens, readable on both surfaces
List<Color> seriesColors(ThemeData theme) {
  final dark = theme.brightness == Brightness.dark;
  return [
    theme.colorScheme.onSurface,
    dark ? AppColors.infoLight : AppColors.info,
    dark ? AppColors.successLight : AppColors.onSuccessContainer,
    dark ? AppColors.roseLight : AppColors.rose,
  ];
}

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

class _Series {
  final String productKey;
  final String name;
  final List<DailyPricePoint> points;
  final Color color;
  final List<int>? dash;

  const _Series(this.productKey, this.name, this.points, this.color, this.dash);
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

  List<_Series> _series(ThemeData theme) {
    final colors = seriesColors(theme);
    final entries = _view.points.entries
        .take(PriceHistoryChart.maxShops)
        .toList();
    return [
      for (var i = 0; i < entries.length; i++)
        _Series(
          entries[i].key,
          _shopName(entries[i].key) ?? 'Shop ${i + 1}',
          entries[i].value,
          colors[i],
          _dashes[i],
        ),
    ];
  }

  String? _shopName(String productKey, [String? fromPoint]) {
    if (fromPoint != null) return fromPoint;
    final product = _view.products[productKey]?.shopName;
    if (product != null && product.isNotEmpty) return product;
    for (final p in (_view.points[productKey] ?? const []).reversed) {
      if (p.shopName != null) return p.shopName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = _series(theme);
    final muted = AppTextStyles.labelMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (_view.isDemo) const DemoDataBadge(),
            const Spacer(),
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
        if (_view.isGroup) ...[
          const SizedBox(height: AppDimens.space8),
          Wrap(
            spacing: AppDimens.space16,
            runSpacing: AppDimens.space4,
            children: [for (final s in series) _LegendItem(series: s)],
          ),
        ],
        const SizedBox(height: AppDimens.space12),
        ExcludeSemantics(
          child: SizedBox(
            height: widget.chartHeight,
            child: _chart(theme, series, muted),
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: AppDimens.space8),
          _DayDetails(lines: describeDay(_view, _selected!, _shopName)),
        ],
        const SizedBox(height: AppDimens.space12),
        Text(
          summarizeView(_view, _shopName),
          key: const ValueKey('price-summary'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _chart(ThemeData theme, List<_Series> series, TextStyle muted) {
    final days = _view.days;
    final values = [
      for (final s in series)
        for (final p in s.points) ?p.minVnd,
      if (widget.showAfterVoucherDots)
        for (final s in series)
          for (final p in s.points) ?p.afterVoucherMinVnd,
    ];
    if (values.isEmpty || days.isEmpty) return const SizedBox.shrink();
    final low = values.reduce(math.min).toDouble();
    final high = values.reduce(math.max).toDouble();
    final pad = math.max((high - low) * 0.15, high * 0.03);
    final step = math.max(1, (days.length / 5).ceil());
    final lastX = (days.length - 1).toDouble();

    final bars = <LineChartBarData>[
      for (final s in series)
        LineChartBarData(
          spots: [
            for (var i = 0; i < s.points.length; i++)
              switch (s.points[i].minVnd) {
                final v? => FlSpot(i.toDouble(), v.toDouble()),
                null => FlSpot.nullSpot,
              },
          ],
          isStepLineChart: true,
          lineChartStepData: const LineChartStepData(
            stepDirection: LineChartStepData.stepDirectionForward,
          ),
          color: s.color,
          barWidth: 2,
          dashArray: s.dash,
          dotData: FlDotData(
            getDotPainter: (spot, _, _, _) =>
                FlDotCirclePainter(radius: 2.8, color: s.color, strokeWidth: 0),
          ),
        ),
      if (widget.showAfterVoucherDots)
        for (final s in series)
          LineChartBarData(
            spots: [
              for (var i = 0; i < s.points.length; i++)
                switch (s.points[i].afterVoucherMinVnd) {
                  final v? => FlSpot(i.toDouble(), v.toDouble()),
                  null => FlSpot.nullSpot,
                },
            ],
            barWidth: 0,
            color: Colors.transparent,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 2.2,
                color: theme.colorScheme.surface,
                strokeWidth: 1.2,
                strokeColor: s.color,
              ),
            ),
          ),
    ];

    final saleLines = <VerticalLine>[
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(lastX, 1),
        minY: math.max(0, low - pad),
        maxY: high + pad,
        lineBarsData: bars,
        extraLinesData: ExtraLinesData(verticalLines: saleLines),
        gridData: FlGridData(
          drawVerticalLine: false,
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
              reservedSize: 44,
              getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                  ? const SizedBox.shrink()
                  : Text(_axisVnd(v), style: muted),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
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
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions || response == null) return;
            final i = response.touchChartCoordinate.dx.round().clamp(
              0,
              days.length - 1,
            );
            if (i != _selected) setState(() => _selected = i);
          },
        ),
      ),
      duration: Duration.zero,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final _Series series;

  const _LegendItem({required this.series});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: _LineSamplePainter(series.color, series.dash),
        ),
        const SizedBox(width: AppDimens.space4),
        Text(series.name, style: AppTextStyles.labelMedium),
      ],
    );
  }
}

class _LineSamplePainter extends CustomPainter {
  final Color color;
  final List<int>? dash;

  const _LineSamplePainter(this.color, this.dash);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final y = size.height / 2;
    final pattern = dash ?? [size.width.toInt()];
    var x = 0.0;
    for (var k = 0; x < size.width; k++) {
      final len = pattern[k % pattern.length].toDouble();
      if (k.isEven) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + len, size.width), y),
          paint,
        );
      }
      x += len;
    }
    canvas.drawCircle(Offset(size.width / 2, y), 2.8, paint);
  }

  @override
  bool shouldRepaint(_LineSamplePainter old) =>
      old.color != color || old.dash != dash;
}

/// One line of the day details: [muted] for the after-voucher reference,
/// [tag] for the "Đang giảm" label
class DayDetailLine {
  final String text;
  final bool muted;
  final bool tag;

  const DayDetailLine(this.text, {this.muted = false, this.tag = false});
}

typedef ShopNameOf = String? Function(String productKey, [String? fromPoint]);

/// Details of day [i]: date, lowest price (shop, ★), highest rating (group), report
/// count, "Đang giảm", and the after-voucher price as a faint reference line
List<DayDetailLine> describeDay(
  PriceHistoryView view,
  int i,
  ShopNameOf shopName,
) {
  final day = view.days[i];
  final points = [
    for (final entry in view.points.entries)
      if (i < entry.value.length) (entry.key, entry.value[i]),
  ];
  final reports = points.fold(0, (n, p) => n + p.$2.reportCount);
  final hasSale = points.any((p) => p.$2.hasPrice && p.$2.hasSale);
  final vouchers = [for (final p in points) ?p.$2.afterVoucherMinVnd];
  String stars(double? r) => r == null ? '' : ' · ★ ${formatStars(r)}';
  String at(String? shop) => shop == null ? '' : ' · $shop';

  final lines = <DayDetailLine>[DayDetailLine(formatDate(day))];
  String? lowest, best;
  if (view.isGroup) {
    final c = view.comparison != null && i < view.comparison!.length
        ? view.comparison![i]
        : null;
    if (c != null) {
      final low = c.lowestPrice;
      lowest =
          'Thấp nhất: ${formatVnd(low.minVnd)}'
          '${at(shopName(low.productKey, low.shopName))}${stars(low.productRating)}';
      if (c.highestRated case final top?) {
        best =
            'Rating cao nhất: ★ ${formatStars(top.productRating!)}'
            '${at(shopName(top.productKey, top.shopName))} · ${formatVnd(top.minVnd)}';
      }
    }
  } else if (points.isNotEmpty && points.first.$2.minVnd != null) {
    final (key, p) = points.first;
    lowest =
        'Thấp nhất: ${formatVnd(p.minVnd)}'
        '${at(shopName(key, p.shopName))}${stars(p.productRating)}';
  }

  if (lowest != null) {
    lines.add(DayDetailLine(lowest));
    if (best != null) lines.add(DayDetailLine(best));
    lines.add(DayDetailLine('$reports báo cáo'));
    if (hasSale) lines.add(const DayDetailLine('Đang giảm', tag: true));
  } else if (reports > 0) {
    lines.add(DayDetailLine('Chưa đủ dữ liệu ($reports báo cáo)'));
  } else {
    lines.add(const DayDetailLine('Chưa có báo cáo'));
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

/// 1–2 sentences for people who cannot see the chart, neutral wording
String summarizeView(PriceHistoryView view, ShopNameOf shopName) {
  final s = view.summary;
  String place(PriceOnDay p) => switch (shopName(p.productKey, p.shopName)) {
    final shop? => ' tại $shop',
    null => '',
  };
  final first = switch (s.lowest) {
    final low? =>
      'Thấp nhất ${view.range.days} ngày: ${formatVnd(low.vnd)} ngày '
          '${formatDayMonth(low.day)}${place(low)}.',
    null => 'Chưa đủ dữ liệu trong ${view.range.days} ngày.',
  };
  final second = switch (s.latest) {
    final last? =>
      ' Giá gần nhất: ${formatVnd(last.vnd)} ngày ${formatDayMonth(last.day)}'
          '${place(last)} (có dữ liệu ${s.daysWithData}/${view.days.length} ngày).',
    null => '',
  };
  return '$first$second';
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
