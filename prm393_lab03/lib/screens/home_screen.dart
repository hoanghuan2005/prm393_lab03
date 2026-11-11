import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 02: Trang chủ from Figma "Why I Buy ver2"
class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  /// "Chào Tâm," when the account has a name; guests and email-only accounts get "Chào bạn,"
  static String _greeting(AuthViewModel? authVm) {
    final name = authVm == null || authVm.isAnonymous
        ? ''
        : authVm.displayName.trim();
    return name.isEmpty || name.contains('@') ? 'Chào bạn,' : 'Chào $name,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseVm = context.watch<PurchaseViewModel>();
    final wishlistVm = context.watch<WishlistViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // Home is the first tab: no "back to Trang chủ" arrow here
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Trang chủ',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [AppHeaderActions(onProfileTap: () => onNavigateTab?.call(4))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              _greeting(context.watch<AuthViewModel?>()),
              style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: AppDimens.space12),

            // Card 1: TỔNG QUAN THÁNG (selected month)
            _buildMonthSummaryCard(context, purchaseVm),

            const SizedBox(height: AppDimens.space16),

            // Card 2: Danh sách mong muốn entry
            _buildWishlistEntryCard(context, wishlistVm),

            const SizedBox(height: AppDimens.space24),

            // Section: Trước khi mua (Flow 9)
            _buildPrePurchaseEntry(context),

            const SizedBox(height: AppDimens.space24),

            // Section 3: Khoản mua gần đây
            _buildRecentPurchasesSection(context, purchaseVm),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shadowColor: AppSemanticColors.of(context).illustrationShadow,
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderPill,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.recordPurchase);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 20),
                const SizedBox(width: AppDimens.space8),
                Text(
                  'Ghi khoản mua',
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stacked bar of the month's motives, widest first, in each motive's own color
  List<Widget> _motiveSegments(
    BuildContext context,
    Map<BuyingMotive, double> distribution,
  ) {
    final theme = Theme.of(context);
    if (distribution.isEmpty) {
      return [
        Expanded(
          child: Container(color: theme.colorScheme.surfaceContainerHighest),
        ),
      ];
    }
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const SizedBox(width: AppDimens.space2),
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
    final budgetVm = context.watch<BudgetViewModel>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppSemanticColors.of(context).summaryCardShadow,
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
                  const SizedBox(width: AppDimens.space6),
                  Text(
                    'TỔNG QUAN THÁNG',
                    style: AppTextStyles.caption.withInheritedColor.copyWith(
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
                    lastMonth: DateTime.now(),
                  );
                  if (picked != null) {
                    purchaseVm.setSelectedMonth(picked);
                  }
                },
                borderRadius: AppDimens.borderPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space12,
                    vertical: AppDimens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppDimens.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMonthLabel(purchaseVm.selectedMonth),
                        style: AppTextStyles.labelMedium.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: AppDimens.space2),
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

          const SizedBox(height: AppDimens.space12),

          // Big Amount
          Text(
            formatVnd(purchaseVm.monthTotal),
            style: AppTextStyles.displayLarge.withInheritedColor.copyWith(
              fontWeight: FontWeight.w700,
              color: AppSemanticColors.of(context).accent,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: AppDimens.space4),

          // Count text
          Text(
            '${purchaseVm.monthCount} khoản trong tháng'
            '${purchaseVm.isCurrentMonthSelected ? ' · Tuần này: ${purchaseVm.weekCount} khoản (${formatVnd(purchaseVm.weekTotal)})' : ''}',
            style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppDimens.space4),

          // Highlight: Nhiều nhất: Khuyến mãi (2/5)
          Text.rich(
            TextSpan(
              text: 'Nhiều nhất: ',
              style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
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

          const SizedBox(height: AppDimens.space16),

          // Motive bar header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space4,
            children: [
              Text(
                'Động cơ chính',
                style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                purchaseVm.dominantMotiveText,
                style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space8),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: AppDimens.borderSmall,
            child: SizedBox(
              height: AppDimens.space8,
              child: Row(
                children: _motiveSegments(
                  context,
                  purchaseVm.motiveDistribution,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space12),
            child: Divider(height: 1, color: theme.dividerColor),
          ),

          // Monthly Budget Quick View
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.budget);
            },
            borderRadius: AppDimens.borderSmall,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space2),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: AppSemanticColors.of(context).accent,
                  ),
                  const SizedBox(width: AppDimens.space6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Ngân sách tháng: ',
                        style: AppTextStyles.labelMedium.withInheritedColor
                            .copyWith(
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
                        horizontal: AppDimens.space6,
                        vertical: AppDimens.space2,
                      ),
                      decoration: BoxDecoration(
                        color: budgetVm.isExceeded
                            ? (AppSemanticColors.of(context).mutedSurface)
                            : (AppSemanticColors.of(context).successContainer),
                        borderRadius: AppDimens.borderSmall,
                      ),
                      child: Text(
                        '${(budgetVm.progress * 100).toInt()}%',
                        style: AppTextStyles.caption.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: budgetVm.isExceeded
                                  ? (AppSemanticColors.of(context).accent)
                                  : (AppSemanticColors.of(context)
                                        .onSuccessContainer),
                            ),
                      ),
                    ),
                  const SizedBox(width: AppDimens.space4),
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

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.wishlist);
      },
      borderRadius: AppDimens.borderLarge,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppDimens.borderLarge,
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: AppSemanticColors.of(context).emphasis,
              size: 22,
            ),
            const SizedBox(width: AppDimens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách mong muốn',
                    style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space2),
                  Text(
                    '${wishlistVm.consideringCount} món đang cân nhắc'
                    '${wishlistVm.reviewDueCount > 0 ? ' · ${wishlistVm.reviewDueCount} cần xem lại' : ''}',
                    style: AppTextStyles.labelMedium.withInheritedColor
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
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

  // ==================== TRƯỚC KHI MUA ENTRY (Figma 02, Flow 9) ====================
  Widget _buildPrePurchaseEntry(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trước khi mua',
          style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        Text(
          'Dừng lại một chút. Vài câu hỏi nhanh giúp bạn hiểu điều gì đang '
          'thu hút mình.',
          style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Text(
          'Hiểu trước khi thay đổi.',
          style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('open-pre-purchase'),
              label: const Text('Trước khi mua'),
              avatar: const Icon(Icons.lightbulb_rounded, size: 18),
              backgroundColor: AppColors.primary,
              elevation: 1,
              pressElevation: 2,
              shadowColor: AppSemanticColors.of(context).illustrationShadow,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space6,
                vertical: AppDimens.space4,
              ),
              labelStyle: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: AppSemanticColors.of(context).budgetActionBorder,
                width: 1,
              ),
              iconTheme: const IconThemeData(color: AppColors.onPrimary),
              shape: const StadiumBorder(),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.prePurchase),
            ),
            // "Chụp để tìm": name an item from a photo, then add it to the wishlist
            ActionChip(
              key: const ValueKey('open-photo-search'),
              label: const Text('Chụp để tìm'),
              avatar: const Icon(Icons.photo_camera_rounded, size: 18),
              backgroundColor: AppColors.primary,
              elevation: 1,
              pressElevation: 2,
              shadowColor: AppSemanticColors.of(context).illustrationShadow,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space6,
                vertical: AppDimens.space4,
              ),
              labelStyle: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: AppSemanticColors.of(context).budgetActionBorder,
                width: 1,
              ),
              iconTheme: const IconThemeData(color: AppColors.onPrimary),
              shape: const StadiumBorder(),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.photoSearch),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== KHOẢN MUA GẦN ĐÂY SECTION ====================
  Widget _buildRecentPurchasesSection(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final theme = Theme.of(context);
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
                style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space8,
                vertical: AppDimens.space2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppDimens.borderPill,
              ),
              child: Text(
                '${recentList.length}',
                style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
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
                minimumSize: const Size(
                  AppDimens.minTouchTarget,
                  AppDimens.minTouchTarget,
                ),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppSemanticColors.of(context).accent,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppSemanticColors.of(context).accent,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimens.space12),

        // Purchases Card Container
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppDimens.borderLarge,
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: recentList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Text(
                    'Chưa có khoản mua nào trong tháng này. Bấm "Ghi khoản mua" để bắt đầu.',
                    style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
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
                          Divider(height: 1, color: theme.dividerColor),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        child: Row(
          children: [
            // Circular Motive Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: motivePalette.background,
                borderRadius: AppDimens.borderMedium,
              ),
              child: Icon(
                item.motive.icon,
                size: 20,
                color: motivePalette.foreground,
              ),
            ),
            const SizedBox(width: AppDimens.space12),

            // Content: Title + Chip + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Wrap(
                    spacing: AppDimens.space8,
                    runSpacing: AppDimens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Motive Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space6,
                          vertical: AppDimens.space2,
                        ),
                        decoration: BoxDecoration(
                          color: motivePalette.background,
                          borderRadius: AppDimens.borderSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.motive.icon,
                              size: 11,
                              color: motivePalette.foreground,
                            ),
                            const SizedBox(width: AppDimens.space4),
                            Text(
                              item.motive.label,
                              style: AppTextStyles.caption.withInheritedColor
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: motivePalette.foreground,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Timestamp
                      Text(
                        item.formattedTime,
                        style: AppTextStyles.labelMedium.withInheritedColor
                            .copyWith(
                              color: AppSemanticColors.of(context).subtleText,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    formatVnd(item.amountVnd),
                    style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppSemanticColors.of(context).accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
