import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';
import '../viewmodels/vouchers_admin_viewmodel.dart';
import 'message_box.dart';

/// Create or edit a real Shopee voucher. [onSubmit] returns an error message,
/// or null when it is saved.
class VoucherFormDialog extends StatefulWidget {
  final String title;
  final VoucherDraft? initial;
  final Future<String?> Function(VoucherDraft draft) onSubmit;

  const VoucherFormDialog({
    super.key,
    required this.title,
    this.initial,
    required this.onSubmit,
  });

  /// true when the voucher was saved
  static Future<bool> show(
    BuildContext context, {
    required String title,
    VoucherDraft? initial,
    required Future<String?> Function(VoucherDraft draft) onSubmit,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          VoucherFormDialog(title: title, initial: initial, onSubmit: onSubmit),
    );
    return saved ?? false;
  }

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _discount;
  late final TextEditingController _minOrder;
  late final TextEditingController _shopLink;
  late final TextEditingController _shopName;
  late final TextEditingController _source;
  late final TextEditingController _untilText;
  late DateTime _until;
  late VoucherKind _kind;
  late VoucherCategory _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _code = TextEditingController(text: d?.code ?? '');
    _title = TextEditingController(text: d?.title ?? '');
    _discount = TextEditingController(
      text: d == null ? '' : '${d.discountVnd}',
    );
    _minOrder = TextEditingController(
      text: d == null || d.minOrderVnd == 0 ? '' : '${d.minOrderVnd}',
    );
    _shopLink = TextEditingController(text: d?.shopId ?? '');
    _shopName = TextEditingController(text: d?.shopName ?? '');
    _source = TextEditingController(text: d?.sourceUrl ?? '');
    final today = DateTime.now();
    _until = d == null || d.validUntil.year < 2000
        ? DateTime(today.year, today.month, today.day + 7)
        : d.validUntil;
    _untilText = TextEditingController(text: formatDay(_until));
    _kind = d?.kind ?? VoucherKind.discount;
    _category = d?.category ?? VoucherCategory.all;
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _title,
      _discount,
      _minOrder,
      _shopLink,
      _shopName,
      _source,
      _untilText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _until.isBefore(today) ? today : _until,
      firstDate: today,
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Hạn dùng (hết ngày này)',
    );
    if (picked == null) return;
    setState(() {
      _until = picked;
      _untilText.text = formatDay(picked);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final link = _shopLink.text.trim();
    final error = await widget.onSubmit(
      VoucherDraft(
        code: _code.text,
        title: _title.text,
        kind: _kind,
        discountVnd: VouchersAdminViewModel.parseVnd(_discount.text) ?? 0,
        minOrderVnd: VouchersAdminViewModel.parseVnd(_minOrder.text) ?? 0,
        category: _category,
        validUntil: _until,
        shopId: link.isEmpty ? null : shopIdFromShopeeLink(link),
        shopName: _shopName.text,
        sourceUrl: _source.text,
      ),
    );
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

  Widget _gap() => const SizedBox(height: AppDimens.space16);

  @override
  Widget build(BuildContext context) {
    final label = context.tokens.text(AppTextStyles.labelLarge);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MessageBox(
                  tone: MessageTone.info,
                  message:
                      'Chỉ nhập mã Shopee đang công bố thật (trang voucher của '
                      'Shopee hoặc của shop). App gợi ý mã này cho món phù hợp, '
                      'ghi rõ "Điều kiện mã do Shopee quyết định".',
                ),
                _gap(),
                AppTextField(
                  label: 'Mã',
                  hint: 'Ví dụ: SHOPEE50K',
                  controller: _code,
                  validator: VouchersAdminViewModel.validateCode,
                ),
                _gap(),
                AppTextField(
                  label: 'Mô tả ngắn',
                  hint: 'Ví dụ: Giảm 50K cho đơn từ 250K',
                  controller: _title,
                  validator: VouchersAdminViewModel.validateTitle,
                ),
                _gap(),
                Text('Loại mã', style: label),
                const SizedBox(height: AppDimens.space8),
                DropdownButtonFormField<VoucherKind>(
                  initialValue: _kind,
                  items: [
                    for (final k in VoucherKind.values)
                      DropdownMenuItem(value: k, child: Text(k.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (k) => setState(() => _kind = k ?? _kind),
                ),
                _gap(),
                AppTextField(
                  label: _kind == VoucherKind.freeship
                      ? 'Phí vận chuyển được miễn tối đa (₫)'
                      : 'Số tiền giảm (₫)',
                  hint: 'Ví dụ: 50000 hoặc 50k',
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      VouchersAdminViewModel.validateDiscount(v, _kind),
                ),
                _gap(),
                AppTextField(
                  label: 'Đơn tối thiểu (₫), để trống nếu không có',
                  hint: 'Ví dụ: 250000',
                  controller: _minOrder,
                  keyboardType: TextInputType.number,
                  validator: VouchersAdminViewModel.validateMinOrder,
                ),
                _gap(),
                Text('Áp cho loại hàng', style: label),
                const SizedBox(height: AppDimens.space8),
                DropdownButtonFormField<VoucherCategory>(
                  initialValue: _category,
                  items: [
                    for (final c in VoucherCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (c) => setState(() => _category = c ?? _category),
                ),
                _gap(),
                AppTextField(
                  label:
                      'Mã của một shop: link sản phẩm của shop (để trống nếu '
                      'mã dùng cho mọi shop)',
                  hint: 'https://shopee.vn/Ten-san-pham-i.123456.789012',
                  controller: _shopLink,
                  validator: VouchersAdminViewModel.validateShopLink,
                ),
                _gap(),
                AppTextField(
                  label: 'Tên shop (hiển thị trong app)',
                  hint: 'Ví dụ: Perseper',
                  controller: _shopName,
                ),
                _gap(),
                AppTextField(
                  label: 'Hạn dùng',
                  controller: _untilText,
                  readOnly: true,
                  onTap: _saving ? null : _pickDate,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                _gap(),
                AppTextField(
                  label: 'Link trang Shopee công bố mã (nên có)',
                  hint: 'https://shopee.vn/…',
                  controller: _source,
                  validator: VouchersAdminViewModel.validateSourceUrl,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.space8),
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
          title: 'Lưu',
          width: 180,
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
