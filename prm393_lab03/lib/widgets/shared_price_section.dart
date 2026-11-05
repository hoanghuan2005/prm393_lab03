import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_format.dart';
import '../models/price_snapshot.dart';
import '../models/shared_price.dart';
import '../models/wishlist_item.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/shared_price_viewmodel.dart';

/// "Giá người khác ghi" (spec 8.3) on Chi tiết món: what other people recorded for the
/// same Shopee product and variant in the last 3 days, never who recorded it. Only a
/// suggestion: [onUsePrice] asks the user before the median becomes their price.
class SharedPriceSection extends StatefulWidget {
  final WishlistItem item;
  final ValueChanged<int>? onUsePrice;

  const SharedPriceSection({super.key, required this.item, this.onUsePrice});

  @override
  State<SharedPriceSection> createState() => _SharedPriceSectionState();
}

class _SharedPriceSectionState extends State<SharedPriceSection> {
  /// The user's latest comparable price once their history has loaded (Lịch sử giá).
  /// Until then the comparison loads without it, so a failed history never blocks it.
  PriceSnapshot? _mine(BuildContext context) => context
      .watch<DecisionSupportViewModel?>()
      ?.priceInsightsFor(widget.item)
      ?.latest;

  void _requestLoad(SharedPriceViewModel vm, PriceSnapshot? mine) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) vm.load(widget.item, mine: mine);
    });
  }

  static String _percent(int diff) => diff == 0
      ? 'bằng trung vị'
      : diff < 0
      ? 'thấp hơn trung vị ${-diff}%'
      : 'cao hơn trung vị $diff%';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SharedPriceViewModel?>();
    if (vm == null) return const SizedBox.shrink();
    final mine = _mine(context);
    final state = vm.stateFor(widget.item, mine: mine);
    if (state.status == SharedPriceStatus.unsupported) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space16),
        child: Text(
          'Thêm link sản phẩm Shopee của món để so với giá người khác đã ghi.',
          style: AppTextStyles.labelMedium,
        ),
      );
    }
    _requestLoad(vm, mine);

    return Card(
      key: const ValueKey('shared-prices'),
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    'Giá người khác ghi',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space8),
            ..._body(context, vm, state, mine),
            if (state.variantUnknown) ...[
              const SizedBox(height: AppDimens.space4),
              Text(
                'Món chưa rõ phân loại: chỉ so với giá cũng chưa rõ phân loại, giá thật có thể khác.',
                style: AppTextStyles.labelMedium,
              ),
            ],
            const Divider(height: AppDimens.space24),
            _SharingSwitch(item: widget.item),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    SharedPriceViewModel vm,
    SharedPriceState state,
    PriceSnapshot? mine,
  ) {
    switch (state.status) {
      case SharedPriceStatus.loading:
      case SharedPriceStatus.unsupported:
        return const [LinearProgressIndicator(minHeight: 3)];
      case SharedPriceStatus.error:
        return [
          Text(
            'Chưa tải được giá người khác ghi. Kiểm tra mạng rồi thử lại.',
            style: AppTextStyles.bodyMedium,
          ),
          TextButton.icon(
            onPressed: () => vm.load(widget.item, mine: mine, force: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ];
      case SharedPriceStatus.notEnough:
        return [
          Text(
            'Chưa đủ dữ liệu: cần ít nhất ${SharedPriceSummary.minPeople} người khác '
            'ghi giá cùng sản phẩm và phân loại trong ${SharedPriceSummary.windowDays} ngày qua.',
            style: AppTextStyles.bodyMedium,
          ),
        ];
      case SharedPriceStatus.ready:
        final s = state.summary!;
        final diff = s.myDiffPercent;
        return [
          Semantics(
            container: true,
            child: Text(
              'Trung vị ${formatVnd(s.medianVnd)} · từ ${s.count} người, '
              '${SharedPriceSummary.windowDays} ngày qua'
              '${state.priceType == PriceType.flash ? ' (giá Flash Sale)' : ''}',
              key: const ValueKey('shared-price-median'),
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Thấp nhất ${formatVnd(s.minVnd)} · cao nhất ${formatVnd(s.maxVnd)}',
            style: AppTextStyles.bodyMedium,
          ),
          if (diff != null)
            Text(
              'Giá bạn ghi ${formatVnd(mine?.amountVnd)} ${_percent(diff)}.',
              style: AppTextStyles.bodyMedium,
            ),
          if (s.excludedCount > 0)
            Text(
              'Đã bỏ ${s.excludedCount} giá lệch hơn ${SharedPriceSummary.outlierPercent}% so với trung vị.',
              style: AppTextStyles.labelMedium,
            ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Ẩn danh: app không lưu và không hiện ai đã ghi. Giá chỉ để tham khảo.',
            style: AppTextStyles.labelMedium,
          ),
          if (widget.onUsePrice case final use?)
            TextButton.icon(
              key: const ValueKey('use-shared-price'),
              onPressed: () => use(s.medianVnd),
              icon: const Icon(Icons.done_rounded, size: 18),
              label: Text('Dùng ${formatVnd(s.medianVnd)} làm giá của món'),
            ),
        ];
    }
  }
}

/// Anonymous sharing of the user's own prices, with what it means
class _SharingSwitch extends StatelessWidget {
  final WishlistItem item;

  const _SharingSwitch({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SharedPriceViewModel>();
    if (!vm.canContribute) {
      return Text(
        'Tài khoản khách chỉ xem được; đăng nhập Google để góp giá ẩn danh.',
        style: AppTextStyles.labelMedium,
      );
    }
    return SwitchListTile(
      key: const ValueKey('share-prices-switch'),
      contentPadding: EdgeInsets.zero,
      value: vm.sharingEnabled,
      onChanged: (on) => vm.setSharingEnabled(on, item: item),
      title: const Text('Góp giá của tôi (ẩn danh)'),
      subtitle: Text(
        'Chỉ gửi giá, loại giá và ngày ghi của món có link Shopee; không gửi tên, '
        'link hay tài khoản. Giá đã góp hết hiệu lực sau ${SharedPriceSummary.windowDays} ngày.',
        style: AppTextStyles.labelMedium,
      ),
    );
  }
}
