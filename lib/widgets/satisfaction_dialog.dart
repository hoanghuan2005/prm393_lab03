import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/purchase_viewmodel.dart';

/// Screen 27 / A-16: "Bạn thấy thế nào?" 1–5 stars with "Bỏ qua" (27.1), then thanks (27.2).
/// Answers feed Góc nhìn "hài lòng theo động cơ" and the sale plan score.
class SatisfactionDialog {
  SatisfactionDialog._();

  /// Asks, saves and thanks. Dismissing the dialog asks again another day;
  /// "Bỏ qua" stops asking for this purchase.
  static Future<void> ask(BuildContext context, PurchaseItem purchase) async {
    final vm = context.read<PurchaseViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final answer = await showDialog<({int? stars})>(
      context: context,
      builder: (_) => _SatisfactionDialog(purchase: purchase),
    );
    if (answer == null) return;
    // "Bỏ qua" on an already rated purchase keeps the rating
    if (answer.stars == null && purchase.satisfaction != null) return;
    final ok = await vm.rateSatisfaction(purchase, answer.stars);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            !ok
                ? vm.actionError ?? 'Chưa lưu được. Vui lòng thử lại.'
                : answer.stars == null
                ? 'Đã bỏ qua. App sẽ không hỏi lại về khoản này.'
                : 'Cảm ơn bạn! Góc nhìn sẽ dùng câu trả lời này.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SatisfactionDialog extends StatefulWidget {
  final PurchaseItem purchase;

  const _SatisfactionDialog({required this.purchase});

  @override
  State<_SatisfactionDialog> createState() => _SatisfactionDialogState();
}

class _SatisfactionDialogState extends State<_SatisfactionDialog> {
  late int? _stars = widget.purchase.satisfaction;

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.borderXLarge),
      title: const Text('Bạn thấy thế nào về khoản mua này?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.title, style: AppTextStyles.titleMedium),
          Text(
            '${formatDate(p.occurredAt)} · ${formatVnd(p.amountVnd)} · ${p.motive.label}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: ValueKey('satisfaction-$i'),
                  tooltip: '$i sao',
                  iconSize: 32,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    _stars != null && i <= _stars!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.motiveSale,
                  ),
                ),
            ],
          ),
          Text(
            'Câu trả lời chỉ dùng để Góc nhìn cho bạn thấy mức hài lòng theo động cơ.',
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (stars: null)),
          child: const Text('Bỏ qua'),
        ),
        ElevatedButton(
          onPressed: _stars == null
              ? null
              : () => Navigator.pop(context, (stars: _stars)),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
