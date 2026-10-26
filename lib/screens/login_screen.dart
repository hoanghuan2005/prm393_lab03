import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';

/// Screen for Authentication (Google Sign-In & Guest Mode)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo / Icon Header
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppDimens.borderXLarge,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_alt_outlined,
                    size: 48,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              Text(
                'Why I Buy',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                'The Psychology of Money',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimens.space12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: Text(
                  'Ghi lại vì sao bạn mua, cho mỗi món thêm thời gian cân nhắc, rồi nhìn lại theo 8 động cơ.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const Spacer(),

              // Error banner if any
              if (authVm.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimens.space12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimens.space8),
                      Expanded(
                        child: Text(
                          authVm.errorMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Google Sign-In Button
              AppButton(
                title: 'Đăng nhập với Google',
                icon: Icons.g_mobiledata,
                isLoading: authVm.status == AuthStatus.loading,
                onPressed: () async {
                  await authVm.signInWithGoogle();
                },
              ),
              const SizedBox(height: AppDimens.space12),

              // Guest mode / Test account option
              AppButton(
                title: 'Dùng thử chế độ Khách (Test)',
                variant: AppButtonVariant.secondary,
                isLoading: authVm.status == AuthStatus.loading,
                onPressed: () async {
                  await authVm.signInAnonymously();
                },
              ),
              const SizedBox(height: AppDimens.space12),

              // Directly explore Figma screens
              TextButton.icon(
                icon: const Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
                label: const Text(
                  'Xem màn hình Onboarding & Trang chủ Figma',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.onboarding);
                },
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}
