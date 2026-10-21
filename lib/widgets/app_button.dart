import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Reusable App Button conforming to >=48dp touch target accessibility rule
class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide? side;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = AppColors.onPrimary;
        side = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.surface;
        fgColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.outline, width: 1.5);
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = AppColors.textOnDark;
        side = BorderSide.none;
        break;
    }

    final isInteractive = !isLoading && onPressed != null;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppDimens.minTouchTarget,
          minWidth: width ?? double.infinity,
        ),
        child: SizedBox(
          width: width,
          height: AppDimens.minTouchTarget,
          child: ElevatedButton(
            onPressed: isInteractive ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
              disabledForegroundColor: fgColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimens.borderPill,
                side: side,
              ),
              elevation: AppDimens.elevationNone,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: fgColor),
                        const SizedBox(width: AppDimens.space8),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(color: fgColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
