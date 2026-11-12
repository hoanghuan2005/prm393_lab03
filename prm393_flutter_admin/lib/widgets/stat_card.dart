import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'status_badge.dart';

/// One dashboard figure: label, value, how it is computed, and an optional chip
/// (for example "Cần kích hoạt") that says what the number calls for.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final BadgeTone tone;
  final String? chip;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.tone = BadgeTone.primary,
    this.chip,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (iconBackground, iconColor) = toneColors(context, tone);
    return Semantics(
      container: true,
      label: [label, value, ?caption, ?chip].join('. '),
      child: ExcludeSemantics(
        child: Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: t.textSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius: AppDimens.borderMedium,
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space12),
                      Text(value, style: t.text(AppTextStyles.displayMedium)),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          caption ?? '',
                          style: t.text(AppTextStyles.bodyMedium),
                        ),
                      ),
                      if (chip != null) ...[
                        const SizedBox(width: AppDimens.space8),
                        StatusBadge(label: chip!, tone: tone),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
