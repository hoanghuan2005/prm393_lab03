import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'amount_field.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';

/// "Cập nhật giá" (screen 22.2): the price the user sees now. Returns the amount, or
/// null when dismissed. Every saved price becomes a dated snapshot.
class PriceUpdateSheet {
  PriceUpdateSheet._();

  static Future<int?> show(
    BuildContext context, {
    int? currentPrice,
    DateTime? currentPriceAt,
  }) {
    return AppBottomSheet.show<int>(
      context,
      title: currentPrice == null ? 'Nhập giá' : 'Cập nhật giá',
      child: _PriceForm(
        currentPrice: currentPrice,
        currentPriceAt: currentPriceAt,
      ),
    );
  }
}

class _PriceForm extends StatefulWidget {
  final int? currentPrice;
  final DateTime? currentPriceAt;

  const _PriceForm({this.currentPrice, this.currentPriceAt});

  @override
  State<_PriceForm> createState() => _PriceFormState();
}

class _PriceFormState extends State<_PriceForm> {
  final _formKey = GlobalKey<FormState>();
  int? _amount;

  void _submit() {
    if (_formKey.currentState?.validate() != true || _amount == null) return;
    Navigator.pop(context, _amount);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentPrice;
    final at = widget.currentPriceAt;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            current == null
                ? 'Giá bạn đang thấy cho món này (đúng phân loại bạn định mua).'
                : 'Giá đã ghi: ${formatVnd(current)}'
                      '${at == null ? '' : ' (ngày ${formatDate(at)})'}. '
                      'Nhập giá bạn đang thấy; giá cũ vẫn được giữ trong lịch sử.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          AmountField(
            key: const ValueKey('price-update-amount'),
            label: 'Giá hiện tại *',
            hint: 'Ví dụ: 389.000',
            onChanged: (value) => _amount = value,
          ),
          const SizedBox(height: AppDimens.space24),
          AppButton(
            title: 'Lưu giá',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
