import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';

/// Screen 05: Chi tiết khoản mua from Figma "Why I Buy ver2"
class PurchaseDetailScreen extends StatelessWidget {
  final PurchaseItem purchase;

  const PurchaseDetailScreen({super.key, required this.purchase});

  String _getBehavioralInsight(BuyingMotive motive) {
    switch (motive) {
      case BuyingMotive.sale:
        return 'Khoản mua do Khuyến mãi thường dễ bị kích thích bởi hiệu ứng sợ bỏ lỡ (FOMO). Hãy thử áp dụng quy tắc chờ 48 giờ cho lần săn sale kế tiếp.';
      case BuyingMotive.emotion:
        return 'Khoản mua mang tính giải tỏa Cảm xúc. Nhận diện được cảm xúc lúc mua sắm là bước đầu tiên để kiểm soát thói quen tiêu dùng bốc đồng.';
      case BuyingMotive.social:
        return 'Bạn đưa ra quyết định mua do Ảnh hưởng MXH. Hãy tự hỏi: món đồ này thực sự hữu ích với lối sống của bạn hay chỉ trông đẹp trên mạng?';
      case BuyingMotive.ads:
        return 'Món hàng này xuất phát từ Quảng cáo nhắm mục tiêu. Thuật toán cá nhân hóa rất giỏi tạo ra mong muốn tức thì.';
      case BuyingMotive.convenience:
        return 'Khoản chi Tiện lợi giúp tiết kiệm thời gian và công sức. Cân nhắc xem tính tiện lợi này có hoàn toàn xứng đáng với mức giá không.';
      case BuyingMotive.want:
        return 'Đây là một Mong muốn cá nhân. Đưa món đồ vào Wishlist 7 ngày là cách tốt nhất để xác thực mong muốn này có bền vững không.';
      case BuyingMotive.need:
        return 'Khoản chi Nhu cầu thiết yếu cho sinh hoạt hằng ngày. Bạn đang duy trì kỷ luật chi tiêu rất tốt.';
      case BuyingMotive.other:
        return 'Khoản chi phát sinh khác. Việc ghi chép đều đặn giúp bạn có cái nhìn tổng quan minh bạch về tài chính cá nhân.';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Xoá khoản mua này?'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xoá "${purchase.title}" không? Khoản tiền này sẽ được khấu trừ khỏi tổng chi tiêu tháng.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx); // close dialog
              final purchaseVm = context.read<PurchaseViewModel>();
              await purchaseVm.deletePurchase(purchase.id);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xoá khoản mua "${purchase.title}"'),
                  backgroundColor: AppColors.onPrimary,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              Navigator.of(context).pop(); // pop back to list
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
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
            '${item.formattedAmount} ₫',
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
                  _getBehavioralInsight(item.motive),
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
