import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Modal sheet with 24 top corners, drag handle and title. The content scrolls and moves
/// above the keyboard.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXLarge),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimens.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: AppDimens.borderPill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space16,
                AppDimens.space16,
                AppDimens.space16,
                AppDimens.space8,
              ),
              child: Text(title, style: AppTextStyles.titleLarge),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.space16,
                  AppDimens.space8,
                  AppDimens.space16,
                  AppDimens.space24,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
