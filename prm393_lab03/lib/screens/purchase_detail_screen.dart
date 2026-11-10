import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/utils/time_slot.dart';
import '../models/budget_group.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/satisfaction_dialog.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 05: Chi tiết khoản mua from Figma "Why I Buy ver2"
class PurchaseDetailScreen extends StatelessWidget {
  final PurchaseItem purchase;

  const PurchaseDetailScreen({super.key, required this.purchase});

  /// Describes the recorded data only (motive, time, budget group); no advice (D11)
  String _describe(PurchaseItem item) {
    final slot = TimeSlot.fromDateTime(item.occurredAt);
    final group = defaultBudgetGroups
        .firstWhere(
          (g) => g.id == item.budgetGroupId,
          orElse: () => defaultBudgetGroups.last,
        )
        .name;
    return 'Bạn ghi khoản này với động cơ ${item.motive.label}, '
        'vào buổi ${slot.label.toLowerCase()} lúc ${formatTime(item.occurredAt)}, '
        'thuộc nhóm ngân sách $group.';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final linked = purchase.wishlistItemId != null;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoá khoản mua này?',
      message:
          'Xoá "${purchase.title}"? Khoản này sẽ không còn được tính vào đã chi của tháng.'
          '${linked ? '\n\nMón tương ứng trong danh sách mong muốn sẽ trở về "Đang cân nhắc".' : ''}',
      confirmLabel: 'Xoá',
      isDanger: true,
    );
    if (!confirmed || !context.mounted) return;
    await _delete(context);
  }

  /// Leaves the screen only after the delete succeeded; a failure offers "Thử lại"
  Future<void> _delete(BuildContext context) async {
    final purchaseVm = context.read<PurchaseViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await purchaseVm.deletePurchase(purchase.id);
    messenger.hideCurrentSnackBar();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(purchaseVm.actionError ?? 'Chưa xoá được khoản mua.'),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: context.mounted
              ? SnackBarAction(
                  label: 'Thử lại',
                  onPressed: () {
                    if (context.mounted) _delete(context);
                  },
                )
              : null,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xoá khoản mua "${purchase.title}".'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch in case item is updated in real-time
    final purchaseVm = context.watch<PurchaseViewModel>();
    final currentItem = purchaseVm.allPurchases.firstWhere(
      (p) => p.id == purchase.id,
      orElse: () => purchase,
    );

    final theme = Theme.of(context);

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
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Chi tiết khoản mua',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppSemanticColors.of(context).error,
            ),
            tooltip: 'Xoá khoản mua',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Purchase Summary (Figma 05)
                    _buildSummaryCard(context, currentItem),

                    const SizedBox(height: AppDimens.space16),

                    // Card 2: Details (Time & Note)
                    _buildDetailsCard(context, currentItem),

                    const SizedBox(height: AppDimens.space16),

                    // Card 3: Behavioral Insight
                    _buildBehavioralCard(context, currentItem),

                    const SizedBox(height: AppDimens.space16),

                    // A-16: how the purchase turned out, 1–5 stars
                    _SatisfactionCard(purchase: currentItem),
                  ],
                ),
              ),
            ),

            // Bottom Bar with "Sửa" Button
            _buildBottomBar(context, currentItem),
          ],
        ),
      ),
    );
  }

  // ==================== PURCHASE SUMMARY CARD ====================
  Widget _buildSummaryCard(BuildContext context, PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
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
          // Header: MỤC ĐÃ CHI TIÊU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MỤC ĐÃ CHI TIÊU',
                style: AppTextStyles.caption.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppSemanticColors.of(context).textSecondary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MotiveColors.of(context)
                      .paletteOf(item.motive)
                      .background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.motive.icon,
                  size: 18,
                  color: MotiveColors.of(context)
                      .paletteOf(item.motive)
                      .foreground,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space8),

          // Title
          Text(
            item.title,
            style: AppTextStyles.headlineMedium.withInheritedColor.copyWith(
              fontWeight: FontWeight.w700,
              color: AppSemanticColors.of(context).textPrimary,
            ),
          ),

          const SizedBox(height: AppDimens.space6),

          // Big Amount
          Text(
            item.formattedAmount,
            style: AppTextStyles.displayLarge.withInheritedColor.copyWith(
              fontWeight: FontWeight.w700,
              color: AppSemanticColors.of(context).accent,
              letterSpacing: -0.5,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
            child: Divider(
              height: 1,
              color: AppSemanticColors.of(context).mutedSurface,
            ),
          ),

          // Motive Row
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Động cơ',
                style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppSemanticColors.of(context).textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space12,
                  vertical: AppDimens.space4,
                ),
                decoration: BoxDecoration(
                  color: MotiveColors.of(context)
                      .paletteOf(item.motive)
                      .background,
                  borderRadius: AppDimens.borderPill,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.motive.icon,
                      size: 14,
                      color: MotiveColors.of(context)
                          .paletteOf(item.motive)
                          .foreground,
                    ),
                    const SizedBox(width: AppDimens.space6),
                    Text(
                      item.motive.label,
                      style: AppTextStyles.labelMedium.withInheritedColor
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: MotiveColors.of(context)
                                .paletteOf(item.motive)
                                .foreground,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DETAILS CARD ====================
  Widget _buildDetailsCard(BuildContext context, PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
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
          // Time Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).mutedSurface,
                  borderRadius: AppDimens.borderMedium,
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: AppSemanticColors.of(context).accent,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian ghi nhận',
                      style: AppTextStyles.labelMedium.withInheritedColor
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppSemanticColors.of(context).textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppDimens.space2),
                    Text(
                      formatRelativeDateTime(item.occurredAt),
                      style: AppTextStyles.bodyLarge.withInheritedColor
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppSemanticColors.of(context).textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppDimens.space2),
                    Text(
                      formatWeekdayDate(item.occurredAt),
                      style: AppTextStyles.labelMedium.withInheritedColor
                          .copyWith(
                            color: AppSemanticColors.of(context).textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
            child: Divider(
              height: 1,
              color: AppSemanticColors.of(context).mutedSurface,
            ),
          ),

          // Note Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).primaryContainer,
                  borderRadius: AppDimens.borderMedium,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppSemanticColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi chú của bạn',
                      style: AppTextStyles.labelMedium.withInheritedColor
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppSemanticColors.of(context).textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppDimens.space6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.of(context).background,
                        borderRadius: AppDimens.borderMedium,
                        border: Border.all(
                          color: AppSemanticColors.of(context).cardBorder,
                        ),
                      ),
                      child: Text(
                        (item.note != null && item.note!.trim().isNotEmpty)
                            ? '“${item.note!.trim()}”'
                            : 'Không có ghi chú thêm',
                        style: AppTextStyles.bodyMedium.withInheritedColor
                            .copyWith(
                              fontStyle:
                                  (item.note != null &&
                                      item.note!.trim().isNotEmpty)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color:
                                  (item.note != null &&
                                      item.note!.trim().isNotEmpty)
                                  ? AppColors.onPrimary
                                  : AppSemanticColors.of(context).hint,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== BEHAVIORAL INSIGHT CARD ====================
  Widget _buildBehavioralCard(BuildContext context, PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).primaryContainer,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            size: 22,
            color: AppSemanticColors.of(context).textPrimary,
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Góc nhìn Why I Buy',
                  style: AppTextStyles.bodyMedium.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.of(context).textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  _describe(item),
                  style: AppTextStyles.labelMedium.withInheritedColor.copyWith(
                    color: AppSemanticColors.of(context).accent,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _buildBottomBar(BuildContext context, PurchaseItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space20,
        AppDimens.space12,
        AppDimens.space20,
        AppDimens.space16,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        border: Border(
          top: BorderSide(
            color: AppSemanticColors.of(context).cardBorder,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: AppDimens.borderPill,
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.recordPurchase,
              arguments: RecordPurchaseArgs(existingPurchase: item),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: AppDimens.space8),
              Text(
                'Sửa khoản mua',
                style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stars given 7 days after the purchase (A-16); can be given or changed any time here
class _SatisfactionCard extends StatelessWidget {
  final PurchaseItem purchase;

  const _SatisfactionCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final stars = purchase.satisfaction;
    return Container(
      key: const ValueKey('purchase-satisfaction'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mức hài lòng',
                  style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                Semantics(
                  label: stars == null ? 'Chưa chấm' : '$stars trên 5 sao',
                  child: ExcludeSemantics(
                    child: Text(
                      stars == null
                          ? (purchase.satisfactionSkipped
                                ? 'Bạn đã bỏ qua câu hỏi này'
                                : 'Chưa chấm')
                          : '★' * stars + '☆' * (5 - stars),
                      style: AppTextStyles.bodyLarge.withInheritedColor
                          .copyWith(
                            color: MotiveColors.of(context)
                                .paletteOf(BuyingMotive.sale)
                                .foreground,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => SatisfactionDialog.ask(context, purchase),
            child: Text(stars == null ? 'Chấm' : 'Sửa'),
          ),
        ],
      ),
    );
  }
}
