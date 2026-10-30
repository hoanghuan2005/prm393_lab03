import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Card with a title row (optional icon and trailing [action]), a divider and content
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? action;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDark ? AppColors.primary : AppColors.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: AppDimens.space8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          Divider(color: theme.dividerColor),
          const SizedBox(height: AppDimens.space12),
          ...children,
        ],
      ),
    );
  }
}
