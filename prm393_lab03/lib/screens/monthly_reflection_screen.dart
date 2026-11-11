import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/spending_insight.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/reflection_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/insight_source_chip.dart';
import '../widgets/states/error_view.dart';
import '../widgets/why_i_buy_logo.dart';
import 'insights_screen.dart';

/// Screen 09: Monthly Reflection + PDF report shared from the device (D7: no Cloud Storage)
class MonthlyReflectionScreen extends StatefulWidget {
  const MonthlyReflectionScreen({super.key});

  @override
  State<MonthlyReflectionScreen> createState() =>
      _MonthlyReflectionScreenState();
}

class _MonthlyReflectionScreenState extends State<MonthlyReflectionScreen> {
  final _formKey = GlobalKey<_ReflectionFormState>();
  bool _allowExit = false;
  bool _confirmingExit = false;

  Future<void> _back() async {
    if (_confirmingExit || context.read<ReflectionViewModel>().isSaving) return;
    _confirmingExit = true;
    final discard =
        _formKey.currentState?.hasChanges != true ||
        await ConfirmDialog.show(
          context,
          title: 'Bỏ chiêm nghiệm đang nhập?',
          message: 'Mục tiêu hoặc mức độ hài lòng vừa nhập chưa được lưu.',
          confirmLabel: 'Bỏ thay đổi',
        );
    _confirmingExit = false;
    if (!mounted || !discard) return;
    context.read<ReflectionViewModel>().discardChanges();
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.maybePop(context);
  }

  Future<void> _exitAfterSave() async {
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.maybePop(context);
  }

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

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: PopScope(
          canPop: _allowExit,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            tooltip: 'Quay lại',
            onPressed: _back,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Chiêm nghiệm tháng',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Edge-to-edge (Android 15+): the last buttons stay above the navigation bar
        padding: EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header Card: totals computed by code, reflection written by AI or template
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                color: AppSemanticColors.of(context).primaryContainer,
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
                          style: AppTextStyles.titleMedium.themed(context),
                        ),
                      ),
                      if (report != null)
                        InsightSourceChip(fromAi: report.summaryFromAi),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    formatVnd(stats?.totalSpent ?? 0),
                    style: AppTextStyles.headlineLarge
                        .themed(context)
                        .copyWith(
                          color: AppSemanticColors.of(context)
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Tổng đã chi từ ${stats?.purchaseCount ?? 0} khoản mua bạn đã ghi',
                    style: AppTextStyles.bodyMedium.themed(context),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  if (insightsVm.isGenerating) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: AppDimens.space8),
                  ],
                  Text(
                    report?.summary ?? 'Chưa có dữ liệu cho tháng này.',
                    style: AppTextStyles.bodyLarge
                        .themed(context)
                        .copyWith(height: 1.5),
                  ),
                  if (insightsVm.fallbackReason != null) ...[
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      InsightsScreen.fallbackMessage(
                        insightsVm.fallbackReason!,
                      ),
                      style: AppTextStyles.caption.themed(context),
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
                  color: AppSemanticColors.of(context).cardSurface,
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: AppSemanticColors.of(context).divider,
                  ),
                ),
                child: Text(
                  'Tháng này bạn đã cân nhắc và không mua ${stats.skippedCount} món, '
                  '${stats.skippedValueText}.',
                  style: AppTextStyles.bodyMedium.themed(context),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
            const SizedBox(height: AppDimens.space8),

            // Motives breakdown of recorded purchases in the selected month
            Text(
              'Phân bổ 8 động cơ mua sắm',
              style: AppTextStyles.titleLarge.themed(context),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Số khoản mua trong tháng theo động cơ bạn đã ghi:',
              style: AppTextStyles.bodyMedium.themed(context),
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
                    color: MotiveColors.of(context)
                        .paletteOf(motive)
                        .background,
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: MotiveColors.of(context)
                          .paletteOf(motive)
                          .foreground
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        motive.icon,
                        size: 16,
                        color: MotiveColors.of(context)
                            .paletteOf(motive)
                            .foreground,
                      ),
                      const SizedBox(width: AppDimens.space6),
                      Text(
                        '${motive.label}: $count',
                        style: AppTextStyles.labelMedium
                            .themed(context)
                            .copyWith(
                              color: MotiveColors.of(context)
                                  .paletteOf(motive)
                                  .foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space32),

            _ReflectionForm(key: _formKey, onSaved: _exitAfterSave),
            const SizedBox(height: AppDimens.space16),

            // PDF report: built on the device and shared with `printing`
            // (decision D7 – no Cloud Storage on the Spark plan)
            Text(
              'Báo cáo PDF',
              style: AppTextStyles.titleLarge.themed(context),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Báo cáo ${formatMonthLabel(month).toLowerCase()} được tạo ngay trên máy. '
              'Bạn chọn ứng dụng để lưu hoặc gửi.',
              style: AppTextStyles.bodyMedium.themed(context),
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
                style: AppTextStyles.labelMedium.themed(context),
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
  final Future<void> Function() onSaved;

  const _ReflectionForm({super.key, required this.onSaved});

  @override
  State<_ReflectionForm> createState() => _ReflectionFormState();
}

class _ReflectionFormState extends State<_ReflectionForm> {
  final _goalController = TextEditingController();
  String? _loadedMonth;
  String _baselineGoal = '';
  bool _loadedFromSaved = false;
  final Map<String, String> _draftGoals = {};

  bool get hasChanges =>
      _goalController.text != _baselineGoal ||
      context.read<ReflectionViewModel>().rating !=
          context.read<ReflectionViewModel>().saved?.rating;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save(ReflectionViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
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
    await widget.onSaved();
    messenger.showSnackBar(
      SnackBar(content: Text('Đã lưu chiêm nghiệm tháng ${vm.month.month}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReflectionViewModel>();

    // Keep an unsaved goal when the selected month changes and restore it on return.
    final monthLabel = formatMonthLabel(vm.month);
    if (_loadedMonth != monthLabel) {
      if (_loadedMonth != null && _goalController.text != _baselineGoal) {
        _draftGoals[_loadedMonth!] = _goalController.text;
      }
      _loadedMonth = monthLabel;
      _loadedFromSaved = vm.saved != null;
      _baselineGoal = vm.saved?.goal ?? '';
      _goalController.text = _draftGoals[monthLabel] ?? _baselineGoal;
    } else if (!_loadedFromSaved && vm.saved != null) {
      _loadedFromSaved = true;
      final savedGoal = vm.saved!.goal ?? '';
      if (_goalController.text == _baselineGoal) {
        _goalController.text = savedGoal;
      }
      _baselineGoal = savedGoal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppSemanticColors.of(context).cardSurface,
            borderRadius: AppDimens.borderMedium,
            border: Border.all(color: AppSemanticColors.of(context).cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mức độ hài lòng của bạn',
                style: AppTextStyles.titleMedium.themed(context),
              ),
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
                      backgroundColor: AppSemanticColors.of(context)
                          .mutedSurface,
                      labelStyle: AppTextStyles.labelLarge
                          .themed(context)
                          .copyWith(
                            color: vm.rating == i
                                ? AppColors.onPrimary
                                : AppSemanticColors.of(context).textPrimary,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.space8),
              Wrap(
                spacing: AppDimens.space16,
                runSpacing: AppDimens.space8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Không hài lòng',
                    style: AppTextStyles.labelMedium.themed(context),
                  ),
                  Text(
                    'Rất hài lòng',
                    style: AppTextStyles.labelMedium.themed(context),
                  ),
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
            color: AppSemanticColors.of(context).cardSurface,
            borderRadius: AppDimens.borderMedium,
            border: Border.all(color: AppSemanticColors.of(context).cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu cho tháng ${vm.nextMonth.month}',
                style: AppTextStyles.titleMedium.themed(context),
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
        // The rules need a rating: say why the button is off instead of a dead button
        if (vm.rating == null) ...[
          Text(
            'Chọn mức độ hài lòng để lưu chiêm nghiệm.',
            style: AppTextStyles.bodyMedium.themed(context),
          ),
          const SizedBox(height: AppDimens.space8),
        ],
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
