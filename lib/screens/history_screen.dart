import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 06: Lịch sử from Figma "Why I Buy ver2"
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Lịch sử',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector: < Tháng MM/YYYY > (Fully Interactive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.accentNeutral,
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
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accentNeutral,
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
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _buildFilterChip(
                  context,
                  label: 'Tất cả',
                  isSelected: purchaseVm.selectedMotiveFilter == null,
                  onTap: () => purchaseVm.setMotiveFilter(null),
                ),
                const SizedBox(width: 8),
                ...BuyingMotive.values.map((motive) {
                  final isSelected = purchaseVm.selectedMotiveFilter == motive;
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

          const Divider(height: 1, color: AppColors.divider),

          // Main Scroll Area with Budget Meter & Purchases
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Monthly Budget Meter Card (Figma "31 Ngân sách theo nhóm")
                _buildBudgetMeterCard(context, purchaseVm),

                const SizedBox(height: 16),

                // 2. Day Grouped Purchases or Empty State
                if (purchases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppColors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có khoản chi nào trong $monthLabel',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nhấn nút "+" bên dưới để ghi nhận khoản mua sắm mới.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDayHeader(dateKey),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formatVnd(dayTotal),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentNeutral,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Day Purchases Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: List.generate(dayItems.length, (i) {
                              final item = dayItems[i];
                              final isLast = i == dayItems.length - 1;
                              return Column(
                                children: [
                                  // Own Material so ink splashes paint above the white card
                                  Material(
                                    type: MaterialType.transparency,
                                    child: _buildHistoryRow(
                                      context,
                                      item,
                                      purchaseVm,
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.surfaceVariant,
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
  Widget _buildBudgetMeterCard(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final spent = purchaseVm.monthlySpent;
    final budget = purchaseVm.monthlyBudget;
    final progress = purchaseVm.budgetProgress;
    final isExceeded = purchaseVm.isBudgetExceeded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded ? AppColors.outline : AppColors.border,
          width: isExceeded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: AppColors.accentNeutral,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ngân sách tháng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.surfaceVariant
                      : AppColors.successContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExceeded
                        ? AppColors.accentNeutral
                        : AppColors.onSuccessContainer,
                  ),
                ),
              ),
              const Spacer(),
              // Edit button
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.budget);
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppColors.accentNeutral,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentNeutral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Numbers Row: 817.000 ₫ / 2.000.000 ₫
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatVnd(spent),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentNeutral,
                ),
              ),
              Text(
                'Mục tiêu: ${formatVnd(budget)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
              backgroundColor: AppColors.surfaceVariant,
              color: isExceeded ? AppColors.accentNeutral : AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          // Explanatory note
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - budget)} so với mốc bạn đặt. Ứng dụng không chặn mua.'
                : 'Còn lại ${formatVnd(budget - spent)} trong ngân sách dự kiến tháng này.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.onPrimary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.accentNeutral,
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
          color: item.motive.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.motive.icon, size: 20, color: item.motive.color),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${item.motive.label} • ${formatTime(item.occurredAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '"${item.note}"',
              style: const TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        formatVnd(item.amountVnd),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.accentNeutral,
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
