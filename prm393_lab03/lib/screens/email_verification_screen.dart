import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    final email = authVm.user?.email ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 72,
                  ),
                  const SizedBox(height: AppDimens.space24),
                  Text(
                    'Xác minh email của bạn',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium
                        .themed(context)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    'Chúng mình đã gửi một đường dẫn xác minh đến:',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .themed(context)
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium
                        .themed(context)
                        .copyWith(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    'Mở email và bấm vào đường dẫn xác minh của Firebase. Sau đó quay lại đây để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .themed(context)
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  AppButton(
                    title: 'Tôi đã xác minh email',
                    icon: Icons.verified_rounded,
                    isLoading: _isChecking,
                    onPressed: _checkVerification,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  AppButton(
                    title: 'Gửi lại email xác minh',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.secondary,
                    isLoading: _isSending,
                    onPressed: _resendVerification,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  TextButton(
                    onPressed: authVm.signOut,
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final verified = await context
        .read<AuthViewModel>()
        .reloadEmailVerification();
    if (!mounted) return;
    setState(() => _isChecking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verified
              ? 'Email đã được xác minh.'
              : 'Email chưa được xác minh. Hãy mở đường dẫn trong email.',
        ),
      ),
    );
  }

  Future<void> _resendVerification() async {
    setState(() => _isSending = true);
    final sent = await context.read<AuthViewModel>().resendEmailVerification();
    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Đã gửi lại email xác minh.'
              : 'Không thể gửi email xác minh. Vui lòng thử lại.',
        ),
      ),
    );
  }
}
