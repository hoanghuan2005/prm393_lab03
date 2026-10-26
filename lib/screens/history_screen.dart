import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/why_i_buy_logo.dart';
import 'budget_screen.dart';
import 'purchase_detail_screen.dart';
import 'record_purchase_screen.dart';

/// Screen 06: Lịch sử from Figma "Why I Buy ver2"
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final purchases = purchaseVm.filteredPurchases;
    final selectedMonth = purchaseVm.selectedMonth;
    final monthLabel = 'Tháng ${selectedMonth.month}/${selectedMonth.year}';

    // Group purchases by day
    final Map<String, List<PurchaseItem>> grouped = {};
    for (final p in purchases) {
      final key = DateFormat('dd/MM/yyyy').format(p.dateTime);
      grouped.putIfAbsent(key, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
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
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF47667B)),
                  tooltip: 'Tháng trước',
                  onPressed: () => purchaseVm.previousMonth(),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await MonthPickerSheet.show(context, selectedMonth);
                    if (picked != null) {
                      purchaseVm.setSelectedMonth(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.onPrimary),
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
                        const Icon(Icons.arrow_drop_down_rounded, size: 22, color: Color(0xFF6D6E73)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF47667B)),
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
                      onTap: () => purchaseVm.setMotiveFilter(isSelected ? null : motive),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

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
                        const Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        Text(
                          'Không có khoản chi nào trong $monthLabel',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D6E73),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nhấn nút "+" bên dưới để ghi nhận khoản mua sắm mới.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...grouped.keys.map((dateKey) {
                    final dayItems = grouped[dateKey]!;
                    final dayTotal = dayItems.fold(0.0, (sum, i) => sum + i.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Header Row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDayHeader(dateKey),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6D6E73),
                                ),
                              ),
                              Text(
                                '${_formatCurrency(dayTotal)} ₫',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF47667B),
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
                            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                    child: _buildHistoryRow(context, item, purchaseVm),
                                  ),
                                  if (!isLast) const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecordPurchaseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== BUDGET METER CARD (Figma 31) ====================
  Widget _buildBudgetMeterCard(BuildContext context, PurchaseViewModel purchaseVm) {
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
          color: isExceeded ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
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
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF47667B)),
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
                  color: isExceeded ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExceeded ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                ),
              ),
              const Spacer(),
              // Edit button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: Color(0xFF47667B)),
                      SizedBox(width: 4),
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF47667B),
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
                '${_formatCurrency(spent)} ₫',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF47667B),
                ),
              ),
              Text(
                'Mục tiêu: ${_formatCurrency(budget)} ₫',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D6E73),
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
              backgroundColor: const Color(0xFFF3F4F6),
              color: isExceeded ? const Color(0xFFEF4444) : AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          // Explanatory note
          Text(
            isExceeded
                ? 'Đã vượt ${_formatCurrency(spent - budget)} ₫ so với mốc bạn đặt. Ứng dụng không chặn mua.'
                : 'Còn lại ${_formatCurrency(budget - spent)} ₫ trong ngân sách dự kiến tháng này.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6D6E73),
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
          color: isSelected ? const Color(0xFF070E20) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF6D6E73)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF47667B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, PurchaseItem item, PurchaseViewModel vm) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PurchaseDetailScreen(purchase: item)),
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
            '${item.motive.label} • ${DateFormat('HH:mm').format(item.dateTime)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '"${item.note}"',
              style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF6D6E73)),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${_formatCurrency(item.amount)} ₫',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF47667B),
        ),
      ),
    );
  }

  String _formatDayHeader(String dateKey) {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final yesterday = DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1)));

    if (dateKey == now) {
      return 'Hôm nay · $dateKey';
    } else if (dateKey == yesterday) {
      return 'Hôm qua · $dateKey';
    } else {
      return dateKey;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]}.');
  }
}
