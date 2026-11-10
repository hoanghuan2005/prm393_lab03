import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/budget_viewmodel.dart';
import 'amount_field.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'confirm_dialog.dart';

/// Figma "31 Ngân sách theo nhóm": a limit per group for the selected month.
/// The month total is the sum of the group limits, never a separate number that could
/// disagree with them. An empty field means "no limit" for that group.
class BudgetSettingSheet {
  BudgetSettingSheet._();

  static Future<void> show(BuildContext context) {
    final month = context.read<BudgetViewModel>().month;
    return AppBottomSheet.show<void>(
      context,
      title: 'Hạn mức ${formatMonthLabel(month).toLowerCase()}',
      child: const _BudgetLimitsForm(),
    );
  }
}

class _BudgetLimitsForm extends StatefulWidget {
  const _BudgetLimitsForm();

  @override
  State<_BudgetLimitsForm> createState() => _BudgetLimitsFormState();
}

class _BudgetLimitsFormState extends State<_BudgetLimitsForm> {
  final _formKey = GlobalKey<FormState>();
  late final BudgetViewModel _vm = context.read<BudgetViewModel>();

  /// groupId → value being edited (null = no limit)
  late final Map<String, int?> _initialValues = {
    for (final g in _vm.groups) g.id: _vm.limitFor(g.id),
  };
  late final Map<String, int?> _values = {..._initialValues};
  bool _isSaving = false;
  bool _allowClose = false;
  bool _confirmingClose = false;
  String? _error;

  bool get _hasChanges =>
      _values.entries.any((entry) => entry.value != _initialValues[entry.key]);

  Future<void> _requestClose() async {
    if (_isSaving || _confirmingClose) return;
    _confirmingClose = true;
    final discard =
        !_hasChanges ||
        await ConfirmDialog.show(
          context,
          title: 'Bỏ thay đổi hạn mức?',
          message: 'Những hạn mức vừa nhập chưa được lưu.',
          confirmLabel: 'Bỏ thay đổi',
        );
    _confirmingClose = false;
    if (!mounted || !discard) return;
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.maybePop(context);
  }

  int get _total => _values.values.fold(0, (sum, v) => sum + (v ?? 0));

  Future<void> _save() async {
    if (_isSaving || _formKey.currentState?.validate() != true) return;
    final changes = <String, int?>{
      for (final e in _values.entries)
        if (e.value != _vm.limitFor(e.key)) e.key: e.value,
    };
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final ok = await _vm.setGroupLimits(changes);
    if (!mounted) return;
    if (!ok) {
      // Keep the sheet and every typed value; pressing save again retries
      setState(() {
        _isSaving = false;
        _error =
            _vm.actionError ?? 'Chưa lưu được ngân sách. Vui lòng thử lại.';
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            changes.isEmpty
                ? 'Hạn mức không thay đổi.'
                : 'Đã lưu hạn mức ${formatMonthLabel(_vm.month).toLowerCase()}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final total = _total;
    // Only groups that get a limit in this form can be compared with the total
    final spent = _values.entries
        .where((e) => e.value != null)
        .fold(0, (sum, e) => sum + vm.spentFor(e.key));
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đặt mốc tham chiếu cho từng nhóm hàng. Để trống nếu không muốn đặt hạn mức. '
            'App không chặn mua sắm.',
            style: AppTextStyles.bodyMedium.themed(context),
          ),
          const SizedBox(height: AppDimens.space16),
          for (final group in vm.groups) ...[
            AmountField(
              key: ValueKey('budget-limit-${group.id}'),
              label: group.name,
              hint: 'Không đặt hạn mức',
              optional: true,
              enabled: !_isSaving,
              initialValue: _values[group.id],
              onChanged: (value) => setState(() => _values[group.id] = value),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimens.space4,
                bottom: AppDimens.space12,
              ),
              child: Text(
                'Đã chi tháng này: ${formatVnd(vm.spentFor(group.id))}',
                style: AppTextStyles.labelMedium.themed(context),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).mutedSurface,
              borderRadius: AppDimens.borderMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng ngân sách tháng: ${formatVnd(total)}',
                  style: AppTextStyles.titleMedium.themed(context),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  total == 0
                      ? 'Chưa đặt hạn mức nào. Thẻ quyết định vẫn hoạt động, chỉ không tính phần trăm.'
                      : 'Bằng tổng hạn mức các nhóm. Các nhóm này đã chi ${formatVnd(spent)}; '
                            '${spent > total ? 'đã vượt ${formatVnd(spent - total)}' : 'còn ${formatVnd(total - spent)}'}.',
                  style: AppTextStyles.bodyMedium.themed(context),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDimens.space12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: AppTextStyles.bodyMedium
                    .themed(context)
                    .copyWith(color: AppSemanticColors.of(context).error),
              ),
            ),
          ],
          const SizedBox(height: AppDimens.space16),
          PopScope(
            canPop: _allowClose || (!_isSaving && !_hasChanges),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _requestClose();
            },
            child: AppButton(
              title: _error == null ? 'Lưu hạn mức' : 'Thử lại',
              icon: _error == null
                  ? Icons.check_rounded
                  : Icons.refresh_rounded,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
