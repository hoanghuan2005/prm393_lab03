import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/spending_insight.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/reflection_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/insight_source_chip.dart';
import '../widgets/states/error_view.dart';
import 'insights_screen.dart';

/// Screen 09: Monthly Reflection + PDF report shared from the device (D7: no Cloud Storage)
class MonthlyReflectionScreen extends StatelessWidget {
  const MonthlyReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final month = context.watch<PurchaseViewModel>().selectedMonth;
    final insightsVm = context.watch<InsightsViewModel>();

    final stats = insightsVm.stats;
    final report = insightsVm.report;
    final motiveCounts = {
      for (final m in stats?.motives ?? const <MotiveStat>[]) m.motive: m.count,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Chiêm nghiệm tháng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header Card: totals computed by code, reflection written by AI or template
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppDimens.borderLarge,
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stats == null
                              ? 'Chiêm nghiệm tháng'
                              : formatMonthLabel(
                                  DateTime(stats.year, stats.month),
                                ),
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      if (report != null)
                        InsightSourceChip(fromAi: report.summaryFromAi),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    formatVnd(stats?.totalSpent ?? 0),
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Tổng đã chi từ ${stats?.purchaseCount ?? 0} khoản mua bạn đã ghi',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.space16),
                  if (insightsVm.isGenerating) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: AppDimens.space8),
                  ],
                  Text(
                    report?.summary ?? 'Chưa có dữ liệu cho tháng này.',
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                  ),
                  if (insightsVm.fallbackReason != null) ...[
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      InsightsScreen.fallbackMessage(
                        insightsVm.fallbackReason!,
                      ),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Neutral metric (spec 7.8): never presented as money saved
            if (stats != null && stats.skippedCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'Tháng này bạn đã cân nhắc và không mua ${stats.skippedCount} món, '
                  '${stats.skippedValueText}.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
            const SizedBox(height: AppDimens.space8),

            // Motives breakdown of recorded purchases in the selected month
            Text('Phân bổ 8 động cơ mua sắm', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Số khoản mua trong tháng theo động cơ bạn đã ghi:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),

            // Motives grid count
            Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              children: BuyingMotive.values.map((motive) {
                final count = motiveCounts[motive] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space12,
                    vertical: AppDimens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: motive.backgroundColor,
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: motive.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(motive.icon, size: 16, color: motive.color),
                      const SizedBox(width: AppDimens.space6),
                      Text(
                        '${motive.label}: $count',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: motive.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space32),

            const _ReflectionForm(),
            const SizedBox(height: AppDimens.space16),

            // PDF report: built on the device and shared with `printing`
            // (decision D7 – no Cloud Storage on the Spark plan)
            Text('Báo cáo PDF', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Báo cáo ${formatMonthLabel(month).toLowerCase()} được tạo ngay trên máy. '
              'Bạn chọn ứng dụng để lưu hoặc gửi.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),
            if (reportVm.status == ReportStatus.error)
              ErrorView(
                message: reportVm.errorMessage ?? 'Chưa tạo được báo cáo.',
                onRetry: () => reportVm.generateAndShare(month),
              )
            else if (reportVm.status == ReportStatus.shared) ...[
              Text(
                'Đã tạo ${ReportViewModel.fileNameFor(month)}.',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: AppDimens.space12),
            ],
            AppButton(
              title: 'Xuất và chia sẻ PDF',
              icon: Icons.ios_share,
              isLoading: reportVm.isBusy,
              onPressed: () => reportVm.generateAndShare(month),
            ),
            const SizedBox(height: AppDimens.space8),
            AppButton(
              title: 'Xem trước',
              icon: Icons.visibility_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: reportVm.isBusy ? null : () => reportVm.preview(month),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mức độ hài lòng 1–5 + mục tiêu tháng sau (handoff 09), saved through ReflectionViewModel
class _ReflectionForm extends StatefulWidget {
  const _ReflectionForm();

  @override
  State<_ReflectionForm> createState() => _ReflectionFormState();
}

class _ReflectionFormState extends State<_ReflectionForm> {
  final _goalController = TextEditingController();
  String? _loadedMonth;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save(ReflectionViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await vm.save(_goalController.text);
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            vm.actionError ?? 'Chưa lưu được chiêm nghiệm. Vui lòng chọn mức độ hài lòng rồi thử lại.',
          ),
        ),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Đã lưu chiêm nghiệm tháng ${vm.month.month}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReflectionViewModel>();

    // Fill the goal once per month with what was saved before
    final monthLabel = formatMonthLabel(vm.month);
    if (_loadedMonth != monthLabel && vm.saved != null) {
      _loadedMonth = monthLabel;
      _goalController.text = vm.saved!.goal ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.borderMedium,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mức độ hài lòng của bạn', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppDimens.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= 5; i++)
                    ChoiceChip(
                      label: Text('$i'),
                      selected: vm.rating == i,
                      onSelected: (_) => vm.selectRating(i),
                      showCheckmark: false,
                      shape: const CircleBorder(),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Không hài lòng', style: AppTextStyles.labelMedium),
                  Text('Rất hài lòng', style: AppTextStyles.labelMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.borderMedium,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu cho tháng ${vm.nextMonth.month}',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppDimens.space12),
              TextField(
                controller: _goalController,
                maxLines: 3,
                maxLength: AppConstants.noteMaxLength,
                decoration: InputDecoration(
                  hintText:
                      'Một điều bạn muốn để ý trong tháng ${vm.nextMonth.month}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        AppButton(
          title: 'Lưu chiêm nghiệm',
          icon: Icons.check,
          isLoading: vm.isSaving,
          onPressed: vm.rating == null ? null : () => _save(vm),
        ),
      ],
    );
  }
}
