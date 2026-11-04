import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/utils/time_slot.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 07: Mô hình from Figma "Why I Buy ver2"
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  static const Map<TimeSlot, IconData> _slotIcons = {
    TimeSlot.morning: Icons.wb_sunny_outlined,
    TimeSlot.noon: Icons.wb_sunny_rounded,
    TimeSlot.afternoon: Icons.wb_twilight_rounded,
    TimeSlot.evening: Icons.nightlight_round,
  };

  static const Map<TimeSlot, Color> _slotColors = {
    TimeSlot.morning: AppColors.slotMorning,
    TimeSlot.noon: AppColors.slotNoon,
    TimeSlot.afternoon: AppColors.slotEvening,
    TimeSlot.evening: AppColors.slotNight,
  };

  StatsPeriod _period = StatsPeriod.week;

  /// Monday of the week shown in "Tuần" mode; the month comes from PurchaseViewModel
  DateTime _weekStart = PurchaseViewModel.weekStartOf(DateTime.now());

  void _shiftWeek(int weeks) => setState(
    () => _weekStart = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + 7 * weeks,
    ),
  );

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Chọn một ngày trong tuần',
    );
    if (picked != null) {
      setState(() => _weekStart = PurchaseViewModel.weekStartOf(picked));
    }
  }

  String get _weekLabel {
    final sunday = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + 6,
    );
    return '${formatDayMonth(_weekStart)} – ${formatDate(sunday)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseVm = context.watch<PurchaseViewModel>();
    final isWeek = _period == StatsPeriod.week;
    // Total, count, motives and time slots all come from this one period
    final stats = isWeek
        ? purchaseVm.weekStats(_weekStart)
        : purchaseVm.monthStats;
    final totalSpent = stats.total;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            WhyIBuyLogo(
              size: 26,
              color: isDark ? AppColors.primary : AppColors.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Mô hình',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body:
          stateView([
            purchaseVm.state,
          ], loadingMessage: 'Đang tải khoản mua...') ??
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Segmented Switcher: Tuần | Tháng
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252D3C)
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentOption(
                          context,
                          'Tuần',
                          StatsPeriod.week,
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentOption(
                          context,
                          'Tháng',
                          StatsPeriod.month,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Period Selector (Interactive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: isWeek ? 'Tuần trước' : 'Tháng trước',
                        onPressed: isWeek
                            ? () => _shiftWeek(-1)
                            : purchaseVm.previousMonth,
                      ),
                      Flexible(
                        child: InkWell(
                          onTap: () async {
                            if (isWeek) return _pickWeek();
                            final picked = await MonthPickerSheet.show(
                              context,
                              purchaseVm.selectedMonth,
                            );
                            if (picked != null) {
                              purchaseVm.setSelectedMonth(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isWeek
                                        ? _weekLabel
                                        : formatMonthLabel(
                                            purchaseVm.selectedMonth,
                                          ),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: isWeek ? 'Tuần sau' : 'Tháng sau',
                        onPressed: isWeek
                            ? () => _shiftWeek(1)
                            : purchaseVm.nextMonth,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Total Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWeek
                                ? 'Tổng chi tiêu trong tuần'
                                : 'Tổng chi tiêu trong tháng',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatVnd(totalSpent),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.primary
                                  : AppColors.accentNeutral,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.count} khoản đã ghi nhận',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2706)
                              : AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pie_chart_rounded,
                          color: isDark
                              ? AppColors.primary
                              : AppColors.onPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Theo động cơ Header
                Text(
                  'Theo động cơ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                // Motives Breakdown List
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      if (stats.motives.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Chưa có khoản mua nào trong kỳ này.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ...stats.motives.map((m) {
                        final motive = m.motive;
                        final sum = m.totalVnd;
                        final count = m.count;
                        final percent = stats.shareOf(sum);
                        final motivePalette = MotiveColors.of(context).paletteOf(motive);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: motivePalette.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      motive.icon,
                                      size: 16,
                                      color: motivePalette.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              motive.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              formatVnd(sum),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.primary
                                                    : AppColors.accentNeutral,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$count khoản chi',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                              ),
                                            ),
                                            Text(
                                              '${(percent * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Track
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? const Color(0xFF262D3B)
                                      : AppColors.surfaceVariant,
                                  color: motive == BuyingMotive.sale
                                      ? AppColors.primary
                                      : motivePalette.foreground,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Khung giờ chi tiêu
                Text(
                  'Khung giờ mua sắm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      for (final stat in stats.timeSlots) ...[
                        if (stat.slot != TimeSlot.values.first)
                          Divider(height: 20, color: theme.dividerColor),
                        _buildTimeSlotRow(
                          context,
                          '${stat.slot.label} (${stat.slot.rangeLabel})',
                          '${stat.count} khoản (${formatVnd(stat.totalVnd)})',
                          _slotIcons[stat.slot]!,
                          _slotColors[stat.slot]!,
                          stats.shareOf(stat.totalVnd),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSegmentOption(
    BuildContext context,
    String label,
    StatsPeriod period,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _period == period;

    return InkWell(
      onTap: () => setState(() => _period = period),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1B202A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.primary : AppColors.onPrimary)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double progress,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: isDark
                ? const Color(0xFF262D3B)
                : AppColors.surfaceVariant,
            color: color,
          ),
        ),
      ],
    );
  }
}
