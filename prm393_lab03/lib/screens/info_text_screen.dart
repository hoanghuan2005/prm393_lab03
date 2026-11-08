import 'package:flutter/material.dart';

import '../core/constants/legal_texts.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/why_i_buy_logo.dart';

/// Read-only text page: "Điều khoản sử dụng", "Chính sách quyền riêng tư"
class InfoTextScreen extends StatelessWidget {
  final InfoDocument document;

  const InfoTextScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                document.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.space16),
          children: [
            Text(
              'Cập nhật: ${document.updated}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              document.intro,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textBody,
              ),
            ),
            for (final section in document.sections) ...[
              const SizedBox(height: AppDimens.space24),
              Text(section.heading, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppDimens.space8),
              Text(
                section.body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textBody,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.space24),
          ],
        ),
      ),
    );
  }
}
