import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/why_i_buy_logo.dart';
import 'budget_screen.dart';
import 'purchase_detail_screen.dart';
import 'record_purchase_screen.dart';
import 'wishlist_screen.dart';

/// Screen 02: Trang chủ from Figma "Why I Buy ver2"
class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final wishlistVm = context.watch<WishlistViewModel>();

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
              'Trang chủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Wishlist icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.bookmark_outline_rounded,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
                tooltip: 'Danh sách mong muốn',
                onPressed: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(1); // Go to Lịch sử / Wishlist
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  }
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // User Avatar
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: InkWell(
              onTap: () {
                if (onNavigateTab != null) onNavigateTab!(4); // Cá nhân
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            const Text(
              'Chào bạn,',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Card 1: TỔNG QUAN TUẦN
            _buildWeeklySummaryCard(context, purchaseVm),

            const SizedBox(height: 16),

            // Card 2: Danh sách mong muốn entry
            _buildWishlistEntryCard(context, wishlistVm),

            const SizedBox(height: 24),

            // Section 3: Khoản mua gần đây
            _buildRecentPurchasesSection(context, purchaseVm),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordPurchaseScreen()),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ghi khoản mua',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TỔNG QUAN TUẦN CARD ====================
  Widget _buildWeeklySummaryCard(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
          // Header: TỔNG QUAN TUẦN + Date chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF6D6E73),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'TỔNG QUAN TUẦN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF6D6E73),
                    ),
                  ),
                ],
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
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tháng ${purchaseVm.selectedMonth.month}/${purchaseVm.selectedMonth.year}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: Color(0xFF6D6E73),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Big Amount: 817.000 ₫
          Text(
            '${_formatCurrency(purchaseVm.weeklyTotal)} ₫',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF47667B),
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle: Tuần này: 5 khoản · 817.000 ₫
          Text(
            'Tuần này: ${purchaseVm.weeklyCount} khoản · ${_formatCurrency(purchaseVm.weeklyTotal)} ₫',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6E73),
            ),
          ),

          const SizedBox(height: 4),

          // Highlight: Nhiều nhất: Khuyến mãi (2/5)
          Text.rich(
            TextSpan(
              text: 'Nhiều nhất: ',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6D6E73)),
              children: [
                TextSpan(
                  text: purchaseVm.dominantMotiveSummary.replaceFirst(
                    'Nhiều nhất: ',
                    '',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Motive bar header: Động cơ chính | 40% do Khuyến mãi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Động cơ chính',
                style: TextStyle(fontSize: 12, color: Color(0xFF6D6E73)),
              ),
              Text(
                purchaseVm.dominantMotiveText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  // Khuyến mãi (40% - Yellow)
                  Expanded(
                    flex: 40,
                    child: Container(color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  // Tiện lợi (25% - Slate)
                  Expanded(
                    flex: 25,
                    child: Container(color: const Color(0xFF47667B)),
                  ),
                  const SizedBox(width: 2),
                  // Mong muốn (20% - Dark)
                  Expanded(
                    flex: 20,
                    child: Container(color: const Color(0xFF1F2937)),
                  ),
                  const SizedBox(width: 2),
                  // Nhu cầu (15% - Light gray)
                  Expanded(
                    flex: 15,
                    child: Container(color: const Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),

          // Monthly Budget Quick View
          InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: Color(0xFF47667B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Ngân sách tháng: ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D6E73),
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formatCurrency(purchaseVm.monthlySpent)} ₫ / ${_formatCurrency(purchaseVm.monthlyBudget)} ₫',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: purchaseVm.isBudgetExceeded
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(purchaseVm.budgetProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: purchaseVm.isBudgetExceeded
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DANH SÁCH MONG MUỐN ENTRY CARD ====================
  Widget _buildWishlistEntryCard(
    BuildContext context,
    WishlistViewModel wishlistVm,
  ) {
    return InkWell(
      onTap: () {
        if (onNavigateTab != null) {
          onNavigateTab!(1); // Go to Wishlist / Lịch sử
        } else {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.onPrimary,
              size: 22,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách mong muốn',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '2 món đang cân nhắc',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF6D6E73)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== KHOẢN MUA GẦN ĐÂY SECTION ====================
  Widget _buildRecentPurchasesSection(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final recentList = purchaseVm.recentPurchases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Khoản mua gần đây [3]    Xem tất cả >
        Row(
          children: [
            const Text(
              'Khoản mua gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${recentList.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6D6E73),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                if (onNavigateTab != null) onNavigateTab!(1); // Lịch sử
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF47667B),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF47667B),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Purchases Card Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            children: List.generate(recentList.length, (index) {
              final item = recentList[index];
              final isLast = index == recentList.length - 1;
              return Column(
                children: [
                  _buildPurchaseRow(context, item),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseRow(BuildContext context, PurchaseItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PurchaseDetailScreen(purchase: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Circular Motive Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.motive.icon,
                size: 20,
                color: const Color(0xFF47667B),
              ),
            ),
            const SizedBox(width: 12),

            // Content: Title + Chip + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Motive Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.motive.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.motive.icon,
                              size: 11,
                              color: item.motive.color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.motive.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: item.motive.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Timestamp
                      Text(
                        item.formattedTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Amount: e.g. 40.000 ₫
            Text(
              '${_formatCurrency(item.amount)} ₫',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF47667B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(formatter, (Match m) => '${m[1]}.');
  }
}
