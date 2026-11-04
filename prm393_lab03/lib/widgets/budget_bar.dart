import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Budget meter (handoff "Budget meter"): neutral colors; over the limit the bar stays
/// neutral and a line "Đã vượt …" is added — never red.
class BudgetBar extends StatelessWidget {
  final int spentVnd;
  final int limitVnd;

  /// Group name for the screen-reader label, e.g. "Công nghệ"
  final String? label;

  const BudgetBar({
    super.key,
    required this.spentVnd,
    required this.limitVnd,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final exceeded = limitVnd > 0 && spentVnd > limitVnd;
    final progress = limitVnd > 0 ? (spentVnd / limitVnd).clamp(0.0, 1.0) : 0.0;
    final remaining = limitVnd - spentVnd;
    final prefix = label == null ? '' : '$label: ';

    return Semantics(
      label:
          '$prefixđã chi ${formatVnd(spentVnd)} trên ${formatVnd(limitVnd)}, '
          '${exceeded ? 'đã vượt ${formatVnd(-remaining)}' : 'còn lại ${formatVnd(remaining)}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: AppDimens.borderPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: exceeded ? AppColors.accentNeutral : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Text(
            '${formatVnd(spentVnd)} / ${formatVnd(limitVnd)}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (exceeded) ...[
            const SizedBox(height: AppDimens.space2),
            Text(
              'Đã vượt ${formatVnd(-remaining)} so với mốc bạn đặt. App không chặn mua.',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentNeutral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
