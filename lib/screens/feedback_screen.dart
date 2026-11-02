import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/app_button.dart';

/// Cá nhân → Hỗ trợ & thông tin → "Gửi góp ý": báo lỗi hoặc đề xuất tính năng mới
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<SettingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await vm.sendFeedback(_controller.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã gửi góp ý. Cảm ơn bạn!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.select<SettingsViewModel, bool>(
      (vm) => vm.isSendingFeedback,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi góp ý')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.space16),
          children: [
            Text(
              'Báo lỗi hoặc đề xuất tính năng mới. Góp ý được lưu cùng tài khoản '
              'của bạn để nhóm phát triển đọc.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),
            TextField(
              key: const ValueKey('feedback-field'),
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              maxLength: FirestoreFeedbackService.maxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Bạn gặp lỗi gì, hay muốn app có thêm điều gì?',
                errorText: _error,
                filled: true,
                fillColor: AppColors.surface,
                border: const OutlineInputBorder(
                  borderRadius: AppDimens.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            AppButton(
              key: const ValueKey('send-feedback'),
              title: 'Gửi góp ý',
              icon: Icons.send_outlined,
              isLoading: isSending,
              onPressed: isSending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
