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
import '../widgets/why_i_buy_logo.dart';

/// Screen 08: Góc nhìn (có AI) from Figma "Why I Buy ver2".
/// Numbers come from code; AI only rewrites the sentences (spec 7.6).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insightsVm = context.watch<InsightsViewModel>();
    final purchaseVm = context.watch<PurchaseViewModel>();
    final stats = insightsVm.stats;
    final report = insightsVm.report;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            SizedBox(width: 8),
            Text(
              'Góc nhìn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.onPrimary,
        onRefresh: () => insightsVm.refresh(force: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMonthSelector(context, purchaseVm),
            const SizedBox(height: 12),
            _buildAiStatusCard(insightsVm),
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
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.border),
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

  Widget _buildMonthSelector(
    BuildContext context,
    PurchaseViewModel purchaseVm,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.accentNeutral,
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
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formatMonthLabel(purchaseVm.selectedMonth),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accentNeutral,
            ),
            tooltip: 'Tháng sau',
            onPressed: purchaseVm.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatusCard(InsightsViewModel vm) {
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
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.aiContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.aiAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nhận xét bằng AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              Switch(
                value: vm.canToggleAi && vm.userAiEnabled,
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
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textBody,
                  ),
                ),
                if (reason == InsightFallbackReason.aiFailed &&
                    !vm.isGenerating)
                  TextButton.icon(
                    onPressed: () => vm.refresh(force: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Chỉ gửi số liệu đã tổng hợp, động cơ và tên khoản lớn nhất. Không gửi ghi chú hay link.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.accentNeutral,
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
        return 'Bạn đã tắt AI. Đang hiện câu mẫu từ số liệu.';
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
    final color = card.kind.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.kind.icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
