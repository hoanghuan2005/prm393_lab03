import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 02: Trang chủ from Figma "Why I Buy ver2"
class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseVm = context.watch<PurchaseViewModel>();
    final wishlistVm = context.watch<WishlistViewModel>();

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
              'Trang chủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
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
                icon: Icon(
                  Icons.bookmark_outline_rounded,
                  color: isDark ? AppColors.primary : AppColors.onPrimary,
                  size: 24,
                ),
                tooltip: 'Danh sách mong muốn',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.wishlist);
                },
              ),
              if (wishlistVm.consideringCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${wishlistVm.consideringCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
      body:
          stateView([
            purchaseVm.state,
          ], loadingMessage: 'Đang tải khoản mua...') ??
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Chào bạn,',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                // Card 1: TỔNG QUAN THÁNG (selected month)
                _buildMonthSummaryCard(context, purchaseVm),

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
              Navigator.pushNamed(context, AppRoutes.recordPurchase);
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

  /// Stacked bar of the month's motives, widest first, in each motive's own color
  List<Widget> _motiveSegments(BuildContext context, Map<BuyingMotive, double> distribution) {
    final theme = Theme.of(context);
    if (distribution.isEmpty) {
      return [
        Expanded(
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ];
    }
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const SizedBox(width: 2),
        Expanded(
          flex: (entries[i].value * 1000).round().clamp(1, 1000),
          child: Container(color: entries[i].key.color),
        ),
      ],
    ];
  }

  // ==================== TỔNG QUAN THÁNG CARD ====================
  Widget _buildMonthSummaryCard(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetVm = context.watch<BudgetViewModel>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TỔNG QUAN THÁNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMonthLabel(purchaseVm.selectedMonth),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Big Amount
          Text(
            formatVnd(purchaseVm.monthTotal),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.primary : AppColors.accentNeutral,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Count text
          Text(
            '${purchaseVm.monthCount} khoản trong tháng'
            '${purchaseVm.isCurrentMonthSelected ? ' · Tuần này: ${purchaseVm.weekCount} khoản (${formatVnd(purchaseVm.weekTotal)})' : ''}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 4),

          // Highlight: Nhiều nhất: Khuyến mãi (2/5)
          Text.rich(
            TextSpan(
              text: 'Nhiều nhất: ',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: purchaseVm.dominantMotiveSummary.replaceFirst(
                    'Nhiều nhất: ',
                    '',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Motive bar header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space4,
            children: [
              Text(
                'Động cơ chính',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                purchaseVm.dominantMotiveText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
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
                children: _motiveSegments(context, purchaseVm.motiveDistribution),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: theme.dividerColor),
          ),

          // Monthly Budget Quick View
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.budget);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: isDark ? AppColors.primary : AppColors.accentNeutral,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Ngân sách tháng: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: budgetVm.totalLimit > 0
                                ? '${formatVnd(budgetVm.limitedSpent)} / ${formatVnd(budgetVm.totalLimit)}'
                                : 'chưa đặt',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (budgetVm.totalLimit > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: budgetVm.isExceeded
                            ? (isDark
                                ? const Color(0xFF451A1A)
                                : AppColors.surfaceVariant)
                            : (isDark
                                ? const Color(0xFF064E3B)
                                : AppColors.successContainer),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(budgetVm.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: budgetVm.isExceeded
                              ? (isDark
                                  ? const Color(0xFFFCA5A5)
                                  : AppColors.accentNeutral)
                              : (isDark
                                  ? const Color(0xFF6EE7B7)
                                  : AppColors.onSuccessContainer),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.wishlist);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: isDark ? AppColors.primary : AppColors.onPrimary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách mong muốn',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${wishlistVm.consideringCount} món đang cân nhắc'
                    '${wishlistVm.reviewDueCount > 0 ? ' · ${wishlistVm.reviewDueCount} cần xem lại' : ''}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recentList = purchaseVm.recentPurchases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Khoản mua gần đây [3]    Xem tất cả >
        Row(
          children: [
            Expanded(
              child: Text(
                'Khoản mua gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${recentList.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (onNavigateTab != null) onNavigateTab!(1); // Lịch sử
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.primary : AppColors.accentNeutral,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? AppColors.primary : AppColors.accentNeutral,
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
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: recentList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Chưa có khoản mua nào trong tháng này. Bấm "Ghi khoản mua" để bắt đầu.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: List.generate(recentList.length, (index) {
                    final item = recentList[index];
                    final isLast = index == recentList.length - 1;
                    return Column(
                      children: [
                        _buildPurchaseRow(context, item),
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
      ],
    );
  }

  Widget _buildPurchaseRow(BuildContext context, PurchaseItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final motivePalette = MotiveColors.of(context).paletteOf(item.motive);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.purchaseDetail,
          arguments: PurchaseDetailArgs(item),
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
                color: motivePalette.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.motive.icon,
                size: 20,
                color: motivePalette.foreground,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
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
                          color: motivePalette.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.motive.icon,
                              size: 11,
                              color: motivePalette.foreground,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.motive.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: motivePalette.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Timestamp
                      Text(
                        item.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Amount: e.g. 40.000 ₫
            Text(
              formatVnd(item.amountVnd),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primary : AppColors.accentNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
