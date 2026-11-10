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
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 06: Lịch sử from Figma "Why I Buy ver2"
class HistoryScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;

  const HistoryScreen({super.key, this.onProfileTap, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Trang chủ',
          onPressed: onBackTap,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Lịch sử',
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
        actions: [AppHeaderActions(onProfileTap: onProfileTap)],
      ),
      body:
          stateView([
            purchaseVm.state,
          ], loadingMessage: 'Đang tải lịch sử...') ??
          Column(
            children: [
              // Period Selector: < Tháng MM/YYYY > (Fully Interactive)
              Container(
                padding: const EdgeInsets.only(
                  left: AppDimens.space16,
                  right: AppDimens.space16,
                  top: AppDimens.space6,
                  bottom: 0,
                ),
                color: theme.scaffoldBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Tháng trước',
                      onPressed: () => purchaseVm.previousMonth(),
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await MonthPickerSheet.show(
                          context,
                          selectedMonth,
                          lastMonth: DateTime.now(),
                        );
                        if (picked != null) {
                          purchaseVm.setSelectedMonth(picked);
                        }
                      },
                      borderRadius: AppDimens.borderMedium,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: AppDimens.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space12,
                          vertical: AppDimens.space4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: AppDimens.space8),
                            Text(
                              monthLabel,
                              style: AppTextStyles.bodyLarge.withInheritedColor
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(width: AppDimens.space4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Tháng sau',
                      onPressed: purchaseVm.canGoToNextMonth
                          ? purchaseVm.nextMonth
                          : null,
                    ),
                  ],
                ),
              ),

              // Motive Filter Chips (Horizontal scroll)
              Container(
                height:
                    MediaQuery.textScalerOf(context)
                        .scale(AppDimens.minTouchTarget) +
                    AppDimens.space8,
                color: theme.scaffoldBackgroundColor,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                    vertical: AppDimens.space4,
                  ),
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'Tất cả',
                      isSelected: !purchaseVm.hasActiveFilter,
                      onTap: purchaseVm.clearFilters,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    // Spec A-10: purchases that came from a Wishlist decision
                    _buildFilterChip(
                      context,
                      key: const ValueKey('history-from-wishlist'),
                      label: 'Mua từ danh sách',
                      icon: Icons.bookmark_border_rounded,
                      isSelected: purchaseVm.fromWishlistOnly,
                      onTap: () => purchaseVm.setFromWishlistOnly(
                        !purchaseVm.fromWishlistOnly,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    ...BuyingMotive.values.map((motive) {
                      final isSelected =
                          purchaseVm.selectedMotiveFilter == motive;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimens.space8),
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

              const SizedBox(height: AppDimens.space8),

              // Main Scroll Area with Budget Meter & Purchases
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.space16,
                    AppDimens.space8,
                    AppDimens.space16,
                    AppDimens.space16,
                  ),
                  children: [
                    // 1. Monthly Budget Meter Card (Figma "31 Ngân sách theo nhóm")
                    _buildBudgetMeterCard(context),

                    const SizedBox(height: AppDimens.space16),

                    // 2. Day Grouped Purchases or Empty State
                    if (purchases.isEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.space24,
                          50,
                          AppDimens.space24,
                          AppDimens.space24,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: AppDimens.space12),
                            Text(
                              purchaseVm.hasActiveFilter
                                  ? 'Không có khoản chi nào khớp bộ lọc trong $monthLabel'
                                  : 'Không có khoản chi nào trong $monthLabel',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.withInheritedColor
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: AppDimens.space4),
                            Text(
                              purchaseVm.hasActiveFilter
                                  ? 'Chọn "Tất cả" để xem mọi khoản mua của tháng.'
                                  : 'Nhấn nút "+" bên dưới để ghi nhận khoản mua sắm mới.',
                              style: AppTextStyles
                                  .labelMedium
                                  .withInheritedColor
                                  .copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
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
                                vertical: AppDimens.space8,
                                horizontal: AppDimens.space4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDayHeader(dateKey),
                                      style: AppTextStyles
                                          .bodyMedium
                                          .withInheritedColor
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.space8),
                                  Text(
                                    formatVnd(dayTotal),
                                    style: AppTextStyles
                                        .bodyMedium
                                        .withInheritedColor
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppSemanticColors.of(context)
                                              .accent,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            // Day Purchases Card
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppDimens.borderLarge,
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                children: List.generate(dayItems.length, (i) {
                                  final item = dayItems[i];
                                  final isLast = i == dayItems.length - 1;
                                  return Column(
                                    children: [
                                      Material(
                                        type: MaterialType.transparency,
                                        child: _buildHistoryRow(
                                          context,
                                          item,
                                          purchaseVm,
                                        ),
                                      ),
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

                            const SizedBox(height: AppDimens.space16),
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
  Widget _buildBudgetMeterCard(BuildContext context) {
    final theme = Theme.of(context);
    final budgetVm = context.watch<BudgetViewModel>();
    final spent = budgetVm.limitedSpent;
    final budget = budgetVm.totalLimit;
    final progress = budgetVm.progress;
    final isExceeded = budgetVm.isExceeded;

    // No limit set: say so (as Trang chủ does) instead of "0 ₫ · Trong hạn mức"
    if (budget <= 0) {
      return Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: const ValueKey('history-budget-unset'),
          leading: Icon(
            Icons.account_balance_wallet_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: const Text('Ngân sách tháng: chưa đặt'),
          subtitle: const Text(
            'Đặt mốc cho từng nhóm để so với số đã chi. App không chặn mua.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.budget),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(
          color: isExceeded
              ? (AppSemanticColors.of(context).secondaryActionBorder)
              : theme.dividerColor,
          width: isExceeded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppSemanticColors.of(context).budgetCardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Fixed overflow bug with Expanded + Flexible)
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space8,

                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppSemanticColors.of(context).accent,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    SizedBox(
                      child: Text(
                        'Ngân sách tháng',
                        style: AppTextStyles.bodyMedium.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space6),
                    // Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space6,
                        vertical: AppDimens.space2,
                      ),
                      decoration: BoxDecoration(
                        color: isExceeded
                            ? (AppSemanticColors.of(context).mutedSurface)
                            : (AppSemanticColors.of(context).successContainer),
                        borderRadius: AppDimens.borderSmall,
                      ),
                      child: Text(
                        isExceeded ? 'Đã vượt mốc' : 'Trong hạn mức',
                        style: AppTextStyles.caption.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: isExceeded
                                  ? (AppSemanticColors.of(context).accent)
                                  : (AppSemanticColors.of(context)
                                        .onSuccessContainer),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              // Edit button
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.budget);
                },
                borderRadius: AppDimens.borderSmall,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppDimens.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space6,
                    vertical: AppDimens.space4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppSemanticColors.of(context).accent,
                      ),
                      const SizedBox(width: AppDimens.space4),
                      Text(
                        'Chi tiết',
                        style: AppTextStyles.labelMedium.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppSemanticColors.of(context).accent,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space12),

          // Numbers Row: 817.000 ₫ / 2.000.000 ₫ (with overflow protection)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  formatVnd(spent),
                  style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.of(context).accent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Flexible(
                child: Text(
                  'Mục tiêu: ${formatVnd(budget)}',
                  style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space8),

          // Budget Meter Progress Bar
          ClipRRect(
            borderRadius: AppDimens.borderSmall,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppSemanticColors.of(context).mutedSurface,
              color: isExceeded
                  ? (AppSemanticColors.of(context).accent)
                  : AppColors.primary,
            ),
          ),

          const SizedBox(height: AppDimens.space6),

          // Explanatory note
          Text(
            isExceeded
                ? 'Đã vượt ${formatVnd(spent - budget)} so với mốc bạn đặt. Ứng dụng không chặn mua.'
                : 'Còn lại ${formatVnd(budget - spent)} trong ngân sách dự kiến tháng này.',
            style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    Key? key,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected
        ? (AppSemanticColors.of(context).selectedChip)
        : (AppSemanticColors.of(context).mutedSurface);

    final textColor = isSelected
        ? (AppSemanticColors.of(context).onSelectedChip)
        : (AppSemanticColors.of(context).mutedText);

    final iconColor = isSelected
        ? (AppSemanticColors.of(context).onSelectedChip)
        : (AppSemanticColors.of(context).textSecondary);

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: AppDimens.borderXLarge,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppDimens.borderXLarge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: AppDimens.space4),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
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
    final theme = Theme.of(context);
    final motivePalette = MotiveColors.of(context).paletteOf(item.motive);

    // Read as one item by TalkBack, including rows that have a note
    return MergeSemantics(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space4,
        ),
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
            color: motivePalette.background,
            borderRadius: AppDimens.borderMedium,
          ),
          child: Icon(
            item.motive.icon,
            size: 20,
            color: motivePalette.foreground,
          ),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.space2),
            Text(
              '${item.motive.label} • ${formatTime(item.occurredAt)}',
              style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.space2),
              Text(
                '"${item.note}"',
                style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppSemanticColors.of(context).captionText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          formatVnd(item.amountVnd),
          style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
            fontWeight: FontWeight.w700,
            color: AppSemanticColors.of(context).accent,
          ),
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
