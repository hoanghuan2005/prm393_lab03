import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/crash_reports_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';

/// "Sự cố": crash and error reports from the app, live (`crashes`). Open a row for
/// the message and stack trace; mark it resolved when it is dealt with.
class CrashesScreen extends StatefulWidget {
  const CrashesScreen({super.key});

  @override
  State<CrashesScreen> createState() => _CrashesScreenState();
}

class _CrashesScreenState extends State<CrashesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setResolved(CrashReport report, bool resolved) async {
    final error = await context.read<CrashReportsViewModel>().setResolved(
      report,
      resolved,
    );
    if (!mounted) return;
    showMessage(
      context,
      error ?? (resolved ? 'Đã đánh dấu đã xử lý.' : 'Đã mở lại báo cáo.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrashReportsViewModel>();
    final fatal = vm.openFatalCount;
    return AdminPage(
      title: 'Sự cố',
      subtitle: fatal > 0
          ? 'Có $fatal sự cố nghiêm trọng chưa xử lý. Báo cáo từ app hiện ngay, '
                'không cần mở Firebase Console.'
          : 'Báo cáo lỗi từ app hiện ngay ở đây, không cần mở Firebase Console. '
                'Chi tiết kỹ thuật vẫn nằm ở Crashlytics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppDimens.space16,
            runSpacing: AppDimens.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: AppTextField(
                  controller: _search,
                  hint: 'Tìm theo màn hình, mã lỗi hoặc người dùng',
                  prefixIcon: Icons.search,
                  onChanged: vm.setQuery,
                ),
              ),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  for (final f in CrashFilter.values)
                    ChoiceChip(
                      label: Text('${f.label} (${vm.countFor(f)})'),
                      selected: vm.filter == f,
                      onSelected: (_) => vm.setFilter(f),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          Expanded(
            child: UiStateBuilder<List<CrashReport>>(
              state: vm.state,
              loadingMessage: 'Đang tải báo cáo sự cố…',
              emptyIcon: Icons.bug_report_outlined,
              builder: (context, reports) => Card(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.space8,
                  ),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => _CrashRow(
                    report: reports[i],
                    busy: vm.isBusy(reports[i].id),
                    onResolved: (resolved) =>
                        _setResolved(reports[i], resolved),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }
}

class _CrashRow extends StatelessWidget {
  final CrashReport report;
  final bool busy;
  final ValueChanged<bool> onResolved;

  const _CrashRow({
    required this.report,
    required this.busy,
    required this.onResolved,
  });

  BadgeTone get _tone => switch (report.severity) {
    CrashSeverity.fatal => BadgeTone.error,
    CrashSeverity.error => BadgeTone.warning,
    CrashSeverity.warning => BadgeTone.info,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final time = report.createdAt;
    return Padding(
      key: ValueKey('crash-row-${report.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: AppDimens.space12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Text(
                report.feature,
                style: t.text(AppTextStyles.titleMedium),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppDimens.space6),
                child: Wrap(
                  spacing: AppDimens.space6,
                  runSpacing: AppDimens.space6,
                  children: [
                    StatusBadge(label: report.severity.label, tone: _tone),
                    StatusBadge(
                      label: report.isResolved ? 'Đã xử lý' : 'Chưa xử lý',
                      tone: report.isResolved
                          ? BadgeTone.success
                          : BadgeTone.neutral,
                    ),
                    StatusBadge(label: report.errorCode),
                    if (time != null)
                      StatusBadge(label: formatDateTime(time.toLocal())),
                    if (report.userId.isNotEmpty)
                      StatusBadge(
                        label: 'Người dùng ${shortId(report.userId)}',
                        tone: BadgeTone.info,
                      ),
                    if (report.platform.isNotEmpty)
                      StatusBadge(
                        label: report.appVersion.isEmpty
                            ? report.platform
                            : '${report.platform} · ${report.appVersion}',
                      ),
                  ],
                ),
              ),
              children: [
                if (report.errorMessage.isNotEmpty)
                  SelectableText(
                    report.errorMessage,
                    style: t.text(AppTextStyles.bodyMedium),
                  ),
                if (report.stackTrace.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.space8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: t.surfaceMuted,
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusSmall,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report.stackTrace,
                        style: t
                            .text(AppTextStyles.caption)
                            .copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(AppDimens.space12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            IconButton(
              tooltip: report.isResolved
                  ? 'Mở lại báo cáo'
                  : 'Đánh dấu đã xử lý',
              icon: Icon(
                report.isResolved ? Icons.undo : Icons.check_circle_outline,
              ),
              onPressed: () => onResolved(!report.isResolved),
            ),
        ],
      ),
    );
  }
}
