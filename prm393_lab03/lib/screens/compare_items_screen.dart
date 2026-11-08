import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/money_format.dart';
import '../models/price_insights.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../widgets/why_i_buy_logo.dart';

/// A-15 "So sánh các món cùng nhóm": price, motive, days saved and priority side by
/// side. Facts only; the app does not rank or pick an item.
class CompareItemsScreen extends StatelessWidget {
  final WishlistItem item;

  const CompareItemsScreen({super.key, required this.item});

  static String stars(int priority) => '★' * priority + '☆' * (5 - priority);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DecisionSupportViewModel>();
    final items = vm.sameGroupItems(item);
    final group = vm.groupName(item.budgetGroupId);
    final now = vm.now;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Text(
              'So sánh món cùng nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          Text(
            group == null
                ? 'Món chưa có nhóm ngân sách nên chưa có món cùng nhóm để so.'
                : 'Các món đang cân nhắc trong nhóm $group, đặt cạnh nhau để bạn '
                      'tự so. App không xếp hạng hay chọn giúp.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const ValueKey('compare-table'),
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Món')),
                DataColumn(label: Text('Giá'), numeric: true),
                DataColumn(label: Text('Ghi giá')),
                DataColumn(label: Text('Động cơ')),
                DataColumn(label: Text('Đã lưu'), numeric: true),
                DataColumn(label: Text('Ưu tiên')),
              ],
              rows: [
                for (final i in items)
                  DataRow(
                    selected: i.id == item.id,
                    onSelectChanged: i.id == item.id
                        ? null
                        : (_) => Navigator.pushNamed(
                            context,
                            AppRoutes.itemDetail,
                            arguments: ItemDetailArgs(i),
                          ),
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(i.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(formatVnd(i.latestPriceVnd))),
                      DataCell(
                        Text(
                          i.latestPriceAt == null
                              ? '–'
                              : PriceInsights.labelAt(i.latestPriceAt!, now),
                        ),
                      ),
                      DataCell(Text(i.displayMotive.label)),
                      DataCell(
                        Text('${now.difference(i.createdAt).inDays} ngày'),
                      ),
                      DataCell(
                        Semantics(
                          label: '${i.priority} trên 5 sao',
                          child: ExcludeSemantics(
                            child: Text(stars(i.priority)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Dòng được chọn là món bạn đang xem. Chạm dòng khác để mở món đó.',
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
