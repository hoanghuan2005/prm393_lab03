import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum MoneyTextSize { small, medium, large }

/// int VND → "389.000 ₫"; null → [emptyLabel] ("Chưa có giá"), never "0 ₫"
class MoneyText extends StatelessWidget {
  final int? amountVnd;
  final MoneyTextSize size;
  final Color? color;
  final String emptyLabel;

  const MoneyText(
    this.amountVnd, {
    super.key,
    this.size = MoneyTextSize.medium,
    this.color,
    this.emptyLabel = 'Chưa có giá',
  });

  TextStyle get _style => switch (size) {
    MoneyTextSize.small => AppTextStyles.labelLarge,
    MoneyTextSize.medium => AppTextStyles.titleMedium.copyWith(
      fontWeight: FontWeight.w700,
    ),
    MoneyTextSize.large => AppTextStyles.headlineLarge.copyWith(
      fontWeight: FontWeight.w800,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final amount = amountVnd;
    return Semantics(
      label: amount == null
          ? emptyLabel
          : '${formatVnd(amount).replaceAll(' ₫', '')} đồng',
      excludeSemantics: true,
      child: Text(
        formatVnd(amount, empty: emptyLabel),
        style: _style.copyWith(
          color: color ?? (amount == null ? AppColors.textSecondary : null),
        ),
      ),
    );
  }
}
