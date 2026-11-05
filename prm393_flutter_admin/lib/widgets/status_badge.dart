import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

enum BadgeTone { neutral, success, warning, error, info, primary }

/// Small pill with a text label: the meaning never relies on colour alone.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (AppColors.surfaceVariant, AppColors.textBody),
      BadgeTone.success => (
        AppColors.successContainer,
        AppColors.onSuccessContainer,
      ),
      BadgeTone.warning => (AppColors.aiContainer, AppColors.onAiContainer),
      BadgeTone.error => (AppColors.errorContainer, AppColors.onErrorContainer),
      BadgeTone.info => (AppColors.infoContainer, AppColors.onInfoContainer),
      BadgeTone.primary => (AppColors.primaryContainer, AppColors.onPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppDimens.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppDimens.space4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
