import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedPeriod = 0; // 0 = Tuần, 1 = Tháng

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final allPurchases = purchaseVm.allPurchases;

    // Calculate motive counts and sums
    final Map<BuyingMotive, double> motiveSums = {};
    final Map<BuyingMotive, int> motiveCounts = {};
    for (final p in allPurchases) {
      motiveSums[p.motive] = (motiveSums[p.motive] ?? 0) + p.amount;
      motiveCounts[p.motive] = (motiveCounts[p.motive] ?? 0) + 1;
    }

    final totalSpent = purchaseVm.weeklyTotal;

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
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentOption('Tuần', 0),
                  ),
                  Expanded(
                    child: _buildSegmentOption('Tháng', 1),
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF47667B)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Tháng ${purchaseVm.selectedMonth.month}/${purchaseVm.selectedMonth.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF6D6E73)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF47667B)),
                    onPressed: () => purchaseVm.nextMonth(),
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng chi tiêu trong kỳ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D6E73),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(totalSpent)} ₫',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF47667B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${purchaseVm.weeklyCount} khoản đã ghi nhận',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFCE6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: AppColors.onPrimary, size: 24),
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: BuyingMotive.values.map((motive) {
                  final sum = motiveSums[motive] ?? 0;
                  final count = motiveCounts[motive] ?? 0;
                  final percent = totalSpent > 0 ? (sum / totalSpent) : 0.0;
                  if (count == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              child: Icon(motive.icon, size: 16, color: motive.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        '${_formatCurrency(sum)} ₫',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF47667B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$count khoản chi',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                      ),
                                      Text(
                                        '${(percent * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6D6E73),
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
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: motive == BuyingMotive.sale ? AppColors.primary : motive.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildTimeSlotRow('Đêm (22:00 - 05:00)', '1 khoản (389.000 ₫)', Icons.nightlight_round, const Color(0xFF6366F1), 0.48),
                  const Divider(height: 20),
                  _buildTimeSlotRow('Chiều & Tối (14:00 - 22:00)', '2 khoản (245.000 ₫)', Icons.wb_twilight_rounded, const Color(0xFFF59E0B), 0.30),
                  const Divider(height: 20),
                  _buildTimeSlotRow('Trưa (11:00 - 14:00)', '1 khoản (40.000 ₫)', Icons.wb_sunny_rounded, const Color(0xFF10B981), 0.05),
                  const Divider(height: 20),
                  _buildTimeSlotRow('Sáng (05:00 - 11:00)', '1 khoản (143.000 ₫)', Icons.wb_sunny_outlined, const Color(0xFF3B82F6), 0.17),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentOption(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = index),
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
            color: isSelected ? AppColors.onPrimary : const Color(0xFF6D6E73),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(String title, String subtitle, IconData icon, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6D6E73)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFF3F4F6),
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]}.');
  }
}
