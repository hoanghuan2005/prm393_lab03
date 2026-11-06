import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';
import '../viewmodels/users_viewmodel.dart';
import 'message_box.dart';

/// A personal message for one user's app inbox. [onSubmit] returns an error, or null.
class UserMessageDialog extends StatefulWidget {
  final String recipient;
  final Future<String?> Function(String title, String body) onSubmit;

  const UserMessageDialog({
    super.key,
    required this.recipient,
    required this.onSubmit,
  });

  /// true when the message was sent
  static Future<bool> show(
    BuildContext context, {
    required String recipient,
    required Future<String?> Function(String title, String body) onSubmit,
  }) async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          UserMessageDialog(recipient: recipient, onSubmit: onSubmit),
    );
    return sent ?? false;
  }

  @override
  State<UserMessageDialog> createState() => _UserMessageDialogState();
}

class _UserMessageDialogState extends State<UserMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSubmit(_title.text, _body.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhắn tin riêng'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tin nhắn hiện trong hộp thư của ${widget.recipient} trên app.',
                  style: context.tokens.text(AppTextStyles.bodyMedium),
                ),
                const SizedBox(height: AppDimens.space16),
                AppTextField(
                  label: 'Tiêu đề',
                  controller: _title,
                  validator: UsersViewModel.validateTitle,
                ),
                const SizedBox(height: AppDimens.space16),
                AppTextField(
                  label: 'Nội dung',
                  hint: 'Tối đa ${UsersViewModel.maxBody} ký tự',
                  controller: _body,
                  maxLines: 4,
                  validator: UsersViewModel.validateBody,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.space12),
                  MessageBox(tone: MessageTone.error, message: _error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        AppButton(
          title: 'Gửi',
          icon: Icons.send_outlined,
          width: 140,
          isLoading: _sending,
          onPressed: _submit,
        ),
      ],
    );
  }
}
