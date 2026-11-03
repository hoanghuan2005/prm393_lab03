import 'package:flutter/material.dart';

import '../core/constants/legal_texts.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Read-only text page: "Điều khoản sử dụng", "Chính sách quyền riêng tư"
class InfoTextScreen extends StatelessWidget {
  final InfoDocument document;

  const InfoTextScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
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
