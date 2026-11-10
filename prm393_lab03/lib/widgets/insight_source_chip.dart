import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// Tells the user whether a sentence was written by AI or is the built-in template
class InsightSourceChip extends StatelessWidget {
  final bool fromAi;

  const InsightSourceChip({super.key, required this.fromAi});

  @override
  Widget build(BuildContext context) {
    final foreground = fromAi
        ? AppSemanticColors.of(context).onAiContainer
        : AppSemanticColors.of(context).textBody;
    // One label for screen readers; the visible "AI"/"Câu mẫu" text is not read again
    return Semantics(
      label: fromAi ? 'Do AI viết' : 'Câu mẫu',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: BoxDecoration(
          color: fromAi
              ? AppSemanticColors.of(context).aiContainer
              : AppSemanticColors.of(context).mutedSurface,
          borderRadius: AppDimens.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fromAi ? Icons.auto_awesome : Icons.notes_rounded,
              size: 12,
              color: foreground,
            ),
            const SizedBox(width: AppDimens.space4),
            Text(
              fromAi ? 'AI' : 'Câu mẫu',
              style: AppTextStyles.caption.withInheritedColor.copyWith(
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
