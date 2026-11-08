import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_box.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submitEmail() => context.read<AuthViewModel>().signInWithEmail(
    _email.text,
    _password.text,
  );

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
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _email,
                            hint: 'Email',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppDimens.space12),
                          AppTextField(
                            controller: _password,
                            hint: 'Mật khẩu',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_showPassword,
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    AppButton(
                      title: 'Đăng nhập',
                      icon: Icons.login,
                      isLoading: signingIn,
                      onPressed: _submitEmail,
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.space12,
                          ),
                          child: Text(
                            'hoặc',
                            style: t.text(AppTextStyles.labelMedium),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space16),
                    AppButton(
                      title: 'Đăng nhập với Google',
                      icon: Icons.account_circle_outlined,
                      variant: AppButtonVariant.secondary,
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
