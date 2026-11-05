import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';

enum AuthMode { login, signup, forgotPassword }

/// Email authentication plus the existing Google, GitHub and guest options.
class LoginScreen extends StatefulWidget {
  final AuthMode mode;

  const LoginScreen({super.key, this.mode = AuthMode.login});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  bool get isSignup => widget.mode == AuthMode.signup;
  bool get isForgotPassword => widget.mode == AuthMode.forgotPassword;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    final isLoading = authVm.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBackButton(context),
                  const SizedBox(height: 18),
                  _buildBrandHeader(theme),
                  const SizedBox(height: 26),
                  Text(
                    _title,
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (authVm.errorMessage != null) ...[
                    _buildError(authVm.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (isSignup) ...[
                          _buildField(
                            controller: _nameController,
                            label: 'Họ tên',
                            hint: 'Tên bạn muốn được gọi',
                            icon: Icons.person_outline_rounded,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Hãy nhập tên của bạn.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Nhập email của bạn',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Hãy nhập email.';
                            }
                            if (!value.contains('@')) {
                              return 'Email chưa đúng định dạng.';
                            }
                            return null;
                          },
                        ),
                        if (!isForgotPassword) ...[
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            hint: isSignup ? 'Tạo mật khẩu' : 'Nhập mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              tooltip: 'Hiện hoặc ẩn mật khẩu',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Hãy nhập mật khẩu.';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu cần ít nhất 6 ký tự.';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (isSignup) ...[
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _confirmPasswordController,
                            label: 'Xác nhận mật khẩu',
                            hint: 'Nhập lại mật khẩu',
                            icon: Icons.lock_reset_outlined,
                            obscureText: _obscureConfirmation,
                            suffixIcon: IconButton(
                              tooltip: 'Hiện hoặc ẩn mật khẩu',
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                ? 'Mật khẩu xác nhận chưa khớp.'
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.mode == AuthMode.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                  AppButton(
                    title: _actionLabel,
                    icon: isForgotPassword
                        ? Icons.mark_email_read_outlined
                        : isSignup
                        ? Icons.person_add_alt_1_rounded
                        : Icons.login_rounded,
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  if (isForgotPassword)
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: const Text('Quay lại Đăng nhập'),
                    )
                  else ...[
                    _buildSwitchMode(context),
                    if (!isSignup) ...[
                      const SizedBox(height: 22),
                      _buildDivider(theme),
                      const SizedBox(height: 16),
                      AppButton(
                        title: 'Đăng nhập với Google',
                        icon: Icons.g_mobiledata,
                        isLoading: isLoading,
                        onPressed: () => authVm.signInWithGoogle(),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        title: 'Đăng nhập với GitHub',
                        icon: Icons.code_rounded,
                        variant: AppButtonVariant.secondary,
                        isLoading: isLoading,
                        onPressed: () => authVm.signInWithGithub(),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        title: 'Dùng thử chế độ Khách',
                        icon: Icons.person_outline_rounded,
                        variant: AppButtonVariant.secondary,
                        isLoading: isLoading,
                        onPressed: () => authVm.signInAnonymously(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  _buildTrustNote(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title => switch (widget.mode) {
    AuthMode.login => 'Chào bạn trở lại',
    AuthMode.signup => 'Tạo tài khoản',
    AuthMode.forgotPassword => 'Quên mật khẩu',
  };

  String get _subtitle => switch (widget.mode) {
    AuthMode.login => 'Tiếp tục hiểu mình qua những khoản mua, từng chút một.',
    AuthMode.signup =>
      'Bắt đầu hành trình hiểu thói quen mua sắm của bạn, theo cách nhẹ nhàng.',
    AuthMode.forgotPassword => 'Nhập email bạn dùng để đăng ký. Chúng mình sẽ gửi liên kết để đặt lại mật khẩu.',
  };

  String get _actionLabel => switch (widget.mode) {
    AuthMode.login => 'Đăng nhập',
    AuthMode.signup => 'Tạo tài khoản',
    AuthMode.forgotPassword => 'Gửi liên kết đặt lại',
  };

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.pushReplacementNamed(
          context,
          AppRoutes.onboarding,
        ),
        icon: const Icon(Icons.chevron_left_rounded, size: 24),
        label: const Text('Quay lại'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD166), AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.psychology_alt_rounded,
            color: AppColors.onPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Why I Buy?',
          style: AppTextStyles.titleLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchMode(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            isLogin ? AppRoutes.signup : AppRoutes.login,
          ),
          child: Text(isLogin ? 'Đăng ký' : 'Đăng nhập'),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }

  Widget _buildTrustNote(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.onPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hiểu mình, không phán xét\nMỗi khoản mua là một dịp để lắng nghe chính bạn.',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    bool success;

    if (isForgotPassword) {
      success = await authVm.sendPasswordReset(_emailController.text);
    } else if (isSignup) {
      success = await authVm.createAccount(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      success = await authVm.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted || !success) return;
    if (isForgotPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi email đặt lại mật khẩu. Hãy kiểm tra hộp thư.'),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
}
