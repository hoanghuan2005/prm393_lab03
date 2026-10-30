import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 06: Lịch sử from Figma "Why I Buy ver2"
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseVm = context.watch<PurchaseViewModel>();
    final purchases = purchaseVm.filteredPurchases;
    final selectedMonth = purchaseVm.selectedMonth;
    final monthLabel = formatMonthLabel(selectedMonth);

    // Group purchases by day
    final Map<String, List<PurchaseItem>> grouped = {};
    for (final p in purchases) {
      final key = formatDate(p.occurredAt);
      grouped.putIfAbsent(key, () => []).add(p);
    }

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
              'Lịch sử',
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
          ], loadingMessage: 'Đang tải lịch sử...') ??
          Column(
            children: [
              // Period Selector: < Tháng MM/YYYY > (Fully Interactive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: theme.colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Tháng trước',
                      onPressed: () => purchaseVm.previousMonth(),
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await MonthPickerSheet.show(
                          context,
                          selectedMonth,
                        );
                        if (picked != null) {
                          purchaseVm.setSelectedMonth(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              monthLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Tháng sau',
                      onPressed: () => purchaseVm.nextMonth(),
                    ),
                  ],
                ),
              ),

              // Motive Filter Chips (Horizontal scroll)
              Container(
                height: 48,
                color: theme.colorScheme.surface,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'Tất cả',
                      isSelected: purchaseVm.selectedMotiveFilter == null,
                      onTap: () => purchaseVm.setMotiveFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...BuyingMotive.values.map((motive) {
                      final isSelected =
                          purchaseVm.selectedMotiveFilter == motive;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildFilterChip(
                          context,
                          label: motive.label,
                          icon: motive.icon,
                          isSelected: isSelected,
                          onTap: () => purchaseVm.setMotiveFilter(
                            isSelected ? null : motive,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Divider(height: 1, color: theme.dividerColor),

              // Main Scroll Area with Budget Meter & Purchases
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Monthly Budget Meter Card (Figma "31 Ngân sách theo nhóm")
                    _buildBudgetMeterCard(context),

                    const SizedBox(height: 16),

                    // 2. Day Grouped Purchases or Empty State
                    if (purchases.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không có khoản chi nào trong $monthLabel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút "+" bên dưới để ghi nhận khoản mua sắm mới.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...grouped.keys.map((dateKey) {
                        final dayItems = grouped[dateKey]!;
                        final dayTotal = dayItems.fold(
                          0,
                          (sum, i) => sum + i.amountVnd,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Header Row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDayHeader(dateKey),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatVnd(dayTotal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.primary
                                          : AppColors.accentNeutral,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Day Purchases Card
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                children: List.generate(dayItems.length, (i) {
                                  final item = dayItems[i];
                                  final isLast = i == dayItems.length - 1;
                                  return Column(
                                    children: [
                                      Material(
                                        type: MaterialType.transparency,
                                        child: _buildHistoryRow(
                                          context,
                                          item,
                                          purchaseVm,
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          color: theme.dividerColor,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        tooltip: 'Ghi khoản mua mới',
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.recordPurchase);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== BUDGET METER CARD (Figma 31) ====================
  Widget _buildBudgetMeterCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetVm = context.watch<BudgetViewModel>();
    final spent = budgetVm.limitedSpent;
    final budget = budgetVm.totalLimit;
    final progress = budgetVm.progress;
    final isExceeded = budgetVm.isExceeded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? (isDark ? const Color(0xFFEF4444) : AppColors.outline)
              : theme.dividerColor,
          width: isExceeded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Fixed overflow bug with Expanded + Flexible)
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: isDark ? AppColors.primary : AppColors.accentNeutral,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Ngân sách tháng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isExceeded
                            ? (isDark
                                ? const Color(0xFF451A1A)
                                : AppColors.surfaceVariant)
                            : (isDark
                                ? const Color(0xFF064E3B)
                                : AppColors.successContainer),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isExceeded
                              ? (isDark
                                  ? const Color(0xFFFCA5A5)
                                  : AppColors.accentNeutral)
                              : (isDark
                                  ? const Color(0xFF6EE7B7)
                                  : AppColors.onSuccessContainer),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.budget);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: isDark ? AppColors.primary : AppColors.accentNeutral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primary
                              : AppColors.accentNeutral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Numbers Row: 817.000 ₫ / 2.000.000 ₫ (with overflow protection)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  formatVnd(spent),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.primary
                        : AppColors.accentNeutral,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mục tiêu: ${formatVnd(budget)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Budget Meter Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark
                  ? const Color(0xFF262D3B)
                  : AppColors.surfaceVariant,
              color: isExceeded
                  ? (isDark ? const Color(0xFFEF4444) : AppColors.accentNeutral)
                  : AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          // Explanatory note
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - budget)} so với mốc bạn đặt. Ứng dụng không chặn mua.'
                : 'Còn lại ${formatVnd(budget - spent)} trong ngân sách dự kiến tháng này.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.primary : AppColors.onPrimary)
        : (isDark ? const Color(0xFF252D3C) : AppColors.surfaceVariant);

    final textColor = isSelected
        ? (isDark ? AppColors.onPrimary : Colors.white)
        : (isDark ? const Color(0xFFCBD5E1) : AppColors.accentNeutral);

    final iconColor = isSelected
        ? (isDark ? AppColors.onPrimary : Colors.white)
        : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    PurchaseItem item,
    PurchaseViewModel vm,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final motivePalette = MotiveColors.of(context).paletteOf(item.motive);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.purchaseDetail,
          arguments: PurchaseDetailArgs(item),
        );
      },
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: motivePalette.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.motive.icon, size: 20, color: motivePalette.foreground),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${item.motive.label} • ${formatTime(item.occurredAt)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '"${item.note}"',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Text(
        formatVnd(item.amountVnd),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.primary : AppColors.accentNeutral,
        ),
      ),
    );
  }

  String _formatDayHeader(String dateKey) {
    final now = formatDate(DateTime.now());
    final yesterday = formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (dateKey == now) {
      return 'Hôm nay · $dateKey';
    } else if (dateKey == yesterday) {
      return 'Hôm qua · $dateKey';
    } else {
      return dateKey;
    }
  }
}
