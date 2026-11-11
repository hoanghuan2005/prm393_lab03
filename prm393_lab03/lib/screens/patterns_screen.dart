import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/utils/time_slot.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 07: Mô hình from Figma "Why I Buy ver2"
class PatternsScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;

  const PatternsScreen({super.key, this.onProfileTap, this.onBackTap});

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

  Map<TimeSlot, Color> get _slotColors => {
    TimeSlot.morning: AppSemanticColors.of(context).slotMorning,
    TimeSlot.noon: AppSemanticColors.of(context).slotNoon,
    TimeSlot.afternoon: AppSemanticColors.of(context).slotEvening,
    TimeSlot.evening: AppSemanticColors.of(context).slotNight,
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

  bool get _canGoToNextWeek =>
      _weekStart.isBefore(PurchaseViewModel.weekStartOf(DateTime.now()));

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Trang chủ',
          onPressed: widget.onBackTap,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Mô hình',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [AppHeaderActions(onProfileTap: widget.onProfileTap)],
      ),
      body:
          stateView([
            purchaseVm.state,
          ], loadingMessage: 'Đang tải khoản mua...') ??
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Segmented Switcher: Tuần | Tháng
                Container(
                  padding: const EdgeInsets.all(AppDimens.space4),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.of(context).divider,
                    borderRadius: AppDimens.borderMedium,
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

                const SizedBox(height: AppDimens.space12),

                // Period Selector (Interactive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                    vertical: AppDimens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppDimens.borderLarge,
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
                              lastMonth: DateTime.now(),
                            );
                            if (picked != null) {
                              purchaseVm.setSelectedMonth(picked);
                            }
                          },
                          borderRadius: AppDimens.borderSmall,
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppDimens.minTouchTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.space8,
                              vertical: AppDimens.space6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: AppDimens.space8),
                                Flexible(
                                  child: Text(
                                    isWeek
                                        ? _weekLabel
                                        : formatMonthLabel(
                                            purchaseVm.selectedMonth,
                                          ),
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles
                                        .bodyMedium
                                        .withInheritedColor
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.space4),
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
                        // No future periods: nothing can have been recorded there yet
                        onPressed: isWeek
                            ? (_canGoToNextWeek ? () => _shiftWeek(1) : null)
                            : (purchaseVm.canGoToNextMonth
                                  ? purchaseVm.nextMonth
                                  : null),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.space16),

                // Total Summary Card
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppDimens.borderLarge,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Wrap(
                    spacing: AppDimens.space8,
                    runSpacing: AppDimens.space8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWeek
                                ? 'Tổng chi tiêu trong tuần'
                                : 'Tổng chi tiêu trong tháng',
                            style: AppTextStyles.labelMedium.withInheritedColor
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppDimens.space4),
                          Text(
                            formatVnd(totalSpent),
                            style: AppTextStyles
                                .displayMedium
                                .withInheritedColor
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppSemanticColors.of(context).accent,
                                ),
                          ),
                          const SizedBox(height: AppDimens.space2),
                          Text(
                            '${stats.count} khoản đã ghi nhận',
                            style: AppTextStyles.labelMedium.withInheritedColor
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppSemanticColors.of(context).primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pie_chart_rounded,
                          color: AppSemanticColors.of(context).emphasis,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.space24),

                // Theo động cơ Header
                Text(
                  'Theo động cơ',
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: AppDimens.space12),

                // Motives Breakdown List
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppDimens.borderLarge,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      if (stats.motives.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          child: Text(
                            'Chưa có khoản mua nào trong kỳ này.',
                            style: AppTextStyles.bodyMedium.withInheritedColor
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ...stats.motives.map((m) {
                        final motive = m.motive;
                        final sum = m.totalVnd;
                        final count = m.count;
                        final percent = stats.shareOf(sum);
                        final motivePalette = MotiveColors.of(context)
                            .paletteOf(motive);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.space16,
                            vertical: AppDimens.space12,
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
                                      borderRadius: AppDimens.borderSmall,
                                    ),
                                    child: Icon(
                                      motive.icon,
                                      size: 16,
                                      color: motivePalette.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: AppDimens.space8,
                                          runSpacing: AppDimens.space8,
                                          alignment: WrapAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              motive.label,
                                              style: AppTextStyles
                                                  .bodyMedium
                                                  .withInheritedColor
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              formatVnd(sum),
                                              style: AppTextStyles
                                                  .bodyMedium
                                                  .withInheritedColor
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppSemanticColors.of(
                                                      context,
                                                    ).accent,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppDimens.space4,
                                        ),
                                        Wrap(
                                          spacing: AppDimens.space8,
                                          runSpacing: AppDimens.space8,
                                          alignment: WrapAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$count khoản chi',
                                              style: AppTextStyles
                                                  .labelMedium
                                                  .withInheritedColor
                                                  .copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                            ),
                                            Text(
                                              '${(percent * 100).toStringAsFixed(0)}%',
                                              style: AppTextStyles
                                                  .labelMedium
                                                  .withInheritedColor
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimens.space8),
                              // Track
                              ClipRRect(
                                borderRadius: AppDimens.borderSmall,
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 6,
                                  backgroundColor: AppSemanticColors.of(context)
                                      .mutedSurface,
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

                const SizedBox(height: AppDimens.space24),

                // Khung giờ chi tiêu
                Text(
                  'Khung giờ mua sắm',
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimens.space12),

                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppDimens.borderLarge,
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
    final isSelected = _period == period;

    return InkWell(
      onTap: () => setState(() => _period = period),
      borderRadius: AppDimens.borderMedium,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
        decoration: BoxDecoration(
          color: isSelected
              ? (AppSemanticColors.of(context).cardSurface)
              : Colors.transparent,
          borderRadius: AppDimens.borderMedium,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppSemanticColors.of(context).segmentShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (AppSemanticColors.of(context).emphasis)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDimens.space8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            Text(
              subtitle,
              style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space6),
        ClipRRect(
          borderRadius: AppDimens.borderSmall,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppSemanticColors.of(context).mutedSurface,
            color: color,
          ),
        ),
      ],
    );
  }
}
