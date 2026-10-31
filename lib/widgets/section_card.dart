import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// White card with a title row (optional icon and trailing [action]), a divider and content
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.divider),
      ),
      // Own Material so ListTile ink in [children] shows above the card's colour
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.onPrimary, size: 20),
                  const SizedBox(width: AppDimens.space8),
                ],
                Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
                ?action,
              ],
            ),
            const SizedBox(height: AppDimens.space12),
            const Divider(),
            const SizedBox(height: AppDimens.space12),
            ...children,
          ],
        ),
      ),
    );
  }
}
