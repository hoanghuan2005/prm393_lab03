import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/utils/time_slot.dart';
import '../models/budget_group.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/confirm_dialog.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết khoản mua',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Purchase Summary (Figma 05)
                    _buildSummaryCard(currentItem),

                    const SizedBox(height: 16),

                    // Card 2: Details (Time & Note)
                    _buildDetailsCard(currentItem),

                    const SizedBox(height: 16),

                    // Card 3: Behavioral Insight
                    _buildBehavioralCard(currentItem),
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
  Widget _buildSummaryCard(PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          // Header: MỤC ĐÃ CHI TIÊU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MỤC ĐÃ CHI TIÊU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.motive.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.motive.icon,
                  size: 18,
                  color: item.motive.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // Big Amount
          Text(
            item.formattedAmount,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.accentNeutral,
              letterSpacing: -0.5,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),

          // Motive Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Động cơ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.motive.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.motive.icon, size: 14, color: item.motive.color),
                    const SizedBox(width: 5),
                    Text(
                      item.motive.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: item.motive.color,
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
  Widget _buildDetailsCard(PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          // Time Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: AppColors.accentNeutral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thời gian ghi nhận',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeDateTime(item.occurredAt),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatWeekdayDate(item.occurredAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),

          // Note Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi chú của bạn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        (item.note != null && item.note!.trim().isNotEmpty)
                            ? '“${item.note!.trim()}”'
                            : 'Không có ghi chú thêm',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontStyle:
                              (item.note != null &&
                                  item.note!.trim().isNotEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color:
                              (item.note != null &&
                                  item.note!.trim().isNotEmpty)
                              ? AppColors.onPrimary
                              : AppColors.textHint,
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
  Widget _buildBehavioralCard(PurchaseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 22,
            color: AppColors.onPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Góc nhìn Why I Buy',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _describe(item),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.accentNeutral,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
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
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.recordPurchase,
              arguments: RecordPurchaseArgs(existingPurchase: item),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text(
                'Sửa khoản mua',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
