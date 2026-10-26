import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/formatters/money_format.dart';
import '../core/validators/validators.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// VND amount input: number keyboard, "389.000" grouping while typing, "₫" suffix,
/// clear button. Values are `int`; an empty optional field reports `null` (never 0).
class AmountField extends StatefulWidget {
  final String? label;
  final String? hint;
  final int? initialValue;
  final ValueChanged<int?>? onChanged;

  /// Empty allowed (e.g. price not known yet)
  final bool optional;
  final TextEditingController? controller;
  final bool enabled;

  const AmountField({
    super.key,
    this.label,
    this.hint = '0',
    this.initialValue,
    this.onChanged,
    this.optional = false,
    this.controller,
    this.enabled = true,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && _controller.text.isEmpty) {
      _controller.text = _VndInputFormatter.group(widget.initialValue!);
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimens.space8),
        ],
        TextFormField(
          enabled: widget.enabled,
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [_VndInputFormatter()],
          style: AppTextStyles.bodyLarge,
          validator: widget.optional
              ? Validators.validateOptionalAmount
              : Validators.validateAmount,
          onChanged: (text) => widget.onChanged?.call(parseVnd(text)),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixText: '₫',
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xoá số tiền',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: widget.enabled ? _clear : null,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Keeps digits only (max 9, i.e. ≤ 999.999.999) and groups them with dots
class _VndInputFormatter extends TextInputFormatter {
  static final int _maxDigits = AppConstants.amountMax.toString().length;

  static String group(int value) => formatVnd(value).replaceAll(' ₫', '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.isNotEmpty && !RegExp(r'^[0-9.,\s₫]+$').hasMatch(raw)) {
      return oldValue;
    }
    // Separators in the existing formatted value move while typing/deleting.
    // Validate multi-character insertions (paste), not those intermediate groups.
    final oldText = oldValue.text;
    final newText = newValue.text;
    var prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }
    final insertedLength = newText.length - prefix - suffix;
    if (raw.isNotEmpty &&
        insertedLength > 1 &&
        raw.replaceAll(RegExp(r'[0₫\s.,]'), '').isNotEmpty &&
        parseVnd(raw) == null) {
      return oldValue;
    }
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > _maxDigits) {
      return oldValue;
    }
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = group(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
