import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../services/voucher_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_demo_viewmodel.dart';
import 'app_button.dart';
import 'confirm_dialog.dart';
import 'section_card.dart';

/// Firebase Demo Area: create / delete the sample data of "Biểu đồ giá tham khảo".
/// Shown to admins only; nothing for everyone else.
class PriceHistoryDemoSection extends StatelessWidget {
  const PriceHistoryDemoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PriceHistoryDemoViewModel?>();
    if (vm == null || !vm.isAdmin) return const SizedBox.shrink();
    final vouchers = context.watch<VoucherService?>();
    final theme = Theme.of(context);
    final muted = AppTextStyles.bodyMedium
        .themed(context)
        .copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      child: SectionCard(
        title: 'Dữ liệu giá mẫu (admin)',
        icon: Icons.show_chart_rounded,
        children: [
          Text(
            'Tạo 8 nhóm sản phẩm mẫu, mỗi nhóm 3–4 shop, giá 90 ngày cho Biểu đồ '
            'giá tham khảo. Mọi người dùng đều thấy, có nhãn "Dữ liệu mẫu". '
            'Tạo lại sẽ xoá bộ mẫu cũ trước.',
            style: muted,
          ),
          const SizedBox(height: AppDimens.space12),
          if (vm.isBusy) ...[
            LinearProgressIndicator(
              key: const ValueKey('price-demo-progress'),
              value: vm.total == 0 ? null : vm.done / vm.total,
            ),
            const SizedBox(height: AppDimens.space8),
            Text('Đang xử lý ${vm.done}/${vm.total} document…', style: muted),
            const SizedBox(height: AppDimens.space12),
          ],
          AppButton(
            title: 'Tạo dữ liệu giá mẫu',
            icon: Icons.add_chart_rounded,
            isLoading: vm.isBusy,
            onPressed: vm.isBusy ? null : () => _seed(context, vm),
          ),
          const SizedBox(height: AppDimens.space12),
          AppButton(
            title: 'Xoá dữ liệu giá mẫu',
            icon: Icons.delete_outline_rounded,
            variant: AppButtonVariant.danger,
            onPressed: vm.isBusy ? null : () => _clear(context, vm),
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            'Món mẫu trong danh sách của bạn: 3 món có "Cùng món ở shop khác" và '
            '1 món không có mã món, có nhãn "Dữ liệu mẫu", không tính vào thống '
            'kê và không gửi giá đi. Cần tạo dữ liệu giá mẫu trước.',
            style: muted,
          ),
          const SizedBox(height: AppDimens.space12),
          AppButton(
            title: 'Thêm món mẫu vào danh sách của tôi',
            icon: Icons.playlist_add_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: vm.isBusy ? null : () => _addItems(context, vm),
          ),
          const SizedBox(height: AppDimens.space12),
          AppButton(
            title: 'Gỡ món mẫu khỏi danh sách',
            icon: Icons.playlist_remove_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: vm.isBusy ? null : () => _removeItems(context, vm),
          ),
          if (vm.groups.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space16),
            Text(
              'Mở biểu đồ nhóm mẫu',
              style: AppTextStyles.labelLarge.themed(context),
            ),
            for (final g in vm.groups)
              ListTile(
                key: ValueKey('demo-group-${g.id}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.show_chart_rounded),
                title: Text(
                  g.name,
                  style: AppTextStyles.bodyMedium.themed(context),
                ),
                subtitle: Text('${g.productKeys.length} shop', style: muted),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.priceHistory,
                  arguments: PriceHistoryArgs(groupId: g.id),
                ),
              ),
          ],
          // For testers: where the voucher suggestions come from
          if (vouchers != null) ...[
            const SizedBox(height: AppDimens.space16),
            Text(
              'Voucher: ${vouchers.source}'
              '${vouchers.isStale ? ' (mất kết nối)' : ''} · ${vouchers.count} mã',
              key: const ValueKey('voucher-source'),
              style: muted,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _seed(BuildContext context, PriceHistoryDemoViewModel vm) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Tạo dữ liệu giá mẫu?',
      message:
          'Xoá bộ giá mẫu cũ rồi ghi khoảng 4.500 document mới lên Firestore. '
          'Dữ liệu thật không bị đụng tới.',
      confirmLabel: 'Tạo',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = await vm.seed();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == null
              ? vm.errorMessage ?? 'Chưa tạo được dữ liệu giá mẫu.'
              : 'Đã ghi $count document giá mẫu.',
        ),
      ),
    );
  }

  Future<void> _clear(
    BuildContext context,
    PriceHistoryDemoViewModel vm,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá dữ liệu giá mẫu?',
      message:
          'Chỉ xoá document có nhãn mẫu trong priceHistory và productGroups, '
          'cùng các món mẫu trong danh sách của bạn. Không hoàn tác được.',
      confirmLabel: 'Xoá',
      isDanger: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = await vm.clear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == null
              ? vm.errorMessage ?? 'Chưa xoá được dữ liệu giá mẫu.'
              : 'Đã xoá $count document giá mẫu.',
        ),
      ),
    );
  }

  Future<void> _addItems(
    BuildContext context,
    PriceHistoryDemoViewModel vm,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Thêm món mẫu vào danh sách?',
      message:
          'Thêm tối đa 4 món mẫu vào danh sách mong muốn của bạn để thử Giá '
          'tham khảo và Cùng món ở shop khác. Món đã có thì bỏ qua.',
      confirmLabel: 'Thêm',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = await vm.addDemoItems();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == null
              ? vm.errorMessage ?? 'Chưa thêm được món mẫu.'
              : count == 0
              ? 'Không có món mẫu mới để thêm. Đã tạo dữ liệu giá mẫu chưa?'
              : 'Đã thêm $count món mẫu vào danh sách.',
        ),
      ),
    );
  }

  Future<void> _removeItems(
    BuildContext context,
    PriceHistoryDemoViewModel vm,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Gỡ món mẫu khỏi danh sách?',
      message:
          'Chỉ xoá các món có nhãn "Dữ liệu mẫu" trong danh sách của bạn, kèm '
          'lịch sử giá của chúng. Món thật không bị đụng tới.',
      confirmLabel: 'Gỡ',
      isDanger: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = await vm.removeDemoItems();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == null
              ? vm.errorMessage ?? 'Chưa gỡ được món mẫu.'
              : 'Đã gỡ $count món mẫu khỏi danh sách.',
        ),
      ),
    );
  }
}
