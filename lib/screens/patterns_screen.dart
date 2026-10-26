import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/utils/time_slot.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
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
    final purchaseVm = context.watch<PurchaseViewModel>();
    final isWeek = _period == StatsPeriod.week;
    // Total, count, motives and time slots all come from this one period
    final stats = isWeek
        ? purchaseVm.weekStats(_weekStart)
        : purchaseVm.monthStats;
    final totalSpent = stats.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            SizedBox(width: 8),
            Text(
              'Mô hình',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Segmented Switcher: Tuần | Tháng
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentOption('Tuần', StatsPeriod.week),
                  ),
                  Expanded(
                    child: _buildSegmentOption('Tháng', StatsPeriod.month),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Period Selector (Interactive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.accentNeutral,
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
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: AppColors.onPrimary,
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.accentNeutral,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVnd(totalSpent),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentNeutral,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.count} khoản đã ghi nhận',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.onPrimary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Theo động cơ Header
            const Text(
              'Theo động cơ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Motives Breakdown List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (stats.motives.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chưa có khoản mua nào trong kỳ này.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ...stats.motives.map((m) {
                    final motive = m.motive;
                    final sum = m.totalVnd;
                    final count = m.count;
                    final percent = stats.shareOf(sum);

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
                                  color: motive.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  motive.icon,
                                  size: 16,
                                  color: motive.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          motive.label,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                        Text(
                                          formatVnd(sum),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentNeutral,
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
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                        Text(
                                          '${(percent * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
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
                              backgroundColor: AppColors.surfaceVariant,
                              color: motive == BuyingMotive.sale
                                  ? AppColors.primary
                                  : motive.color,
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
            const Text(
              'Khung giờ mua sắm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final stat in stats.timeSlots) ...[
                    if (stat.slot != TimeSlot.values.first)
                      const Divider(height: 20),
                    _buildTimeSlotRow(
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

  Widget _buildSegmentOption(String label, StatsPeriod period) {
    final isSelected = _period == period;
    return InkWell(
      onTap: () => setState(() => _period = period),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
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
            backgroundColor: AppColors.surfaceVariant,
            color: color,
          ),
        ),
      ],
    );
  }
}
