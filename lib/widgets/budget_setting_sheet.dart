import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';

/// Bottom Sheet for setting and adjusting monthly budget matching Figma "31 Ngân sách theo nhóm"
class BudgetSettingSheet extends StatefulWidget {
  const BudgetSettingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BudgetSettingSheet(),
    );
  }

  @override
  State<BudgetSettingSheet> createState() => _BudgetSettingSheetState();
}

class _BudgetSettingSheetState extends State<BudgetSettingSheet> {
  late TextEditingController _controller;
  late double _amount;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final purchaseVm = context.read<PurchaseViewModel>();
    _amount = purchaseVm.monthlyBudget;
    _controller = TextEditingController(text: _currencyFormat.format(_amount).trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(cleaned) ?? 0;
    setState(() {
      _amount = parsed;
    });
  }

  void _setPredefinedAmount(double val) {
    setState(() {
      _amount = val;
      _controller.text = _currencyFormat.format(_amount).trim();
    });
  }

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final spent = purchaseVm.monthlySpent;
    final remaining = _amount - spent;
    final isExceeded = remaining < 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: AppColors.onPrimary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ngân sách chi tiêu tháng',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6D6E73)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Text(
              'Thiết lập mốc ngân sách để tự quan sát thói quen. Ứng dụng không chặn mua sắm, chỉ gửi thông tin trung tính.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6D6E73), height: 1.35),
            ),

            const SizedBox(height: 16),

            // Budget Input Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Mức ngân sách tháng',
                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF6D6E73)),
                  isDense: true,
                ),
                onChanged: _onAmountChanged,
              ),
            ),

            const SizedBox(height: 12),

            // Quick Budget Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('1.500.000 ₫', 1500000),
                _buildQuickChip('2.000.000 ₫', 2000000),
                _buildQuickChip('3.000.000 ₫', 3000000),
                _buildQuickChip('5.000.000 ₫', 5000000),
              ],
            ),

            const SizedBox(height: 18),

            // Overview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã chi tháng này',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6D6E73)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format(spent).trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF47667B),
                        ),
                      ),
                    ],
                  ),
                  Container(height: 28, width: 1, color: const Color(0xFFD1D5DB)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isExceeded ? 'Đã vượt mốc' : 'Dự kiến còn lại',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format(remaining.abs()).trim(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
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
                onPressed: _isSaving
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSaving = true);
                        await purchaseVm.setMonthlyBudget(_amount);
                        if (!mounted) return;
                        setState(() => _isSaving = false);
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Đã lưu ngân sách: ${_currencyFormat.format(_amount).trim()} lên Firebase!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                      )
                    : const Text(
                        'Lưu ngân sách',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double val) {
    final isSelected = _amount == val;
    return InkWell(
      onTap: () => _setPredefinedAmount(val),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.onPrimary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}
