import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../viewmodels/review_queue_viewmodel.dart';
import 'message_box.dart';

/// Reject a suggestion with a reason the user will read in their inbox.
/// Quick reasons fill the field in one tap. [onSubmit] returns an error, or null.
class ReasonDialog extends StatefulWidget {
  final String suggestionName;
  final Future<String?> Function(String reason) onSubmit;

  const ReasonDialog({
    super.key,
    required this.suggestionName,
    required this.onSubmit,
  });

  /// true when the suggestion was rejected
  static Future<bool> show(
    BuildContext context, {
    required String suggestionName,
    required Future<String?> Function(String reason) onSubmit,
  }) async {
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ReasonDialog(suggestionName: suggestionName, onSubmit: onSubmit),
    );
    return done ?? false;
  }

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(_reason.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối đề xuất'),
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
                  'Người gửi "${widget.suggestionName}" sẽ đọc lý do này trong hộp thư của app.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.space16),
                Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space8,
                  children: [
                    for (final reason in ReviewQueueViewModel.quickReasons)
                      ActionChip(
                        label: Text(reason),
                        onPressed: _saving
                            ? null
                            : () => setState(() => _reason.text = reason),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.space16),
                AppTextField(
                  label: 'Lý do',
                  hint: 'Chọn một lý do ở trên hoặc tự nhập',
                  controller: _reason,
                  maxLines: 3,
                  validator: ReviewQueueViewModel.validateReason,
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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        AppButton(
          title: 'Từ chối',
          variant: AppButtonVariant.danger,
          width: 160,
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
