import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';
import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/shell_viewmodel.dart';
import '../viewmodels/users_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    return AdminPage(
      title: 'Tổng quan',
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
    final a = stats.activity;
    final cards = <Widget>[
      StatCard(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Người dùng mới hôm nay',
        value: '+${stats.newUsersToday}',
        caption: '${stats.newUsersLast7Days} người trong 7 ngày qua',
        tone: BadgeTone.success,
      ),
      if (a != null)
        StatCard(
          icon: Icons.bolt_outlined,
          label: 'Hoạt động hôm nay',
          value: '${a.activeUsersToday}',
          caption:
              'Người đã thêm món hoặc ghi khoản mua hôm nay, '
              'trên tổng ${stats.totalUsers} người',
          tone: BadgeTone.warning,
        ),
      if (a != null)
        StatCard(
          icon: Icons.person_off_outlined,
          label: 'Cài app nhưng chưa dùng',
          value: a.dormantUsers == null ? '—' : '${a.dormantUsers}',
          caption: a.dormantUsers == null
              ? 'Quá nhiều người dùng để đếm từng người'
              : '0 món cân nhắc, 0 khoản mua',
          tone: BadgeTone.error,
          chip: (a.dormantUsers ?? 0) > 0 ? 'Cần kích hoạt' : null,
        ),
      if (a != null)
        StatCard(
          icon: Icons.payments_outlined,
          label: 'Tổng chi tiêu đã ghi',
          value: formatVnd(a.totalSpendingVnd),
          caption:
              '${a.purchaseCount} khoản mua · ${a.considering} món đang cân nhắc',
          tone: BadgeTone.info,
        ),
      StatCard(
        icon: Icons.people_alt_outlined,
        label: 'Tổng người dùng',
        value: '${stats.totalUsers}',
        caption: 'Tài khoản đã đăng nhập vào app',
      ),
      StatCard(
        icon: Icons.fact_check_outlined,
        label: 'Đề xuất chờ duyệt',
        value: '${stats.pendingSuggestions}',
        caption: 'Xem ở mục "Duyệt đề xuất"',
        tone: BadgeTone.warning,
        chip: stats.pendingSuggestions > 0 ? 'Cần xử lý' : null,
      ),
      if (a != null)
        StatCard(
          icon: Icons.do_not_disturb_on_outlined,
          label: 'Món đã bỏ qua',
          value: '${a.skipped}',
          caption: a.skipRate == null
              ? 'Chưa có món nào được quyết định'
              : 'Bằng ${(a.skipRate! * 100).round()}% số món đã quyết định',
          tone: BadgeTone.success,
        ),
      if (a != null)
        StatCard(
          icon: Icons.savings_outlined,
          label: 'Giá trị tránh chi',
          value: formatVnd(a.skippedValueVnd),
          caption:
              'Giá đã ghi của ${a.skippedWithPrice}/${a.skipped} món bỏ qua '
              '(món chưa có giá không tính)',
          tone: BadgeTone.success,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimens.space32),
      children: [
        if (a == null) ...[
          const MessageBox(
            message:
                'Các chỉ số về món cân nhắc và khoản mua của người dùng chỉ admin '
                'xem được (firestore.rules). Nhân viên thấy số người dùng và đề xuất.',
          ),
          const SizedBox(height: AppDimens.space16),
        ],
        if ((a?.dormantUsers ?? 0) > 0) ...[
          _GrowthCard(dormant: a!.dormantUsers!),
          const SizedBox(height: AppDimens.space16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppDimens.space16;
            final w = constraints.maxWidth;
            final columns = w >= 1000 ? 4 : (w >= 640 ? 2 : 1);
            final rows = <Widget>[];
            for (var i = 0; i < cards.length; i += columns) {
              final rowCards = cards.sublist(
                i,
                math.min(i + columns, cards.length),
              );
              rows.add(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var j = 0; j < rowCards.length; j++) ...[
                        if (j > 0) const SizedBox(width: gap),
                        Expanded(child: rowCards[j]),
                      ],
                      for (var k = rowCards.length; k < columns; k++) ...[
                        const SizedBox(width: gap),
                        const Expanded(child: SizedBox()),
                      ],
                    ],
                  ),
                ),
              );
              if (i + columns < cards.length) {
                rows.add(const SizedBox(height: gap));
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          },
        ),
        if (a != null) ...[
          const SizedBox(height: AppDimens.space24),
          LayoutBuilder(
            builder: (context, constraints) {
              final motives = SectionCard(
                title: 'Phân bổ động cơ mua sắm',
                icon: Icons.pie_chart_outline,
                children: [_MotiveBars(activity: a)],
              );
              final outcomes = SectionCard(
                title: 'Kết quả cân nhắc của người dùng',
                icon: Icons.bar_chart,
                children: [_StatusChart(activity: a)],
              );
              if (constraints.maxWidth < 960) {
                return Column(
                  children: [
                    motives,
                    const SizedBox(height: AppDimens.space16),
                    outcomes,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: motives),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(child: outcomes),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: AppDimens.space12),
        Text(
          'Cập nhật lúc ${formatDateTime(stats.loadedAt)}',
          style: context.tokens.text(AppTextStyles.labelMedium),
        ),
      ],
    );
  }
}

/// "Cơ hội tăng trưởng": the dormant users and what staff can do about them
class _GrowthCard extends StatelessWidget {
  final int dormant;

  const _GrowthCard({required this.dormant});

  void _showUsers(BuildContext context) {
    context.read<UsersViewModel>().setFilter(UserFilter.dormant);
    context.read<ShellViewModel>().goTo(AdminSection.users);
  }

  void _askAi(BuildContext context) {
    context.read<ShellViewModel>().goTo(AdminSection.assistant);
    context.read<AiAssistantViewModel>().suggest(
      AiAssistantViewModel.topicIdeas.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(
          label: 'CƠ HỘI TĂNG TRƯỞNG',
          tone: BadgeTone.primary,
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          'Có $dormant người cài app nhưng chưa thêm món nào',
          style: t.text(AppTextStyles.titleLarge),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          'Có thể họ ngại nhập tay. Nhắc họ về tính năng chia sẻ link từ Shopee / '
          'Lazada để thêm món chỉ với một chạm.',
          style: t.text(AppTextStyles.bodyMedium),
        ),
      ],
    );
    final buttons = Wrap(
      spacing: AppDimens.space8,
      runSpacing: AppDimens.space8,
      children: [
        AppButton(
          title: 'Xem danh sách',
          icon: Icons.people_alt_outlined,
          width: 180,
          onPressed: () => _showUsers(context),
        ),
        AppButton(
          title: 'Nhờ AI soạn lời nhắn',
          icon: Icons.auto_awesome_outlined,
          variant: AppButtonVariant.secondary,
          width: 220,
          onPressed: () => _askAi(context),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: t.primaryContainer,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 760
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: AppDimens.space16),
                  buttons,
                ],
              )
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: AppDimens.space16),
                  buttons,
                ],
              ),
      ),
    );
  }
}

/// Share of purchases per motive, as labelled bars (text + value, not colour only)
class _MotiveBars extends StatelessWidget {
  final ActivityStats activity;

  const _MotiveBars({required this.activity});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = activity.motives.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Text(
        'Chưa có khoản mua nào được ghi.',
        style: t.text(AppTextStyles.bodyMedium),
      );
    }
    final rows = activity.motives.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final e in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        motiveLabels[e.key] ?? e.key,
                        style: t.text(AppTextStyles.labelLarge),
                      ),
                    ),
                    Text(
                      '${(e.value * 100 / total).round()}% · ${e.value}',
                      style: t.text(AppTextStyles.labelMedium),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space4),
                ClipRRect(
                  borderRadius: AppDimens.borderPill,
                  child: LinearProgressIndicator(
                    value: e.value / total,
                    minHeight: 8,
                    backgroundColor: t.surfaceMuted,
                    color: _motiveColor(e.key),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Tính trên $total khoản mua.',
          style: t.text(AppTextStyles.labelMedium),
        ),
      ],
    );
  }

  static Color _motiveColor(String key) => switch (key) {
    'need' => AppColors.motiveNeed,
    'want' => AppColors.motiveWant,
    'sale' => AppColors.motiveSale,
    'emotion' => AppColors.motiveEmotion,
    'social' => AppColors.motiveSocial,
    'convenience' => AppColors.motiveConvenience,
    'ads' => AppColors.motiveAds,
    _ => AppColors.motiveOther,
  };
}

class _StatusChart extends StatelessWidget {
  final ActivityStats activity;

  const _StatusChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bars = [
      ('Đang cân nhắc', activity.considering, AppColors.info),
      ('Đã mua', activity.purchased, AppColors.accentNeutral),
      ('Đã bỏ qua', activity.skipped, AppColors.success),
    ];
    final maxValue = bars.map((b) => b.$2).fold(0, math.max);
    final maxY = math.max(4, (maxValue * 1.2).ceil()).toDouble();
    final interval = math.max(1, (maxY / 4).ceil()).toDouble();

    return Semantics(
      label:
          'Biểu đồ cột: ${bars.map((b) => '${b.$1} ${b.$2} món').join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App đạt mục tiêu khi tỷ lệ bỏ qua tăng: người dùng mua ít món bốc đồng hơn.',
            style: t.text(AppTextStyles.bodyMedium),
          ),
          const SizedBox(height: AppDimens.space16),
          SizedBox(
            height: 220,
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
                        FlLine(color: t.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: t.text(AppTextStyles.labelMedium),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            bars[value.toInt()].$1,
                            style: t.text(AppTextStyles.labelMedium),
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
                            width: 40,
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
          const SizedBox(height: AppDimens.space12),
          // Values as text too: the chart never relies on colour alone
          Wrap(
            spacing: AppDimens.space16,
            runSpacing: AppDimens.space8,
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
                    const SizedBox(width: AppDimens.space6),
                    Text(
                      '$label: $value',
                      style: t.text(AppTextStyles.labelLarge),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
