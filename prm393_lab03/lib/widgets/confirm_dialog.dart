import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// Yes/no dialog with a "Huỷ" button. [isDanger] colors the confirm button with `error`
/// (deletes); otherwise it uses `primary` with `onPrimary` text.
class ConfirmDialog {
  ConfirmDialog._();

  /// true only when the user tapped the confirm button
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Đồng ý',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderXLarge,
        ),
        icon: isDanger
            ? Icon(
                Icons.warning_amber_rounded,
                color: AppSemanticColors.of(context).error,
              )
            : null,
        title: Text(title),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.themed(context).copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimens.minTouchTarget),
              backgroundColor: isDanger
                  ? AppSemanticColors.of(context).error
                  : AppColors.primary,
              foregroundColor: isDanger
                  ? AppSemanticColors.of(context).onStatusFill
                  : AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
