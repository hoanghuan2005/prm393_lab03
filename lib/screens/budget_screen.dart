import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/available_budget.dart';
import '../theme/app_colors.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/budget_setting_sheet.dart';
import '../widgets/month_picker_sheet.dart';

/// Screen 31, 31a, 31b: Ngân sách theo nhóm from Figma "Why I Buy ver2"
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const Map<String, IconData> _groupIcons = {
    'food': Icons.restaurant_rounded,
    'fashion': Icons.checkroom_rounded,
    'tech': Icons.devices_rounded,
    'beauty': Icons.face_retouching_natural_rounded,
    'study': Icons.school_rounded,
    'other': Icons.more_horiz_rounded,
  };

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.onPrimary),
            SizedBox(width: 8),
            Text('Vì sao con số này?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '• Ngân sách là mốc tham chiếu bạn tự đặt cho từng nhóm hàng.\n\n'
            '• Ứng dụng không đồng bộ tài khoản ngân hàng và hoàn toàn KHÔNG chặn mua sắm.\n\n'
            '• Khi vượt mốc, ứng dụng chỉ đưa ra thông tin trung tính để bạn tự quan sát tâm lý tiêu dùng của chính mình.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final budgetVm = context.watch<BudgetViewModel>();
    final spent = budgetVm.totalSpent;
    final budget = budgetVm.totalLimit;
    final progress = budgetVm.progress;
    final isExceeded = budgetVm.isExceeded;
    // Groups with a limit, plus groups without one that already have spending this month
    final visibleGroups = budgetVm.visibleGroups;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ngân sách theo nhóm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Giải thích ngân sách',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector Row
              _buildMonthSelector(context, purchaseVm),

              const SizedBox(height: 16),

              if (budget <= 0)
                _buildEmptyState(context)
              else
                // Overall Budget Card (Figma 31a/31b)
                _buildOverallBudgetCard(
                  context,
                  spent,
                  budget,
                  progress,
                  isExceeded,
                ),

              if (visibleGroups.isNotEmpty) ...[
                const SizedBox(height: 24),

                // Category Budgets Header
                const Text(
                  'CÁC NHÓM NGÂN SÁCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Category Cards
                ...visibleGroups.map((group) {
                  return _buildCategoryCard(
                    context,
                    name: group.name,
                    icon: _groupIcons[group.id] ?? Icons.more_horiz_rounded,
                    spent: budgetVm.spentFor(group.id),
                    breakdown: budgetVm.availableBreakdown(group.id),
                  );
                }),
              ],

              if (budget > 0) ...[
                const SizedBox(height: 16),

                // Note at bottom (Figma 31)
                const Center(
                  child: Text(
                    'Bỏ qua cũng được: Decision Card vẫn hoạt động, chỉ không tính phần trăm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      height: 1.35,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Button: Thiết lập lại ngân sách
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => BudgetSettingSheet.show(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cài đặt mức ngân sách',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              color: AppColors.onPrimary,
            ),
            onPressed: () => purchaseVm.previousMonth(),
          ),
          InkWell(
            onTap: () async {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.accentNeutral,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatMonthLabel(purchaseVm.selectedMonth),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onPrimary,
            ),
            onPressed: () => purchaseVm.nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 30,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa đặt ngân sách nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ngân sách là mốc tham chiếu bạn tự đặt cho từng nhóm hàng. App không đồng bộ ngân hàng và không chặn mua.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => BudgetSettingSheet.show(context),
              child: const Text(
                'Đặt ngân sách cho tháng này',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetCard(
    BuildContext context,
    int spent,
    int budget,
    double progress,
    bool isExceeded,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng ngân sách tháng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.surfaceVariant
                      : AppColors.successContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isExceeded
                        ? AppColors.accentNeutral
                        : AppColors.onSuccessContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatVnd(spent),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentNeutral,
                ),
              ),
              Text(
                '/ ${formatVnd(budget)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Neutral progress meter (Đặc tả 11.4 Figma)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? AppColors.accentNeutral : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - budget)} so với mốc bạn đặt. App không chặn mua.'
                : 'Còn lại ${formatVnd(budget - spent)} trong ngân sách dự kiến tháng này.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// "Vì sao con số này?" for one group: spec 7.1 with the user's own numbers
  void _showAvailableExplanation(
    BuildContext context,
    String groupName,
    AvailableBudget b,
  ) {
    final lines = <String>[
      'Hạn mức nhóm: ${formatVnd(b.limit)}',
      '− Đã chi tháng này: ${formatVnd(b.spent)}',
      '= Còn lại: ${formatVnd(b.remaining)}',
      '',
      if (b.hasEnoughHistory) ...[
        '− Dự phòng chi thường ngày: ${formatVnd(b.dailyAverage)}/ngày × '
            '${b.daysLeft} ngày còn lại = ${formatVnd(b.buffer)}',
        '  (trung bình ${b.windowDays} ngày gần nhất của nhóm, '
            'không tính khoản mua từ danh sách mong muốn)',
      ] else
        '− Dự phòng chi thường ngày: 0 ₫ (chưa đủ '
            '${AvailableBudget.historyDaysRequired} ngày dữ liệu chi tiêu, '
            'con số có thể cao hơn thực tế)',
      '× ${100 - AvailableBudget.safetyMarginPercent}% '
          '(chừa ${AvailableBudget.safetyMarginPercent}% biên độ an toàn)',
      '',
      '= Khả dụng cho danh sách mong muốn: ${formatVnd(b.available)}',
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Vì sao con số này? · $groupName'),
        content: SingleChildScrollView(
          child: Text(
            lines.join('\n'),
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String name,
    required IconData icon,
    required int spent,
    required AvailableBudget? breakdown,
  }) {
    if (breakdown == null) {
      return _buildUnlimitedGroupCard(name: name, icon: icon, spent: spent);
    }
    final catBudget = breakdown.limit;
    final progress = catBudget > 0 ? (spent / catBudget).clamp(0.0, 1.0) : 0.0;
    final isExceeded = spent > catBudget && catBudget > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.accentNeutral),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nhóm $name',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              Text(
                '${formatVnd(spent)} / ${formatVnd(catBudget)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentNeutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Neutral budget meter
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? AppColors.accentNeutral : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - catBudget)} so với mốc nhóm. App không chặn mua.'
                : 'Còn lại ${formatVnd(catBudget - spent)} · '
                      'khả dụng cho danh sách mong muốn ${formatVnd(breakdown.available)}.',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.accentNeutral,
              ),
              onPressed: () =>
                  _showAvailableExplanation(context, name, breakdown),
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const Text('Vì sao con số này?'),
            ),
          ),
        ],
      ),
    );
  }

  /// Group with spending but no limit this month: shown so every purchase is accounted for
  Widget _buildUnlimitedGroupCard({
    required String name,
    required IconData icon,
    required int spent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accentNeutral),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhóm $name',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chưa đặt hạn mức tháng này',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Đã chi ${formatVnd(spent)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentNeutral,
            ),
          ),
        ],
      ),
    );
  }
}
