import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Standard Empty View when list/content is empty
class EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionTitle;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionTitle,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Danh sách trống: $title',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimens.space8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              if (actionTitle != null && onAction != null) ...[
                const SizedBox(height: AppDimens.space24),
                ElevatedButton(onPressed: onAction, child: Text(actionTitle!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
