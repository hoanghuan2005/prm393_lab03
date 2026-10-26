import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app/routes.dart';
import '../core/constants/app_constants.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/validators/validators.dart';
import '../models/budget_group.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/amount_field.dart';
import '../widgets/app_button.dart';

/// Shared Android/web form. Wishlist items are only changed by a successful save.
class RecordPurchaseScreen extends StatefulWidget {
  final int? initialAmount;
  final String? initialTitle;
  final PurchaseItem? existingPurchase;
  final WishlistItem? wishlistItem;

  const RecordPurchaseScreen({
    super.key,
    this.initialAmount,
    this.initialTitle,
    this.existingPurchase,
    this.wishlistItem,
  }) : assert(existingPurchase == null || wishlistItem == null);

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final _informationKey = GlobalKey<FormState>();
  final _detailsKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _requestId = const Uuid().v4();
  late final String? _sessionUid;
  late DateTime _occurredAt;
  late BuyingMotive _motive;
  late String _budgetGroupId;
  late bool _usedDiscountCode;
  int _step = 1;
  bool _isSaving = false;
  bool _didSave = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _sessionUid = context.read<PurchaseViewModel>().uid;
    final purchase = widget.existingPurchase;
    final item = widget.wishlistItem;
    final amount =
        purchase?.amountVnd ?? item?.latestPriceVnd ?? widget.initialAmount;
    _amountController.text = amount == null || amount <= 0
        ? ''
        : formatVnd(amount).replaceAll(' ₫', '');
    _titleController.text =
        purchase?.title ?? item?.title ?? widget.initialTitle ?? '';
    _noteController.text = purchase?.note ?? item?.note ?? '';
    _occurredAt = purchase?.occurredAt ?? DateTime.now();
    _motive = purchase?.motive ?? item?.displayMotive ?? BuyingMotive.emotion;
    _budgetGroupId =
        purchase?.budgetGroupId ?? item?.budgetGroupId ?? BudgetGroup.otherId;
    _usedDiscountCode = purchase?.usedDiscountCode ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _back() {
    if (_isSaving || _didSave) return;
    if (_step == 2) {
      setState(() => _step = 1);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _next() {
    if (_informationKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _step = 2;
      _saveError = null;
    });
  }

  void _addAmount(int amount) {
    final next = (parseVnd(_amountController.text) ?? 0) + amount;
    if (next > AppConstants.amountMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số tiền tối đa ${formatVnd(AppConstants.amountMax)}'),
        ),
      );
      return;
    }
    _amountController.text = formatVnd(next).replaceAll(' ₫', '');
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(_occurredAt.year < 2000 ? _occurredAt.year : 2000),
      lastDate: DateTime(
        _occurredAt.year > now.year ? _occurredAt.year + 1 : now.year + 1,
        12,
        31,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;
    setState(
      () => _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving || _didSave || _detailsKey.currentState?.validate() != true) {
      return;
    }
    final vm = context.read<PurchaseViewModel>();
    if (_sessionUid == null || vm.uid != _sessionUid) {
      setState(
        () => _saveError =
            'Phiên đăng nhập đã thay đổi. Vui lòng mở lại màn ghi khoản mua.',
      );
      return;
    }
    final amount = parseVnd(_amountController.text) ?? 0;
    final error = Validators.validatePurchase(
      title: _titleController.text,
      amountVnd: amount,
      budgetGroupId: _budgetGroupId,
      note: _noteController.text,
    );
    if (error != null) {
      setState(() => _saveError = error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final original = widget.existingPurchase;
    PurchaseItem? saved;
    if (original != null) {
      final ok = await vm.updatePurchase(
        id: original.id,
        title: _titleController.text,
        amount: amount,
        motive: _motive,
        dateTime: _occurredAt,
        note: _noteController.text,
        budgetGroupId: _budgetGroupId,
        usedDiscountCode: _usedDiscountCode,
        originalPurchase: original,
      );
      if (ok) {
        final note = _noteController.text.trim();
        saved = original.copyWith(
          title: _titleController.text.trim(),
          amountVnd: amount,
          motive: _motive,
          occurredAt: _occurredAt,
          note: note,
          clearNote: note.isEmpty,
          budgetGroupId: _budgetGroupId,
          usedDiscountCode: _usedDiscountCode,
        );
      }
    } else {
      saved = await vm.addPurchase(
        title: _titleController.text,
        amount: amount,
        motive: _motive,
        dateTime: _occurredAt,
        note: _noteController.text,
        budgetGroupId: _budgetGroupId,
        usedDiscountCode: _usedDiscountCode,
        fromWishlist: widget.wishlistItem,
        requestId: _requestId,
      );
    }
    if (!mounted) return;
    final sessionChanged = vm.uid != _sessionUid;
    setState(() {
      _isSaving = false;
      _didSave = saved != null && !sessionChanged;
      if (!_didSave) {
        _saveError = sessionChanged
            ? 'Phiên đăng nhập đã thay đổi. Vui lòng mở lại màn ghi khoản mua.'
            : vm.actionError ?? 'Chưa lưu được khoản mua. Thông tin vẫn được giữ, bạn có thể thử lại.';
      }
    });
    if (!_didSave || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          original == null ? 'Đã lưu khoản mua.' : 'Đã cập nhật khoản mua.',
        ),
      ),
    );
    if (widget.wishlistItem != null || original != null) {
      Navigator.pop(context, saved);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: PurchaseDetailArgs(saved),
      );
    }
  }

  List<BudgetGroup> _groups(BudgetViewModel vm) {
    final groups = [...vm.groups];
    if (!groups.any((g) => g.id == BudgetGroup.otherId)) {
      groups.add(defaultBudgetGroups.last);
    }
    // Preserve an older/custom group instead of silently changing an edited expense.
    if (!groups.any((g) => g.id == _budgetGroupId)) {
      groups.add(
        BudgetGroup(
          id: _budgetGroupId,
          name: 'Nhóm đã lưu',
          order: groups.length,
        ),
      );
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewModel>();
    final groups = _groups(context.watch<BudgetViewModel>());
    final activeSession = _sessionUid != null && vm.uid == _sessionUid;
    final busy = _isSaving || _didSave || vm.isSaving;
    return PopScope<PurchaseItem>(
      canPop: !busy && _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingPurchase == null
                ? 'Ghi khoản mua'
                : 'Chỉnh sửa khoản mua',
          ),
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: busy ? null : _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            if (_step == 2)
              IconButton(
                tooltip: 'Giải thích động cơ',
                onPressed: busy ? null : _showMotiveHelp,
                icon: const Icon(Icons.help_outline_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    child: Text(
                      _step == 1
                          ? 'Bước 1/2: Thông tin khoản mua'
                          : 'Bước 2/2: Động cơ và ghi chú',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.wishlistItem != null) ...[
                            _message(
                              'Xác nhận số tiền bạn thực trả sau giảm giá. Món chỉ được chuyển sang Đã mua khi lưu khoản mua thành công.',
                            ),
                            const SizedBox(height: AppDimens.space16),
                          ],
                          if (!activeSession) ...[
                            _message(
                              'Phiên đăng nhập đã thay đổi. Vui lòng quay lại và mở lại màn ghi khoản mua.',
                            ),
                            const SizedBox(height: AppDimens.space16),
                          ],
                          if (_step == 1)
                            _information(groups, !busy && activeSession)
                          else
                            _details(!busy && activeSession),
                          const SizedBox(height: AppDimens.space24),
                        ],
                      ),
                    ),
                  ),
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    child: AppButton(
                      title: _step == 1
                          ? 'Tiếp tục'
                          : widget.existingPurchase == null
                          ? 'Lưu khoản mua'
                          : 'Cập nhật khoản mua',
                      icon: _step == 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      isLoading: _isSaving,
                      onPressed: busy || !activeSession
                          ? null
                          : _step == 1
                          ? _next
                          : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _information(List<BudgetGroup> groups, bool enabled) {
    return Form(
      key: _informationKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            label: 'Số tiền thực trả *',
            hint: 'Ví dụ: 389.000',
            controller: _amountController,
            enabled: enabled,
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Số tiền sau giảm giá, không bao gồm phí vận chuyển.',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppDimens.space12),
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              for (final amount in [20000, 50000, 100000])
                ActionChip(
                  label: Text('+${formatVnd(amount)}'),
                  onPressed: enabled ? () => _addAmount(amount) : null,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space24),
          TextFormField(
            key: const ValueKey('purchase-title'),
            controller: _titleController,
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: AppConstants.titleMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            validator: Validators.validateTitle,
            decoration: const InputDecoration(
              labelText: 'Tên món hoặc dịch vụ *',
              hintText: 'Ví dụ: Tai nghe Bluetooth',
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          DropdownButtonFormField<String>(
            key: const ValueKey('purchase-budget-group'),
            initialValue: _budgetGroupId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Nhóm ngân sách'),
            items: [
              for (final group in groups)
                DropdownMenuItem(value: group.id, child: Text(group.name)),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) setState(() => _budgetGroupId = value);
                  }
                : null,
          ),
          const SizedBox(height: AppDimens.space16),
          OutlinedButton.icon(
            onPressed: enabled ? _pickDateTime : null,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              '${formatDate(_occurredAt)} · ${formatTime(_occurredAt)}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Có dùng mã giảm giá'),
            controlAffinity: ListTileControlAffinity.leading,
            value: _usedDiscountCode,
            onChanged: enabled
                ? (value) => setState(() => _usedDiscountCode = value ?? false)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _details(bool enabled) {
    return Form(
      key: _detailsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _message(
            '${_titleController.text.trim()}\n${formatVnd(parseVnd(_amountController.text))}',
          ),
          const SizedBox(height: AppDimens.space24),
          Text(
            'Điều gì thúc đẩy bạn mua món này?',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppDimens.space8),
          Text('Chọn một động cơ chính.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimens.space16),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              children: [
                for (final motive in BuyingMotive.values)
                  SizedBox(
                    width: (constraints.maxWidth - AppDimens.space8) / 2,
                    child: Semantics(
                      selected: _motive == motive,
                      child: OutlinedButton(
                        onPressed: enabled
                            ? () => setState(() => _motive = motive)
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 72),
                          padding: const EdgeInsets.all(AppDimens.space12),
                          backgroundColor: _motive == motive
                              ? AppColors.primaryContainer
                              : AppColors.surface,
                          side: BorderSide(
                            color: _motive == motive
                                ? AppColors.onPrimary
                                : AppColors.border,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppDimens.borderMedium,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(motive.icon, size: 20),
                            const SizedBox(width: AppDimens.space8),
                            Expanded(child: Text(motive.label)),
                            if (_motive == motive)
                              const Icon(Icons.check, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space24),
          TextFormField(
            key: const ValueKey('purchase-note'),
            controller: _noteController,
            enabled: enabled,
            minLines: 2,
            maxLines: 4,
            maxLength: AppConstants.noteMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            validator: Validators.validateNote,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (không bắt buộc)',
              hintText: 'Điều bạn muốn ghi nhớ về khoản mua này',
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text) => Container(
    padding: const EdgeInsets.all(AppDimens.space16),
    decoration: const BoxDecoration(
      color: AppColors.primaryContainer,
      borderRadius: AppDimens.borderMedium,
    ),
    child: Text(text, style: AppTextStyles.bodyLarge),
  );

  void _showMotiveHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Động cơ mua sắm'),
        content: const SingleChildScrollView(
          child: Text(
            'Chọn lý do gần nhất với quyết định của bạn:\n\n'
            '• Nhu cầu: Phục vụ sinh hoạt hoặc công việc.\n'
            '• Mong muốn: Món bạn muốn có hoặc nâng cấp.\n'
            '• Khuyến mãi: Bị thu hút bởi ưu đãi.\n'
            '• Cảm xúc: Tự thưởng hoặc phản ứng với cảm xúc.\n'
            '• Ảnh hưởng MXH: Thấy người khác giới thiệu hoặc sử dụng.\n'
            '• Tiện lợi: Phù hợp hoàn cảnh tại thời điểm mua.\n'
            '• Quảng cáo: Thấy thông tin tiếp thị.\n'
            '• Khác: Lý do khác với các lựa chọn trên.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
