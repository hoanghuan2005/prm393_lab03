import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/vouchers_admin_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';
import '../widgets/voucher_form_dialog.dart';

/// "Mã giảm giá": real Shopee vouchers the app suggests on matching items
/// (list, search, create, edit, archive, use again; decision D-3)
class VouchersAdminScreen extends StatefulWidget {
  const VouchersAdminScreen({super.key});

  @override
  State<VouchersAdminScreen> createState() => _VouchersAdminScreenState();
}

class _VouchersAdminScreenState extends State<VouchersAdminScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm([VoucherRecord? voucher]) async {
    final vm = context.read<VouchersAdminViewModel>();
    final saved = await VoucherFormDialog.show(
      context,
      title: voucher == null
          ? 'Thêm mã giảm giá'
          : 'Sửa mã ${voucher.draft.code}',
      initial: voucher?.draft,
      onSubmit: (draft) => vm.save(draft, id: voucher?.id),
    );
    if (saved && mounted) {
      showMessage(context, 'Đã lưu. App cập nhật mã gợi ý ngay.');
    }
  }

  Future<void> _setActive(VoucherRecord voucher, bool active) async {
    final vm = context.read<VouchersAdminViewModel>();
    if (!active) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Lưu trữ mã ${voucher.draft.code}?',
        message:
            'App sẽ không gợi ý mã này nữa. Bạn có thể bấm "Dùng lại" sau.',
        confirmLabel: 'Lưu trữ',
      );
      if (!ok) return;
    }
    final error = await vm.setActive(voucher, active);
    if (!mounted) return;
    showMessage(
      context,
      error ??
          (active
              ? 'Đã dùng lại mã ${voucher.draft.code}.'
              : 'Đã lưu trữ mã ${voucher.draft.code}.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VouchersAdminViewModel>();
    return AdminPage(
      title: 'Mã giảm giá',
      subtitle:
          'Mã Shopee thật mà app gợi ý ở Chi tiết món. Mã không bị xoá mà '
          'được lưu trữ; mã hết hạn tự ngừng gợi ý.',
      actions: [
        AppButton(
          title: 'Thêm mã',
          icon: Icons.add,
          width: 160,
          onPressed: _openForm,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppDimens.space16,
            runSpacing: AppDimens.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: AppTextField(
                  controller: _search,
                  hint: 'Tìm theo mã, mô tả, shop hoặc loại hàng',
                  prefixIcon: Icons.search,
                  onChanged: vm.setQuery,
                ),
              ),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  for (final f in VoucherFilter.values)
                    ChoiceChip(
                      label: Text('${f.label} (${vm.countFor(f)})'),
                      selected: vm.filter == f,
                      onSelected: (_) => vm.setFilter(f),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          Expanded(
            child: UiStateBuilder<List<VoucherRecord>>(
              state: vm.state,
              loadingMessage: 'Đang tải mã giảm giá…',
              emptyIcon: Icons.local_offer_outlined,
              builder: (context, vouchers) => Card(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.space8,
                  ),
                  itemCount: vouchers.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => _VoucherRow(
                    voucher: vouchers[i],
                    now: vm.now,
                    busy: vm.isBusy(vouchers[i].id),
                    onEdit: () => _openForm(vouchers[i]),
                    onActive: (active) => _setActive(vouchers[i], active),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }
}

class _VoucherRow extends StatelessWidget {
  final VoucherRecord voucher;
  final DateTime now;
  final bool busy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActive;

  const _VoucherRow({
    required this.voucher,
    required this.now,
    required this.busy,
    required this.onEdit,
    required this.onActive,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final d = voucher.draft;
    final expired = voucher.isExpired(now);
    final amount = d.kind == VoucherKind.freeship
        ? 'Miễn phí vận chuyển tối đa ${formatVnd(d.discountVnd)}'
        : 'Giảm ${formatVnd(d.discountVnd)}';
    return Padding(
      key: ValueKey('voucher-row-${voucher.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      d.code,
                      style: t
                          .text(AppTextStyles.titleMedium)
                          .copyWith(fontFamily: 'monospace'),
                    ),
                    Text(d.title, style: t.text(AppTextStyles.bodyMedium)),
                  ],
                ),
                const SizedBox(height: AppDimens.space6),
                Wrap(
                  spacing: AppDimens.space6,
                  runSpacing: AppDimens.space6,
                  children: [
                    StatusBadge(
                      label: !voucher.isActive
                          ? 'Đã lưu trữ'
                          : expired
                          ? 'Hết hạn'
                          : 'Đang dùng',
                      tone: !voucher.isActive
                          ? BadgeTone.neutral
                          : expired
                          ? BadgeTone.warning
                          : BadgeTone.primary,
                    ),
                    StatusBadge(label: amount),
                    StatusBadge(
                      label: d.minOrderVnd > 0
                          ? 'Đơn từ ${formatVnd(d.minOrderVnd)}'
                          : 'Mọi đơn',
                    ),
                    StatusBadge(label: d.category.label),
                    StatusBadge(
                      label: d.shopId == null && d.shopName == null
                          ? 'Mọi shop'
                          : 'Shop ${d.shopName ?? d.shopId}',
                      tone: BadgeTone.info,
                    ),
                    StatusBadge(label: 'Hạn ${formatDay(d.validUntil)}'),
                    if (voucher.isLegacy)
                      const StatusBadge(
                        label: 'Từ màn quản trị cũ, cần kiểm tra',
                        tone: BadgeTone.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(AppDimens.space12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Sửa mã ${d.code}',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            if (voucher.isActive)
              IconButton(
                tooltip: 'Lưu trữ mã ${d.code}',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => onActive(false),
              )
            else
              IconButton(
                tooltip: 'Dùng lại mã ${d.code}',
                icon: const Icon(Icons.unarchive_outlined),
                onPressed: () => onActive(true),
              ),
          ],
        ],
      ),
    );
  }
}
