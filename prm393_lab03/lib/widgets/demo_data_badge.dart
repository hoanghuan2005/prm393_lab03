import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

import '../theme/app_text_styles.dart';

/// "Dữ liệu mẫu": shown next to every sample product, price or chart (isDemo /
/// source 'demo') so it is never taken for real data. Colors follow the theme.
class DemoDataBadge extends StatelessWidget {
  static const label = 'Dữ liệu mẫu';

  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: AppDimens.borderPill,
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppDimens.space4),
            Text(
              label,
              style: AppTextStyles.caption
                  .themed(context)
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
