import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/owned_item.dart';
import '../models/ui_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/shopping_profile_viewmodel.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/error_view.dart';
import '../widgets/states/loading_view.dart';

/// Screen 24 "Hồ sơ mua sắm" (spec 7.2, A-12): 24.1 empty · 24.2 owned items ·
/// 24.3 add / edit. Everything is optional and never read from Shopee.
class ShoppingProfileScreen extends StatelessWidget {
  const ShoppingProfileScreen({super.key});

  Future<void> _delete(BuildContext context, OwnedItem item) async {
    final vm = context.read<ShoppingProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá "${item.name}"?',
      message: 'Thẻ Quyết Định sẽ không nhắc tới món này nữa.',
      confirmLabel: 'Xoá',
      isDanger: true,
    );
    if (!ok) return;
    final done = await vm.deleteOwnedItem(item);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          done ? 'Đã xoá "${item.name}".' : vm.actionError ?? 'Chưa xoá được.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingProfileViewModel>();
    final groups = context.watch<BudgetViewModel>().groups;
    String? groupName(String? id) =>
        groups.where((g) => g.id == id).firstOrNull?.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ mua sắm')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          Text(
            'Tất cả đều tùy chọn. App không lấy lịch sử mua Shopee: bạn tự ghi đồ '
            'đang dùng để Thẻ Quyết Định nhắc khi có món cùng nhóm hoặc cùng thẻ.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'Đồ đang dùng',
            icon: Icons.inventory_2_outlined,
            action: IconButton(
              key: const ValueKey('owned-add'),
              tooltip: 'Thêm đồ đang dùng',
              icon: const Icon(Icons.add),
              onPressed: () => OwnedItemSheet.show(context),
            ),
            children: [
              switch (vm.state) {
                UiInitial() ||
                UiLoading() => const LoadingView(message: 'Đang tải hồ sơ...'),
                UiError(message: final msg, onRetry: final retry) => ErrorView(
                  message: msg,
                  onRetry: retry,
                ),
                _ when vm.ownedItems.isEmpty => EmptyView(
                  title: 'Chưa ghi đồ đang dùng',
                  subtitle: 'Ví dụ: AirPods, dùng 2 năm, thẻ "tai nghe".',
                  icon: Icons.inventory_2_outlined,
                  actionTitle: 'Thêm đồ đang dùng',
                  onAction: () => OwnedItemSheet.show(context),
                ),
                _ => Column(
                  children: [
                    for (final item in vm.ownedItems)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.label,
                          style: AppTextStyles.titleMedium,
                        ),
                        subtitle: Text(
                          [
                            groupName(item.budgetGroupId) ?? 'Chưa chọn nhóm',
                            if (item.tags.isNotEmpty) item.tags.join(', '),
                          ].join(' · '),
                        ),
                        onTap: () =>
                            OwnedItemSheet.show(context, existing: item),
                        trailing: IconButton(
                          tooltip: 'Xoá',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _delete(context, item),
                        ),
                      ),
                  ],
                ),
              },
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          const _TagsCard(),
        ],
      ),
    );
  }
}

/// Phong cách và thương hiệu hay dùng: comma-separated tags
class _TagsCard extends StatefulWidget {
  const _TagsCard();

  @override
  State<_TagsCard> createState() => _TagsCardState();
}

class _TagsCardState extends State<_TagsCard> {
  final _styles = TextEditingController();
  final _brands = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _styles.dispose();
    _brands.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<ShoppingProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final ok = await vm.saveTags(
      stylesText: _styles.text,
      brandsText: _brands.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã lưu phong cách và thương hiệu.'
              : vm.actionError ?? 'Chưa lưu được.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<ShoppingProfileViewModel>().tags;
    // Fill once with what is stored; afterwards the fields belong to the user
    if (!_loaded && (tags.styles.isNotEmpty || tags.brands.isNotEmpty)) {
      _loaded = true;
      _styles.text = tags.styles.join(', ');
      _brands.text = tags.brands.join(', ');
    }
    return SectionCard(
      title: 'Phong cách và thương hiệu',
      icon: Icons.style_outlined,
      children: [
        AppTextField(
          label: 'Phong cách (cách nhau bởi dấu phẩy)',
          hint: 'Ví dụ: tối giản, thể thao',
          controller: _styles,
        ),
        const SizedBox(height: AppDimens.space12),
        AppTextField(
          label: 'Thương hiệu hay dùng',
          hint: 'Ví dụ: Apple, Uniqlo',
          controller: _brands,
        ),
        const SizedBox(height: AppDimens.space12),
        AppButton(
          title: 'Lưu',
          icon: Icons.check,
          variant: AppButtonVariant.secondary,
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// 24.3 add / edit one owned item
class OwnedItemSheet {
  OwnedItemSheet._();

  static Future<void> show(BuildContext context, {OwnedItem? existing}) =>
      AppBottomSheet.show<void>(
        context,
        title: existing == null ? 'Thêm đồ đang dùng' : 'Sửa đồ đang dùng',
        child: _OwnedItemForm(existing: existing),
      );
}

class _OwnedItemForm extends StatefulWidget {
  final OwnedItem? existing;

  const _OwnedItemForm({this.existing});

  @override
  State<_OwnedItemForm> createState() => _OwnedItemFormState();
}

class _OwnedItemFormState extends State<_OwnedItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _tags = TextEditingController(
    text: widget.existing?.tags.join(', '),
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late String? _groupId = widget.existing?.budgetGroupId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _tags.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _formKey.currentState?.validate() != true) return;
    final vm = context.read<ShoppingProfileViewModel>();
    setState(() {
      _saving = true;
      _error = null;
    });
    final existing = widget.existing;
    final ok = await vm.saveOwnedItem(
      id: existing?.id ?? '',
      name: _name.text,
      budgetGroupId: _groupId,
      tagsText: _tags.text,
      note: _note.text,
      createdAt: existing?.createdAt,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _error = vm.actionError ?? 'Chưa lưu được. Vui lòng thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<BudgetViewModel>().groups;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Tên *',
            hint: 'Ví dụ: AirPods Pro',
            controller: _name,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return 'Vui lòng nhập tên';
              if (text.length > OwnedItem.nameMaxLength) {
                return 'Tối đa ${OwnedItem.nameMaxLength} ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.space12),
          DropdownButtonFormField<String?>(
            key: const ValueKey('owned-group'),
            initialValue: groups.any((g) => g.id == _groupId) ? _groupId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Nhóm ngân sách (không bắt buộc)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Chưa chọn'),
              ),
              for (final g in groups)
                DropdownMenuItem<String?>(value: g.id, child: Text(g.name)),
            ],
            onChanged: _saving ? null : (v) => setState(() => _groupId = v),
          ),
          const SizedBox(height: AppDimens.space12),
          AppTextField(
            label: 'Thẻ (cách nhau bởi dấu phẩy)',
            hint: 'Ví dụ: tai nghe, hệ Apple',
            controller: _tags,
          ),
          const SizedBox(height: AppDimens.space12),
          AppTextField(
            label: 'Ghi chú (không bắt buộc)',
            hint: 'Ví dụ: dùng 2 năm',
            controller: _note,
            validator: (v) => (v?.trim().length ?? 0) > OwnedItem.noteMaxLength
                ? 'Tối đa ${OwnedItem.noteMaxLength} ký tự'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDimens.space12),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppDimens.space16),
          AppButton(
            key: const ValueKey('owned-save'),
            title: 'Lưu',
            icon: Icons.check,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
