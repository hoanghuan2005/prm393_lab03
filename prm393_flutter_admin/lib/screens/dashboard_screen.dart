import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';
import '../utils/formatters.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    return AdminPage(
      title: 'Tổng quan',
      subtitle:
          'Mỗi con số là một truy vấn tổng hợp (count / sum) chạy trên Firestore, '
          'không tải từng document về trình duyệt.',
      actions: [
        AppButton(
          title: 'Làm mới',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          width: 140,
          isLoading: vm.isLoading,
          onPressed: vm.load,
        ),
      ],
      child: UiStateBuilder<DashboardStats>(
        state: vm.state,
        loadingMessage: 'Đang tính số liệu…',
        emptyIcon: Icons.insights_outlined,
        builder: (context, stats) => _DashboardBody(stats: stats),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStats stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final skipRate = stats.skipRate;
    final cards = [
      StatCard(
        icon: Icons.people_alt_outlined,
        label: 'Tổng người dùng',
        value: '${stats.totalUsers}',
        caption: 'Đếm tài khoản đã đăng nhập vào app',
      ),
      StatCard(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Người dùng mới (7 ngày)',
        value: '${stats.newUsersLast7Days}',
        caption: 'Tạo tài khoản trong 7 ngày qua',
      ),
      StatCard(
        icon: Icons.fact_check_outlined,
        label: 'Đề xuất chờ duyệt',
        value: '${stats.pendingSuggestions}',
        caption: 'Xem ở mục "Duyệt đề xuất"',
      ),
      StatCard(
        icon: Icons.do_not_disturb_on_outlined,
        label: 'Món đã bỏ qua',
        value: '${stats.skipped}',
        caption: skipRate == null
            ? 'Chưa có món nào được quyết định'
            : 'Bằng ${(skipRate * 100).round()}% số món đã quyết định',
      ),
      StatCard(
        icon: Icons.savings_outlined,
        label: 'Giá trị tránh chi',
        value: formatVnd(stats.skippedValueVnd),
        caption:
            'Tổng giá đã ghi của ${stats.skippedWithPrice}/${stats.skipped} món '
            'bỏ qua (món chưa có giá không tính)',
      ),
      StatCard(
        icon: Icons.hourglass_bottom,
        label: 'Đang cân nhắc',
        value: '${stats.considering}',
        caption: 'Món còn trong thời gian chờ hoặc chưa quyết định',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimens.space32),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppDimens.space16;
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: AppDimens.space24),
        SectionCard(
          title: 'Kết quả cân nhắc của người dùng',
          icon: Icons.bar_chart,
          children: [
            Text(
              'Số món trong danh sách cân nhắc của mọi người dùng, theo trạng thái. '
              'App đạt mục tiêu khi tỷ lệ bỏ qua tăng: người dùng mua ít món bốc đồng hơn.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space24),
            _StatusChart(stats: stats),
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        Text(
          'Cập nhật lúc ${formatDateTime(stats.loadedAt)}',
          style: AppTextStyles.labelMedium,
        ),
      ],
    );
  }
}

class _StatusChart extends StatelessWidget {
  final DashboardStats stats;

  const _StatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Đang cân nhắc', stats.considering, AppColors.info),
      ('Đã mua', stats.purchased, AppColors.accentNeutral),
      ('Đã bỏ qua', stats.skipped, AppColors.success),
    ];
    final maxValue = bars.map((b) => b.$2).fold(0, math.max);
    final maxY = math.max(4, (maxValue * 1.2).ceil()).toDouble();
    final interval = math.max(1, (maxY / 4).ceil()).toDouble();

    return Semantics(
      label:
          'Biểu đồ cột: ${bars.map((b) => '${b.$1} ${b.$2} món').join(', ')}',
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: ExcludeSemantics(
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            bars[value.toInt()].$1,
                            style: AppTextStyles.labelLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < bars.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: bars[i].$2.toDouble(),
                            color: bars[i].$3,
                            width: 48,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimens.radiusSmall),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          // Values as text too: the chart never relies on colour alone
          Wrap(
            spacing: AppDimens.space24,
            runSpacing: AppDimens.space8,
            alignment: WrapAlignment.center,
            children: [
              for (final (label, value, color) in bars)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppDimens.borderSmall,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Text('$label: $value', style: AppTextStyles.labelLarge),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
