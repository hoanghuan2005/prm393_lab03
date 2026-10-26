import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/spending_insight.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/insight_source_chip.dart';
import 'insights_screen.dart';

/// Screen 09: Monthly Reflection & Cloud Storage PDF Export
class MonthlyReflectionScreen extends StatelessWidget {
  const MonthlyReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final wishlistVm = context.watch<WishlistViewModel>();
    final reportVm = context.watch<ReportViewModel>();
    final insightsVm = context.watch<InsightsViewModel>();

    final items = wishlistVm.filteredItems;
    final totalSaved = wishlistVm.totalSavedAmount;
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
                  'tổng giá đã ghi ${formatVnd(stats.skippedValue)}.',
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

            // Cloud Storage PDF Section (Lab 3 Core Requirement)
            Text(
              'Báo cáo Cloud Storage (Firebase)',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Xuất báo cáo PDF chiêm nghiệm và upload trực tiếp lên Firebase Cloud Storage per-user path: reports/{uid}/...',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),

            // Upload Progress or Status Card
            if (reportVm.status == ReportStatus.generating ||
                reportVm.status == ReportStatus.uploading) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppDimens.borderMedium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportVm.status == ReportStatus.generating
                          ? 'Đang kết xuất tài liệu PDF...'
                          : 'Đang upload lên Firebase Cloud Storage... ${(reportVm.uploadProgress * 100).toInt()}%',
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    LinearProgressIndicator(
                      value: reportVm.uploadProgress > 0
                          ? reportVm.uploadProgress
                          : null,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            if (reportVm.status == ReportStatus.success &&
                reportVm.downloadUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppDimens.space8),
                        Text(
                          'Đã upload thành công lên Cloud Storage!',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      'Download URL:\n${reportVm.downloadUrl}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            if (reportVm.status == ReportStatus.error &&
                reportVm.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  reportVm.errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            // Export Button
            AppButton(
              title: 'Xuất & Upload báo cáo PDF',
              icon: Icons.picture_as_pdf,
              isLoading:
                  reportVm.status == ReportStatus.generating ||
                  reportVm.status == ReportStatus.uploading,
              onPressed: () async {
                final userId = authVm.userId ?? 'anonymous_test';
                await reportVm.generateAndUploadReport(
                  userId: userId,
                  userName: authVm.displayName,
                  items: items,
                  totalSaved: totalSaved,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
