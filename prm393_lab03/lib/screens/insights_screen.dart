import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../models/buying_motive.dart';
import '../models/spending_insight.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/reflection_viewmodel.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/insight_source_chip.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 08: Góc nhìn (có AI) from Figma "Why I Buy ver2".
/// Numbers come from code; AI only rewrites the sentences (spec 7.6).
class InsightsScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;

  const InsightsScreen({super.key, this.onProfileTap, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightsVm = context.watch<InsightsViewModel>();
    final purchaseVm = context.watch<PurchaseViewModel>();
    final reflectionVm = context.watch<ReflectionViewModel>();
    final stats = insightsVm.stats;
    final report = insightsVm.report;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
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
                'Góc nhìn',
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
          ], loadingMessage: 'Đang tải khoản mua...') ??
          RefreshIndicator(
            color: AppSemanticColors.of(context).emphasis,
            onRefresh: () => insightsVm.refresh(force: true),
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.space16),
              children: [
                _buildMonthSelector(context, purchaseVm),
                const SizedBox(height: AppDimens.space12),
                if (reflectionVm.goalForMonth case final goal?) ...[
                  _GoalCard(
                    goal: goal,
                    month: reflectionVm.month,
                    onEdit: () {
                      purchaseVm.setSelectedMonth(reflectionVm.previousMonth);
                      Navigator.pushNamed(context, AppRoutes.reflection);
                    },
                  ),
                  const SizedBox(height: AppDimens.space12),
                ],
                _buildAiStatusCard(context, insightsVm),
                const SizedBox(height: AppDimens.space20),
                if (stats == null || report == null || !stats.hasPurchases)
                  const Padding(
                    padding: EdgeInsets.only(top: AppDimens.space24),
                    child: EmptyView(
                      title: 'Chưa có khoản mua nào trong tháng',
                      subtitle: 'Khi bạn ghi khoản mua kèm động cơ, Góc nhìn sẽ tổng hợp lại ở đây.',
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                  )
                else
                  for (final card in report.cards) ...[
                    _InsightCardView(card: card),
                    const SizedBox(height: AppDimens.space16),
                  ],
                // Also for a month without purchases: the user may still have
                // skipped items to look back on and a goal to set
                if (stats == null || report == null || !stats.hasPurchases)
                  const SizedBox(height: AppDimens.space24),
                OutlinedButton.icon(
                  key: const ValueKey('open-reflection'),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.reflection),
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  label: const Text('Xem chiêm nghiệm tháng'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppSemanticColors.of(context).emphasis,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: theme.dividerColor),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppDimens.borderPill,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Tháng trước',
            onPressed: purchaseVm.previousMonth,
          ),
          Flexible(
            child: InkWell(
              onTap: () async {
                final picked = await MonthPickerSheet.show(
                  context,
                  purchaseVm.selectedMonth,
                  lastMonth: DateTime.now(),
                );
                if (picked != null) purchaseVm.setSelectedMonth(picked);
              },
              borderRadius: AppDimens.borderSmall,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Flexible(
                      child: Text(
                        formatMonthLabel(purchaseVm.selectedMonth),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildAiStatusCard(BuildContext context, InsightsViewModel vm) {
    final reason = vm.fallbackReason;
    final String status;
    if (vm.isGenerating) {
      status = 'Đang viết nhận xét từ số liệu của bạn...';
    } else if (reason != null) {
      status = fallbackMessage(reason);
    } else if (vm.report?.source == InsightSource.ai) {
      status = 'Lời nhận xét do AI viết lại từ số liệu app đã tính. AI không tạo ra con số mới.';
    } else {
      status = 'Đang hiện câu mẫu từ số liệu đã ghi.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space12,
        AppDimens.space8,
        AppDimens.space12,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).primaryContainer,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(
          color: AppSemanticColors.of(context).primaryContainerBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppSemanticColors.of(context).aiAccent,
                size: 24,
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  'Dùng AI',
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.of(context).emphasis,
                  ),
                ),
              ),
              Switch(
                value: vm.canToggleAi && vm.userAiEnabled,
                activeThumbColor: AppColors.primary,
                // Must stand out from the primaryContainer box behind it
                activeTrackColor: AppSemanticColors.of(context).switchTrack,
                onChanged: vm.canToggleAi ? vm.setUserAiEnabled : null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimens.space40,
              right: AppDimens.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.isGenerating) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: AppDimens.space8),
                ],
                Text(
                  status,
                  style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                    height: 1.4,
                    color: AppSemanticColors.of(context).aiBody,
                  ),
                ),
                if (reason == InsightFallbackReason.aiFailed &&
                    !vm.isGenerating)
                  TextButton.icon(
                    onPressed: () => vm.refresh(force: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppSemanticColors.of(context).emphasis,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  'Chỉ gửi số liệu đã tổng hợp, động cơ và tên khoản lớn nhất. Không gửi ghi chú hay link.',
                  style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                    height: 1.35,
                    color: AppSemanticColors.of(context).accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String fallbackMessage(InsightFallbackReason reason) {
    switch (reason) {
      case InsightFallbackReason.notEnoughData:
        return 'Cần ít nhất $kMinPurchasesForAi khoản mua trong tháng để AI nhận xét. Đang hiện câu mẫu từ số liệu.';
      case InsightFallbackReason.userTurnedOff:
        return 'Bạn đã tắt AI (cả gợi ý nhóm và món tương tự khi thêm món). Đang hiện câu mẫu từ số liệu.';
      case InsightFallbackReason.disabledRemotely:
        return 'Tính năng AI đang tạm tắt. Đang hiện câu mẫu từ số liệu.';
      case InsightFallbackReason.unsupportedPlatform:
        return 'AI chưa hỗ trợ trên nền tảng này. Đang hiện câu mẫu từ số liệu.';
      case InsightFallbackReason.aiFailed:
        return 'Chưa nhận được nhận xét hợp lệ từ AI. Đang hiện câu mẫu từ số liệu.';
    }
  }
}

/// The goal the user wrote in last month's reflection, shown during this month
class _GoalCard extends StatelessWidget {
  final String goal;
  final DateTime month;
  final VoidCallback onEdit;

  const _GoalCard({
    required this.goal,
    required this.month,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Container(
      key: const ValueKey('reflection-goal-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space12,
        AppDimens.space8,
        AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: semantic.cardSurface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: semantic.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: semantic.emphasis),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Text(
                  'Mục tiêu bạn đặt cho tháng ${month.month}',
                  style: AppTextStyles.titleMedium.themed(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.space8),
            child: Text(goal, style: AppTextStyles.bodyLarge.themed(context)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: semantic.emphasis,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Sửa mục tiêu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCardView extends StatelessWidget {
  final InsightCard card;

  const _InsightCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MotiveColors.of(context).paletteOf(switch (card.kind) {
      InsightKind.dominantMotive => BuyingMotive.sale,
      InsightKind.lateNight => BuyingMotive.need,
      InsightKind.monthOverMonth => BuyingMotive.social,
      InsightKind.largestPurchase => BuyingMotive.emotion,
      InsightKind.skippedItems => BuyingMotive.convenience,
      InsightKind.satisfactionByMotive => BuyingMotive.want,
    }).foreground;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: AppSemanticColors.of(context).insightOverlay.a,
                  ),
                  borderRadius: AppDimens.borderMedium,
                ),
                child: Icon(card.kind.icon, size: 20, color: color),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  card.title,
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              InsightSourceChip(fromAi: card.fromAi),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          Text(
            card.body,
            style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
