import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/budget_setting_sheet.dart';
import '../widgets/month_picker_sheet.dart';

/// Screen 31, 31a, 31b: Ngân sách theo nhóm from Figma "Why I Buy ver2"
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]}.');
  }

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
            style: TextStyle(fontSize: 13.5, color: Color(0xFF6D6E73), height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final spent = purchaseVm.monthlySpent;
    final budget = purchaseVm.monthlyBudget;
    final progress = purchaseVm.budgetProgress;
    final isExceeded = purchaseVm.isBudgetExceeded;
    final categorySpent = purchaseVm.categorySpent;
    final categoryBudgets = purchaseVm.categoryBudgets;

    final categories = [
      {
        'name': 'Công nghệ',
        'icon': Icons.devices_rounded,
        'spent': categorySpent['Công nghệ'] ?? 0.0,
        'budget': categoryBudgets['Công nghệ'] ?? 1000000.0,
      },
      {
        'name': 'Thời trang',
        'icon': Icons.checkroom_rounded,
        'spent': categorySpent['Thời trang'] ?? 0.0,
        'budget': categoryBudgets['Thời trang'] ?? 600000.0,
      },
      {
        'name': 'Ăn uống',
        'icon': Icons.restaurant_rounded,
        'spent': categorySpent['Ăn uống'] ?? 0.0,
        'budget': categoryBudgets['Ăn uống'] ?? 500000.0,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onPrimary),
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
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF6D6E73)),
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
              else ...[
                // Overall Budget Card (Figma 31a/31b)
                _buildOverallBudgetCard(context, spent, budget, progress, isExceeded),

                const SizedBox(height: 24),

                // Category Budgets Header
                const Text(
                  'CÁC NHÓM NGÂN SÁCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF6D6E73),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Cards
                ...categories.map((cat) {
                  return _buildCategoryCard(
                    name: cat['name'] as String,
                    icon: cat['icon'] as IconData,
                    spent: cat['spent'] as double,
                    catBudget: cat['budget'] as double,
                  );
                }),

                const SizedBox(height: 16),

                // Note at bottom (Figma 31)
                const Center(
                  child: Text(
                    'Bỏ qua cũng được: Decision Card vẫn hoạt động, chỉ không tính phần trăm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _buildMonthSelector(BuildContext context, PurchaseViewModel purchaseVm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.onPrimary),
            onPressed: () => purchaseVm.previousMonth(),
          ),
          InkWell(
            onTap: () async {
              final picked = await MonthPickerSheet.show(context, purchaseVm.selectedMonth);
              if (picked != null) {
                purchaseVm.setSelectedMonth(picked);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF47667B)),
                  const SizedBox(width: 8),
                  Text(
                    'Tháng ${purchaseVm.selectedMonth.month}/${purchaseVm.selectedMonth.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6D6E73)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.onPrimary),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCE6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 30, color: AppColors.onPrimary),
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
            style: TextStyle(fontSize: 13, color: Color(0xFF6D6E73), height: 1.4),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => BudgetSettingSheet.show(context),
              child: const Text('Đặt ngân sách cho tháng này', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetCard(
    BuildContext context,
    double spent,
    double budget,
    double progress,
    bool isExceeded,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isExceeded ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isExceeded ? const Color(0xFFDC2626) : const Color(0xFF059669),
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
                '${_formatCurrency(spent)} ₫',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF47667B),
                ),
              ),
              Text(
                '/ ${_formatCurrency(budget)} ₫',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D6E73),
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
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? const Color(0xFF47667B) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExceeded
                ? 'Đã vượt ${_formatCurrency(spent - budget)} ₫ so với mốc bạn đặt. App không chặn mua.'
                : 'Còn lại ${_formatCurrency(budget - spent)} ₫ trong ngân sách dự kiến tháng này.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6D6E73),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required IconData icon,
    required double spent,
    required double catBudget,
  }) {
    final progress = catBudget > 0 ? (spent / catBudget).clamp(0.0, 1.0) : 0.0;
    final isExceeded = spent > catBudget && catBudget > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF47667B)),
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
                '${_formatCurrency(spent)} ₫ / ${_formatCurrency(catBudget)} ₫',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF47667B),
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
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? const Color(0xFF47667B) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isExceeded
                ? 'Đã vượt ${_formatCurrency(spent - catBudget)} ₫ so với mốc nhóm. App không chặn mua.'
                : 'Còn lại ${_formatCurrency(catBudget - spent)} ₫ trong nhóm này.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6D6E73),
            ),
          ),
        ],
      ),
    );
  }
}
