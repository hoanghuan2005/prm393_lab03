import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../models/spending_insight.dart';
import '../theme/app_colors.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/insight_source_chip.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/state_view.dart';
import '../widgets/why_i_buy_logo.dart';
import '../widgets/app_header_actions.dart';

/// Screen 08: Góc nhìn (có AI) from Figma "Why I Buy ver2".
/// Numbers come from code; AI only rewrites the sentences (spec 7.6).
class InsightsScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;

  const InsightsScreen({super.key, this.onProfileTap, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final insightsVm = context.watch<InsightsViewModel>();
    final purchaseVm = context.watch<PurchaseViewModel>();
    final stats = insightsVm.stats;
    final report = insightsVm.report;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Trang chủ',
          onPressed: onBackTap,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            WhyIBuyLogo(
              size: 26,
              color: isDark ? AppColors.primary : AppColors.onPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              'Góc nhìn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          AppHeaderActions(onProfileTap: onProfileTap),
        ],
      ),
      body:
          stateView([
            purchaseVm.state,
          ], loadingMessage: 'Đang tải khoản mua...') ??
          RefreshIndicator(
            color: isDark ? AppColors.primary : AppColors.onPrimary,
            onRefresh: () => insightsVm.refresh(force: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildIntroHero(context),
                const SizedBox(height: 16),
                _buildMonthSelector(context, purchaseVm),
                const SizedBox(height: 12),
                _buildAiStatusCard(context, insightsVm),
                const SizedBox(height: 20),
                if (stats == null || report == null || !stats.hasPurchases)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyView(
                      title: 'Chưa có khoản mua nào trong tháng',
                      subtitle: 'Khi bạn ghi khoản mua kèm động cơ, Góc nhìn sẽ tổng hợp lại ở đây.',
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                  )
                else ...[
                  for (final card in report.cards) ...[
                    _InsightCardView(card: card),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.reflection),
                    icon: const Icon(Icons.auto_stories_outlined, size: 18),
                    label: const Text('Xem chiêm nghiệm tháng'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.primary : AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildIntroHero(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // A minimum height, not a fixed one: the text wraps at 360 dp and with larger fonts
    return Container(
      constraints: const BoxConstraints(minHeight: 306),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF24382D), Color(0xFF263746)]
              : const [Color(0xFFE6F1EC), Color(0xFFE8EEF7)],
        ),
        borderRadius: BorderRadius.circular(42),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF344A3D) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF263B31)
                          : const Color(0xFFE8F1ED),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 52,
                      color: isDark ? AppColors.primary : AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -2,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary : const Color(0xFF263B1E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF344A3D) : const Color(0xFFE6F1EC),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.self_improvement_rounded,
                    size: 20,
                    color: isDark ? AppColors.onPrimary : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF33483B)
                  : const Color(0xFFDCEBE3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '◉  Không gian an toàn tài chính',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'DÀNH RIÊNG CHO BẠN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Góc nhìn của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quan sát động cơ tiêu dùng của chính mình\nmà không cần tự trách.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
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
                );
                if (picked != null) purchaseVm.setSelectedMonth(picked);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formatMonthLabel(purchaseVm.selectedMonth),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
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
            onPressed: purchaseVm.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatusCard(BuildContext context, InsightsViewModel vm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2706) : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5E5410) : AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: isDark ? AppColors.primary : AppColors.aiAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dùng AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.primary : AppColors.onPrimary,
                  ),
                ),
              ),
              Switch(
                value: vm.canToggleAi && vm.userAiEnabled,
                activeThumbColor: AppColors.primary,
                // Must stand out from the primaryContainer box behind it
                activeTrackColor: isDark
                    ? AppColors.darkPrimaryContainerOutline
                    : AppColors.onPrimary,
                onChanged: vm.canToggleAi ? vm.setUserAiEnabled : null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.isGenerating) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 8),
                ],
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFFFEF3C7) : AppColors.textBody,
                  ),
                ),
                if (reason == InsightFallbackReason.aiFailed &&
                    !vm.isGenerating)
                  TextButton.icon(
                    onPressed: () => vm.refresh(force: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.primary : AppColors.onPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Chỉ gửi số liệu đã tổng hợp, động cơ và tên khoản lớn nhất. Không gửi ghi chú hay link.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? const Color(0xFF93B5CE) : AppColors.accentNeutral,
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

class _InsightCardView extends StatelessWidget {
  final InsightCard card;

  const _InsightCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = card.kind.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.kind.icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InsightSourceChip(fromAi: card.fromAi),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            card.body,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
