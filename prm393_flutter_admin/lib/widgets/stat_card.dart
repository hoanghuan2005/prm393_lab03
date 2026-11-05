import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// One dashboard figure: label, value and how it is computed.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value${caption == null ? '' : '. $caption'}',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: AppDimens.borderMedium,
                      ),
                      child: Icon(icon, color: AppColors.onPrimary, size: 22),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space16),
                Text(value, style: AppTextStyles.displayMedium),
                if (caption != null) ...[
                  const SizedBox(height: AppDimens.space4),
                  Text(caption!, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
