import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/shopee_voucher.dart';
import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/shopee_vouchers_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';

/// Shopee vouchers an admin / staff scraped with the Chrome extension (lab
/// build): filter, search, copy the source link, delete outdated ones.
class ShopeeVouchersScreen extends StatefulWidget {
  const ShopeeVouchersScreen({super.key});

  @override
  State<ShopeeVouchersScreen> createState() => _ShopeeVouchersScreenState();
}

class _ShopeeVouchersScreenState extends State<ShopeeVouchersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(ShopeeVoucher v) async {
    final vm = context.read<ShopeeVouchersViewModel>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá voucher?',
      message:
          'Voucher "${v.valueLabel}" sẽ bị xoá khỏi Firebase. '
          'Lần cào sau, nếu voucher còn trên trang, nó sẽ được thêm lại.',
      confirmLabel: 'Xoá',
      isDanger: true,
    );
    if (!ok || !mounted) return;
    final error = await vm.delete(v);
    if (mounted) showMessage(context, error ?? 'Đã xoá voucher.');
  }

  Future<void> _copyLink(ShopeeVoucher v) async {
    await Clipboard.setData(ClipboardData(text: v.sourceUrl));
    if (mounted) showMessage(context, 'Đã chép link trang Shopee.');
  }

  Widget _filters(ShopeeVouchersViewModel vm) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Wrap(
        spacing: AppDimens.space16,
        runSpacing: AppDimens.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 340,
            child: AppTextField(
              controller: _search,
              hint: 'Tìm theo nội dung, shop hoặc sản phẩm',
              prefixIcon: Icons.search,
              onChanged: vm.setQuery,
            ),
          ),
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              for (final scope in <VoucherScope?>[null, ...VoucherScope.values])
                ChoiceChip(
                  label: Text(
                    '${scope?.label ?? 'Tất cả'} (${vm.countFor(scope)})',
                  ),
                  selected: vm.scope == scope,
                  onSelected: (_) => vm.setScope(scope),
                ),
              FilterChip(
                label: const Text('Ẩn mã đã hết lượt'),
                selected: vm.hideUnavailable,
                onSelected: vm.setHideUnavailable,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShopeeVouchersViewModel>();
    return AdminPage(
      title: 'Voucher Shopee',
      subtitle:
          'Voucher do Admin / Nhân viên cào bằng Chrome extension (bản Lab). '
          'Đang có ${vm.totalCount} voucher từ ${vm.shopCount} shop; '
          'cào lại cùng trang chỉ cập nhật, không tạo trùng.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filters(vm),
          const SizedBox(height: AppDimens.space16),
          Expanded(
            child: UiStateBuilder<List<ShopeeVoucher>>(
              state: vm.state,
              loadingMessage: 'Đang tải voucher…',
              emptyIcon: Icons.local_offer_outlined,
              builder: (context, items) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppDimens.space24),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimens.space12),
                itemBuilder: (context, i) => _VoucherCard(
                  voucher: items[i],
                  busy: vm.isBusy(items[i].id),
                  onCopyLink: () => _copyLink(items[i]),
                  onDelete: () => _delete(items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final ShopeeVoucher voucher;
  final bool busy;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;

  const _VoucherCard({
    required this.voucher,
    required this.busy,
    required this.onCopyLink,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final v = voucher;
    final t = context.tokens;
    final condition = v.conditionLabel;
    final scopeTone = switch (v.scope) {
      VoucherScope.shop => BadgeTone.primary,
      VoucherScope.platform => BadgeTone.info,
      VoucherScope.payment => BadgeTone.warning,
      VoucherScope.unknown => BadgeTone.neutral,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(v.valueLabel, style: t.text(AppTextStyles.titleLarge)),
                StatusBadge(label: v.scope.label, tone: scopeTone),
                if (v.unavailable)
                  const StatusBadge(
                    label: 'Hết lượt / đã dùng',
                    tone: BadgeTone.error,
                    icon: Icons.block,
                  ),
              ],
            ),
            if (condition.isNotEmpty) ...[
              const SizedBox(height: AppDimens.space4),
              Text(condition, style: t.text(AppTextStyles.bodyMedium)),
            ],
            const SizedBox(height: AppDimens.space12),
            MessageBox(message: v.raw),
            const SizedBox(height: AppDimens.space12),
            Wrap(
              spacing: AppDimens.space16,
              runSpacing: AppDimens.space4,
              children: [
                if (v.shopName != null)
                  _Fact(icon: Icons.storefront_outlined, text: v.shopName!),
                if (v.productTitle != null)
                  _Fact(
                    icon: Icons.shopping_bag_outlined,
                    text: v.productTitle!,
                  ),
                if (v.lastSeenAt != null)
                  _Fact(
                    icon: Icons.schedule,
                    text: 'Cào lúc ${formatDateTime(v.lastSeenAt!)}',
                  ),
                _Fact(
                  icon: Icons.person_outline,
                  text: 'Người cào: ${shortId(v.capturedBy)}',
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppDimens.space12,
                runSpacing: AppDimens.space8,
                alignment: WrapAlignment.end,
                children: [
                  if (v.sourceUrl.isNotEmpty)
                    AppButton(
                      title: 'Chép link',
                      icon: Icons.link,
                      variant: AppButtonVariant.secondary,
                      width: 150,
                      onPressed: onCopyLink,
                    ),
                  AppButton(
                    title: 'Xoá',
                    icon: Icons.delete_outline,
                    variant: AppButtonVariant.secondary,
                    width: 150,
                    isLoading: busy,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: context.tokens.textSecondary),
        const SizedBox(width: AppDimens.space4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: context.tokens.text(AppTextStyles.bodyMedium),
          ),
        ),
      ],
    );
  }
}
