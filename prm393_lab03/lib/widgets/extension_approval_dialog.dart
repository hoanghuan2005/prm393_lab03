import 'package:flutter/material.dart';

import '../models/extension_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// "Cho phép … liên kết?" for a Chrome extension signed in with this account (handoff X4, 25f).
/// Đồng ý and Từ chối have equal weight; dismissing leaves the request pending until it expires.
class ExtensionApprovalDialog {
  ExtensionApprovalDialog._();

  /// true = approve, false = reject, null = dismissed without a choice
  static Future<bool?> ask(BuildContext context, ExtensionSession session) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderXLarge,
        ),
        icon: const Icon(Icons.computer_rounded, color: AppColors.onPrimary),
        title: Text('Cho phép ${session.deviceLabel} liên kết?'),
        content: Text(
          'Extension Why I Buy? trên máy tính sẽ xem và lưu được danh sách mong muốn '
          'của bạn. Bạn có thể huỷ liên kết bất cứ lúc nào trong Cá nhân.',
          style: AppTextStyles.bodyMedium.themed(context).copyWith(height: 1.4),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimens.minTouchTarget),
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimens.minTouchTarget),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
