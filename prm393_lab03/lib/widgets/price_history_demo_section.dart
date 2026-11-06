import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
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
    final theme = Theme.of(context);
    final muted = AppTextStyles.bodyMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
          if (vm.groups.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space16),
            Text('Mở biểu đồ nhóm mẫu', style: AppTextStyles.labelLarge),
            for (final g in vm.groups)
              ListTile(
                key: ValueKey('demo-group-${g.id}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.show_chart_rounded),
                title: Text(g.name, style: AppTextStyles.bodyMedium),
                subtitle: Text('${g.productKeys.length} shop', style: muted),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.priceHistory,
                  arguments: PriceHistoryArgs(groupId: g.id),
                ),
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
          'Chỉ xoá document có nhãn mẫu trong priceHistory và productGroups. '
          'Không hoàn tác được.',
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
}
