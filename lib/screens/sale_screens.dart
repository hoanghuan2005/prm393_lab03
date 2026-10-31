import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/sale_event.dart';
import '../models/sale_plan.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/wishlist_card.dart';

String _countdown(SaleEvent sale, DateTime now) {
  final days = sale.daysUntil(now);
  return days == 0 ? 'Hôm nay' : 'Còn $days ngày';
}

/// "Đã xác nhận" (Shopee announced it) or "Dự kiến" (public pattern)
class _SaleStatusChip extends StatelessWidget {
  final bool confirmed;

  const _SaleStatusChip({required this.confirmed});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimens.space8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: confirmed ? AppColors.primaryContainer : AppColors.surfaceVariant,
      borderRadius: AppDimens.borderPill,
    ),
    child: Text(
      confirmed ? 'Đã xác nhận' : 'Dự kiến',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
    ),
  );
}

/// Screen 26: public sale days for the next 60 days (spec 8.2)
class SaleCalendarScreen extends StatelessWidget {
  const SaleCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DecisionSupportViewModel>();
    final sales = vm.upcomingSales;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sale')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          Text(
            'Lịch sale chung theo thông báo công khai của Shopee VN. '
            '"Đã xác nhận": Shopee đã công bố. "Dự kiến": theo lịch định kỳ '
            '(ngày đôi, ngày 15, ngày 25). App không dự đoán giá.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          if (sales.isEmpty)
            const EmptyView(
              title: 'Chưa có đợt sale nào trong 60 ngày tới',
              icon: Icons.event_busy_outlined,
            ),
          for (final sale in sales)
            Card(
              margin: const EdgeInsets.only(bottom: AppDimens.space12),
              child: ListTile(
                key: ValueKey('sale-${sale.id}'),
                minTileHeight: AppDimens.minTouchTarget,
                leading: const Icon(Icons.event_outlined),
                title: Text(sale.name, style: AppTextStyles.titleMedium),
                subtitle: Text(
                  '${formatWeekdayDate(sale.date)} · ${_countdown(sale, vm.now)}',
                ),
                trailing: _SaleStatusChip(confirmed: sale.confirmed),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.saleList,
                  arguments: SaleArgs(sale),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Danh sách cho đợt sale" (26.2, 26.3): items still being considered
class SaleListScreen extends StatelessWidget {
  final SaleEvent sale;

  const SaleListScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DecisionSupportViewModel>();
    final items = vm.consideringItems;
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách cho ${sale.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatWeekdayDate(sale.date)} · ${_countdown(sale, vm.now)}',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                _SaleStatusChip(confirmed: sale.confirmed),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyView(
                    title: 'Chưa có món nào đang cân nhắc',
                    subtitle:
                        'Lưu món bạn đang muốn mua để xem lại trước đợt sale.',
                    actionTitle: 'Thêm món',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.wishlistAdd),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                    ),
                    children: [
                      Text(
                        'Các món bạn đang cân nhắc, ưu tiên cao xếp trước. '
                        'Đợt sale không có nghĩa là phải mua.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimens.space12),
                      for (final item in items)
                        WishlistCard(
                          item: item,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.itemDetail,
                            arguments: ItemDetailArgs(item),
                          ),
                        ),
                    ],
                  ),
          ),
          if (items.isNotEmpty)
            SafeArea(
              minimum: const EdgeInsets.all(AppDimens.space16),
              child: AppButton(
                key: const ValueKey('sale-plan-button'),
                title: 'Lập kế hoạch cho đợt sale',
                icon: Icons.playlist_add_check_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.salePlan,
                  arguments: SaleArgs(sale),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Lập kế hoạch cho đợt sale" (spec 7.5): three plans that fit each group's
/// "phần khả dụng". Computed once, when the user opens it; scores are never shown.
class SalePlanScreen extends StatefulWidget {
  final SaleEvent sale;

  const SalePlanScreen({super.key, required this.sale});

  @override
  State<SalePlanScreen> createState() => _SalePlanScreenState();
}

class _SalePlanScreenState extends State<SalePlanScreen> {
  late final SalePlanResult _result;

  @override
  void initState() {
    super.initState();
    // Computed once here, not in build: the plan only changes when the user asks again
    _result = context.read<DecisionSupportViewModel>().plan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kế hoạch cho ${widget.sale.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          Text(
            'Mỗi phương án xếp các món đang cân nhắc vào phần khả dụng tháng này '
            'của từng nhóm (giá làm tròn lên 1.000 ₫). Đây là cách sắp xếp để bạn '
            'tham khảo, không phải lời khuyên mua.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          if (_result.isEmpty)
            EmptyView(
              title: 'Chưa lập được gói mua',
              subtitle: 'Cần ít nhất một món có giá thuộc nhóm đã đặt hạn mức tháng này.',
              icon: Icons.pie_chart_outline,
              actionTitle: 'Đặt ngân sách',
              onAction: () => Navigator.pushNamed(context, AppRoutes.budget),
            )
          else
            for (final plan in _result.plans) _PlanCard(plan: plan),
          if (_result.excluded.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space8),
            Text('Chưa đưa vào gói', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimens.space8),
            for (final entry in _result.excluded.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space4),
                child: Text(
                  '• ${entry.key.title} – ${entry.value.reason}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SalePlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('plan-${plan.option.name}'),
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.option.title, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimens.space4),
          Text(plan.option.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimens.space8),
          Text(
            '${plan.itemCount} món · ${formatVnd(plan.total)} '
            '/ khả dụng ${formatVnd(plan.available)}',
            style: AppTextStyles.labelLarge,
          ),
          for (final group in plan.groups) ...[
            const Divider(height: AppDimens.space24),
            Text(
              '${group.group.name}: ${formatVnd(group.total)} '
              '/ ${formatVnd(group.available)}',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppDimens.space4),
            if (group.chosen.isEmpty)
              Text(
                'Không có món nào vừa trong phần này.',
                style: AppTextStyles.bodyMedium,
              ),
            for (final item in group.chosen)
              Text(
                '• ${item.title} · ${formatVnd(item.latestPriceVnd)}',
                style: AppTextStyles.bodyMedium,
              ),
          ],
        ],
      ),
    );
  }
}
