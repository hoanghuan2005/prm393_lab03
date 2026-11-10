import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/available_budget.dart';
import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/budget_setting_sheet.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

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
        content: SingleChildScrollView(
          child: Text(
            '• Ngân sách là mốc tham chiếu bạn tự đặt cho từng nhóm hàng.\n\n'
            '• Ứng dụng không đồng bộ tài khoản ngân hàng và hoàn toàn KHÔNG chặn mua sắm.\n\n'
            '• Khi vượt mốc, ứng dụng chỉ đưa ra thông tin trung tính để bạn tự quan sát tâm lý tiêu dùng của chính mình.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppSemanticColors.of(context).textSecondary,
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
    // Compared with the limits, so only groups that have one
    final spent = budgetVm.limitedSpent;
    final budget = budgetVm.totalLimit;
    final progress = budgetVm.progress;
    final isExceeded = budgetVm.isExceeded;
    // Groups with a limit, plus groups without one that already have spending this month
    final visibleGroups = budgetVm.visibleGroups;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Ngân sách theo nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: AppSemanticColors.of(context).textSecondary,
            ),
            tooltip: 'Giải thích ngân sách',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body:
          stateView([
            budgetVm.state,
            purchaseVm.state,
          ], loadingMessage: 'Đang tải ngân sách...') ??
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector Row
                  _buildMonthSelector(context, purchaseVm),

                  const SizedBox(height: 16),

                  if (!budgetVm.isBudgetLoaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (budget <= 0)
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
                  if (budget > 0 && budgetVm.unlimitedSpent > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ngoài ra bạn đã chi ${formatVnd(budgetVm.unlimitedSpent)} ở nhóm chưa đặt hạn mức (không tính vào tổng trên).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppSemanticColors.of(context).textSecondary,
                        ),
                      ),
                    ),

                  if (visibleGroups.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    // Category Budgets Header
                    Text(
                      'CÁC NHÓM NGÂN SÁCH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppSemanticColors.of(context).textSecondary,
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
                    Center(
                      child: Text(
                        'Bỏ qua cũng được: Thẻ Quyết Định vẫn hoạt động, chỉ không tính phần trăm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppSemanticColors.of(context).hint,
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
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.onPrimary,
            ),
            tooltip: 'Tháng trước',
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
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppSemanticColors.of(context).accent,
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
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppSemanticColors.of(context).textSecondary,
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
            tooltip: 'Tháng sau',
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
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).primaryContainer,
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
          Text(
            'Ngân sách là mốc tham chiếu bạn tự đặt cho từng nhóm hàng. App không đồng bộ ngân hàng và không chặn mua.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppSemanticColors.of(context).textSecondary,
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
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
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
                      ? AppSemanticColors.of(context).mutedSurface
                      : AppSemanticColors.of(context).successContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isExceeded
                        ? AppSemanticColors.of(context).accent
                        : AppSemanticColors.of(context).onSuccessContainer,
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppSemanticColors.of(context).accent,
                ),
              ),
              Text(
                '/ ${formatVnd(budget)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.of(context).textSecondary,
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
              backgroundColor: AppSemanticColors.of(context).divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded
                    ? AppSemanticColors.of(context).accent
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - budget)} so với mốc bạn đặt. App không chặn mua.'
                : 'Còn lại ${formatVnd(budget - spent)} trong ngân sách dự kiến tháng này.',
            style: TextStyle(
              fontSize: 12,
              color: AppSemanticColors.of(context).textSecondary,
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
            style: TextStyle(
              fontSize: 13.5,
              color: AppSemanticColors.of(context).textSecondary,
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
      return _buildUnlimitedGroupCard(
        context,
        name: name,
        icon: icon,
        spent: spent,
      );
    }
    final catBudget = breakdown.limit;
    final progress = catBudget > 0 ? (spent / catBudget).clamp(0.0, 1.0) : 0.0;
    final isExceeded = spent > catBudget && catBudget > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
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
                  color: AppSemanticColors.of(context).mutedSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppSemanticColors.of(context).accent,
                ),
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.of(context).accent,
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
              backgroundColor: AppSemanticColors.of(context).divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded
                    ? AppSemanticColors.of(context).accent
                    : AppSemanticColors.of(context).hint,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - catBudget)} so với mốc nhóm. App không chặn mua.'
                : 'Còn lại ${formatVnd(catBudget - spent)} · '
                      'khả dụng cho danh sách mong muốn ${formatVnd(breakdown.available)}.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppSemanticColors.of(context).textSecondary,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                foregroundColor: AppSemanticColors.of(context).accent,
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
  Widget _buildUnlimitedGroupCard(
    BuildContext context, {
    required String name,
    required IconData icon,
    required int spent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).mutedSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppSemanticColors.of(context).accent,
            ),
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
                Text(
                  'Chưa đặt hạn mức tháng này',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppSemanticColors.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Đã chi ${formatVnd(spent)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppSemanticColors.of(context).accent,
            ),
          ),
        ],
      ),
    );
  }
}
