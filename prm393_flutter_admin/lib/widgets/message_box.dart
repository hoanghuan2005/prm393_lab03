import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'status_badge.dart';

enum MessageTone { info, error, success, warning }

/// Inline message with an icon, used for form errors and context notes.
class MessageBox extends StatelessWidget {
  final String message;
  final MessageTone tone;

  const MessageBox({
    super.key,
    required this.message,
    this.tone = MessageTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final (badge, icon) = switch (tone) {
      MessageTone.info => (BadgeTone.info, Icons.info_outline),
      MessageTone.error => (BadgeTone.error, Icons.error_outline),
      MessageTone.success => (BadgeTone.success, Icons.check_circle_outline),
      MessageTone.warning => (BadgeTone.warning, Icons.auto_awesome_outlined),
    };
    final (background, foreground) = toneColors(context, badge);
    return Semantics(
      liveRegion: tone == MessageTone.error,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppDimens.borderMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Short feedback after an action
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
