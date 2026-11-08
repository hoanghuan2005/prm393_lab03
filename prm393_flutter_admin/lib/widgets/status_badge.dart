import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

enum BadgeTone { neutral, success, warning, error, info, primary }

/// Container / text colours of a tone for the current brightness
(Color, Color) toneColors(BuildContext context, BadgeTone tone) {
  final t = AppTokens.of(context);
  return switch (tone) {
    BadgeTone.neutral => (t.surfaceMuted, t.textBody),
    BadgeTone.success => (t.successContainer, t.onSuccessContainer),
    BadgeTone.warning => (t.warningContainer, t.onWarningContainer),
    BadgeTone.error => (t.errorContainer, t.onErrorContainer),
    BadgeTone.info => (t.infoContainer, t.onInfoContainer),
    BadgeTone.primary => (t.primaryContainer, t.onPrimaryContainer),
  };
}

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
    final (background, foreground) = toneColors(context, tone);
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
