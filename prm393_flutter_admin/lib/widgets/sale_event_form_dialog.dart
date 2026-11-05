import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../viewmodels/sale_events_viewmodel.dart';
import 'message_box.dart';

/// Create or edit a sale event, or confirm the event of a suggestion being
/// approved. [onSubmit] returns an error message, or null when it is saved.
class SaleEventFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final SaleEventDraft initial;

  /// Read-only context shown above the form (the user's note on a suggestion)
  final String? note;
  final Future<String?> Function(SaleEventDraft draft) onSubmit;

  const SaleEventFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.initial,
    this.note,
    required this.onSubmit,
  });

  /// true when the event was saved
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String submitLabel,
    required SaleEventDraft initial,
    String? note,
    required Future<String?> Function(SaleEventDraft draft) onSubmit,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SaleEventFormDialog(
        title: title,
        submitLabel: submitLabel,
        initial: initial,
        note: note,
        onSubmit: onSubmit,
      ),
    );
    return saved ?? false;
  }

  @override
  State<SaleEventFormDialog> createState() => _SaleEventFormDialogState();
}

class _SaleEventFormDialogState extends State<SaleEventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dateText;
  late DateTime _date;
  late SaleType _type;
  late bool _confirmed;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _date = widget.initial.day;
    _dateText = TextEditingController(text: formatDay(_date));
    _type = widget.initial.type;
    _confirmed = widget.initial.confirmed;
  }

  @override
  void dispose() {
    _name.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Chọn ngày diễn ra',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = formatDay(picked);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(
      SaleEventDraft(
        name: _name.text,
        date: _date,
        type: _type,
        confirmed: _confirmed,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.note != null) ...[
                  MessageBox(
                    tone: MessageTone.info,
                    message: 'Ghi chú của người gửi: ${widget.note}',
                  ),
                  const SizedBox(height: AppDimens.space16),
                ],
                AppTextField(
                  label: 'Tên đợt sale',
                  hint: 'Ví dụ: Siêu sale 11.11',
                  controller: _name,
                  validator: SaleEventsViewModel.validateName,
                ),
                const SizedBox(height: AppDimens.space16),
                AppTextField(
                  label: 'Ngày diễn ra',
                  controller: _dateText,
                  readOnly: true,
                  onTap: _saving ? null : _pickDate,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: AppDimens.space16),
                Text('Loại đợt sale', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimens.space8),
                DropdownButtonFormField<SaleType>(
                  initialValue: _type,
                  items: [
                    for (final t in SaleType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (t) => setState(() => _type = t ?? _type),
                ),
                const SizedBox(height: AppDimens.space8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmed,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _confirmed = v),
                  title: Text(
                    'Shop đã công bố chính thức',
                    style: AppTextStyles.labelLarge,
                  ),
                  subtitle: Text(
                    'Chỉ đợt đã xác nhận mới được tính trong Thẻ quyết định '
                    'và được nhắc lúc 20:00 hôm trước.',
                    style: AppTextStyles.bodyMedium,
                  ),
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
          title: widget.submitLabel,
          width: 180,
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
