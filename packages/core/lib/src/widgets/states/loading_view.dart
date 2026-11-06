import 'package:flutter/material.dart';

import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// Standard Loading View with accessible Semantics
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      label: 'Đang tải dữ liệu',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  // Same as onPrimary in light mode; stays visible in dark mode
                  valueColor: AlwaysStoppedAnimation<Color>(t.textPrimary),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDimens.space16),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: t.text(AppTextStyles.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
