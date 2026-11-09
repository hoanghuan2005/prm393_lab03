import 'package:flutter/material.dart';

import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';

/// Reusable Motive Chip for the 8 Buying Motives.
/// Tappable chips always get a 48dp touch target; [isCompact] only shrinks display-only chips.
class MotiveChip extends StatelessWidget {
  final BuyingMotive motive;
  final bool isSelected;
  final ValueChanged<BuyingMotive>? onSelected;
  final bool isCompact;

  const MotiveChip({
    super.key,
    required this.motive,
    this.isSelected = false,
    this.onSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Theme palette: same colours as before in light mode, deep hues in dark mode
    final palette = MotiveColors.of(context).paletteOf(motive);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected ? palette.foreground : palette.background;
    final fgColor = isSelected
        ? (isDark ? AppColors.textPrimary : AppColors.textOnDark)
        : palette.foreground;
    final isInteractive = onSelected != null;

    return Semantics(
      button: isInteractive,
      selected: isSelected,
      label: 'Động cơ: ${motive.label}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isInteractive || !isCompact
              ? AppDimens.minTouchTarget
              : 32,
        ),
        child: InkWell(
          onTap: onSelected != null ? () => onSelected!(motive) : null,
          borderRadius: AppDimens.borderPill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppDimens.space12 : AppDimens.space16,
              vertical: isCompact ? AppDimens.space4 : AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppDimens.borderPill,
              border: Border.all(
                color: isSelected
                    ? palette.foreground
                    : palette.foreground.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(motive.icon, size: isCompact ? 16 : 18, color: fgColor),
                const SizedBox(width: AppDimens.space6),
                Text(
                  motive.label,
                  style:
                      (isCompact
                              ? AppTextStyles.labelMedium
                              : AppTextStyles.labelLarge)
                          .copyWith(
                            color: fgColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
