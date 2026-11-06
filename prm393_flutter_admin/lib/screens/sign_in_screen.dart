import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_box.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final state = vm.state;
    final message = state is AuthSignedOut ? state.message : null;
    final signingIn = state is AuthSignedOut && state.signingIn;
    final t = context.tokens;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 64)),
                    const SizedBox(height: AppDimens.space20),
                    Text(
                      'Why I Buy · Quản trị',
                      textAlign: TextAlign.center,
                      style: t.text(AppTextStyles.headlineMedium),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      'Quản lý lịch sale, duyệt đề xuất của người dùng và gửi thông báo tới app.',
                      textAlign: TextAlign.center,
                      style: t.text(AppTextStyles.bodyMedium),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    if (message != null) ...[
                      MessageBox(tone: MessageTone.error, message: message),
                      const SizedBox(height: AppDimens.space16),
                    ],
                    AppButton(
                      title: 'Đăng nhập với Google',
                      icon: Icons.login,
                      isLoading: signingIn,
                      onPressed: vm.signIn,
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Text(
                      'Dành cho tài khoản có vai trò nhân viên (staff) hoặc quản trị viên (admin).',
                      textAlign: TextAlign.center,
                      style: t.text(AppTextStyles.labelMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
