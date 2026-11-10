import 'package:flutter/material.dart';

import '../../theme/app_dimens.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';

/// Standard Error View with Retry Button per Lab 3 requirement (Section 5)
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryTitle;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryTitle = 'Thử lại',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Thông báo lỗi: $message',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).error
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 38,
                  color: AppSemanticColors.of(context).error,
                ),
              ),
              const SizedBox(height: AppDimens.space20),
              Text(
                'Đã xảy ra sự cố',
                style: AppTextStyles.titleMedium.themed(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.themed(context),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimens.space24),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDimens.minTouchTarget,
                    minWidth: 140,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(retryTitle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
