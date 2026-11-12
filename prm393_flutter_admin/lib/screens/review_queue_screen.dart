import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';
import '../utils/formatters.dart';
import '../viewmodels/review_queue_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/reason_dialog.dart';
import '../widgets/sale_event_form_dialog.dart';
import '../widgets/status_badge.dart';

/// Review queue: sale suggestions sent from the app, approved or rejected with
/// a reason. The sender's app updates in real time.
class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  Future<void> _approve(BuildContext context, SaleSuggestion s) async {
    final vm = context.read<ReviewQueueViewModel>();
    final done = await SaleEventFormDialog.show(
      context,
      title: 'Duyệt đề xuất',
      submitLabel: 'Duyệt và đăng',
      initial: ReviewQueueViewModel.draftFor(s),
      note: s.note,
      onSubmit: (draft, _) => vm.approve(s, draft),
    );
    if (done && context.mounted) {
      showMessage(
        context,
        'Đã duyệt. Sự kiện có trong lịch sale và người gửi đã nhận tin.',
      );
    }
  }

  Future<void> _reject(BuildContext context, SaleSuggestion s) async {
    final vm = context.read<ReviewQueueViewModel>();
    final done = await ReasonDialog.show(
      context,
      suggestionName: s.name,
      onSubmit: (reason) => vm.reject(s, reason),
    );
    if (done && context.mounted) {
      showMessage(context, 'Đã từ chối. Người gửi nhận lý do trong hộp thư.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewQueueViewModel>();
    return AdminPage(
      title: 'Duyệt đề xuất',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppDimens.space8,
            children: [
              for (final status in SuggestionStatus.values)
                ChoiceChip(
                  label: Text(
                    status == SuggestionStatus.pending
                        ? '${status.label} (${vm.pendingCount})'
                        : status.label,
                  ),
                  selected: vm.tab == status,
                  onSelected: (_) => vm.setTab(status),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          Expanded(
            child: UiStateBuilder<List<SaleSuggestion>>(
              state: vm.state,
              loadingMessage: 'Đang tải đề xuất…',
              emptyIcon: Icons.fact_check_outlined,
              builder: (context, items) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppDimens.space24),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimens.space12),
                itemBuilder: (context, i) => _SuggestionCard(
                  suggestion: items[i],
                  busy: vm.isBusy(items[i].id),
                  onApprove: () => _approve(context, items[i]),
                  onReject: () => _reject(context, items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final SaleSuggestion suggestion;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SuggestionCard({
    required this.suggestion,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final pending = s.status == SuggestionStatus.pending;
    final past = DateTime(
      s.date.year,
      s.date.month,
      s.date.day,
    ).isBefore(DateUtils.dateOnly(DateTime.now()));
    final (tone, icon) = switch (s.status) {
      SuggestionStatus.pending => (BadgeTone.warning, Icons.schedule),
      SuggestionStatus.approved => (BadgeTone.success, Icons.check),
      SuggestionStatus.rejected => (BadgeTone.error, Icons.close),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: context.tokens.text(AppTextStyles.titleLarge),
                  ),
                ),
                StatusBadge(label: s.status.label, tone: tone, icon: icon),
              ],
            ),
            const SizedBox(height: AppDimens.space8),
            Wrap(
              spacing: AppDimens.space16,
              runSpacing: AppDimens.space4,
              children: [
                _Fact(
                  icon: Icons.event_outlined,
                  text:
                      'Ngày sale: ${weekdayLabel(s.date)}, ${formatDay(s.date)}',
                ),
                if (s.createdAt != null)
                  _Fact(
                    icon: Icons.schedule_send_outlined,
                    text: 'Gửi lúc ${formatDateTime(s.createdAt!)}',
                  ),
                _Fact(
                  icon: Icons.person_outline,
                  text: 'Người gửi: ${shortId(s.uid)}',
                ),
                if (past && pending)
                  const StatusBadge(
                    label: 'Ngày đã qua',
                    tone: BadgeTone.warning,
                  ),
              ],
            ),
            if (s.note != null) ...[
              const SizedBox(height: AppDimens.space12),
              MessageBox(message: 'Ghi chú: ${s.note}'),
            ],
            if (s.status == SuggestionStatus.rejected && s.reason != null) ...[
              const SizedBox(height: AppDimens.space12),
              MessageBox(
                tone: MessageTone.error,
                message: 'Lý do từ chối: ${s.reason}',
              ),
            ],
            if (s.status == SuggestionStatus.approved) ...[
              const SizedBox(height: AppDimens.space12),
              const MessageBox(
                tone: MessageTone.success,
                message: 'Đã thêm vào lịch sale (mục "Sự kiện sale").',
              ),
            ],
            if (pending) ...[
              const SizedBox(height: AppDimens.space16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppDimens.space12,
                  runSpacing: AppDimens.space8,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      title: 'Từ chối',
                      icon: Icons.close,
                      variant: AppButtonVariant.secondary,
                      width: 150,
                      isLoading: busy,
                      onPressed: onReject,
                    ),
                    AppButton(
                      title: 'Duyệt',
                      icon: Icons.check,
                      width: 150,
                      isLoading: busy,
                      onPressed: onApprove,
                    ),
                  ],
                ),
              ),
            ],
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
            style: context.tokens.text(AppTextStyles.bodyMedium),
          ),
        ),
      ],
    );
  }
}
