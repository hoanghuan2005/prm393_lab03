import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/sale_events_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/sale_event_form_dialog.dart';
import '../widgets/status_badge.dart';

/// Management screen: the sale calendar the app reads (list, search, create as
/// draft or published, edit, publish, archive).
class SaleEventsScreen extends StatefulWidget {
  const SaleEventsScreen({super.key});

  @override
  State<SaleEventsScreen> createState() => _SaleEventsScreenState();
}

class _SaleEventsScreenState extends State<SaleEventsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm([SaleEvent? event]) async {
    final vm = context.read<SaleEventsViewModel>();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final saved = await SaleEventFormDialog.show(
      context,
      title: event == null ? 'Thêm sự kiện sale' : 'Sửa sự kiện sale',
      submitLabel: 'Lưu',
      askPublish: event == null,
      initial:
          event?.toDraft() ??
          SaleEventDraft(
            name: '',
            date: tomorrow,
            type: SaleType.other,
            confirmed: false,
          ),
      onSubmit: (draft, publish) =>
          vm.save(draft, id: event?.id, publish: publish),
    );
    if (saved && mounted) {
      showMessage(context, 'Đã lưu. Lịch sale trong app cập nhật ngay.');
    }
  }

  Future<void> _setStatus(SaleEvent event, SaleEventStatus status) async {
    final vm = context.read<SaleEventsViewModel>();
    if (status == SaleEventStatus.archived) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Lưu trữ sự kiện?',
        message:
            '"${event.name}" sẽ không còn hiện trong Lịch sale của app. '
            'Sự kiện đã lưu trữ không khôi phục hay sửa được nữa.',
        confirmLabel: 'Lưu trữ',
        isDanger: true,
      );
      if (!ok) return;
    }
    final error = await vm.setStatus(event, status);
    if (!mounted) return;
    showMessage(
      context,
      error ??
          (status == SaleEventStatus.published
              ? 'Đã đăng "${event.name}" lên lịch sale.'
              : 'Đã lưu trữ "${event.name}".'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SaleEventsViewModel>();
    return AdminPage(
      title: 'Sự kiện sale',
      subtitle:
          'Lịch sale người dùng thấy trong app. Nháp chỉ nhân viên thấy; '
          'sự kiện không bị xoá mà được lưu trữ.',
      actions: [
        AppButton(
          title: 'Thêm sự kiện',
          icon: Icons.add,
          width: 180,
          onPressed: _openForm,
        ),
      ],
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
                  hint: 'Tìm theo tên, loại hoặc ngày',
                  prefixIcon: Icons.search,
                  onChanged: vm.setQuery,
                ),
              ),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  for (final f in SaleEventFilter.values)
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
            child: UiStateBuilder<List<SaleEvent>>(
              state: vm.state,
              loadingMessage: 'Đang tải lịch sale…',
              emptyIcon: Icons.event_busy_outlined,
              builder: (context, events) => Card(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.space8,
                  ),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => _SaleEventRow(
                    event: events[i],
                    busy: vm.isBusy(events[i].id),
                    onEdit: () => _openForm(events[i]),
                    onStatus: (s) => _setStatus(events[i], s),
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

class _SaleEventRow extends StatelessWidget {
  final SaleEvent event;
  final bool busy;
  final VoidCallback onEdit;
  final ValueChanged<SaleEventStatus> onStatus;

  const _SaleEventRow({
    required this.event,
    required this.busy,
    required this.onEdit,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final past = event.daysUntil(DateTime.now()) < 0;
    final status = event.status;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Row(
        children: [
          _DayTile(date: event.date),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: t.text(AppTextStyles.titleMedium)),
                const SizedBox(height: AppDimens.space6),
                Wrap(
                  spacing: AppDimens.space6,
                  runSpacing: AppDimens.space6,
                  children: [
                    StatusBadge(
                      label: status.label,
                      tone: switch (status) {
                        SaleEventStatus.published => BadgeTone.primary,
                        SaleEventStatus.draft => BadgeTone.info,
                        SaleEventStatus.archived => BadgeTone.neutral,
                      },
                    ),
                    StatusBadge(label: event.type.label),
                    StatusBadge(
                      label: event.confirmed ? 'Đã xác nhận' : 'Dự kiến',
                      tone: event.confirmed
                          ? BadgeTone.success
                          : BadgeTone.neutral,
                      icon: event.confirmed ? Icons.verified_outlined : null,
                    ),
                    if (event.fromSuggestion)
                      const StatusBadge(
                        label: 'Từ đề xuất người dùng',
                        tone: BadgeTone.info,
                      ),
                    if (past)
                      const StatusBadge(
                        label: 'Đã qua',
                        tone: BadgeTone.warning,
                      ),
                  ],
                ),
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
          else if (status != SaleEventStatus.archived) ...[
            if (status == SaleEventStatus.draft)
              IconButton(
                tooltip: 'Đăng "${event.name}" lên lịch sale',
                icon: const Icon(Icons.publish_outlined),
                onPressed: () => onStatus(SaleEventStatus.published),
              ),
            IconButton(
              tooltip: 'Sửa "${event.name}"',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Lưu trữ "${event.name}"',
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => onStatus(SaleEventStatus.archived),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DateTime date;

  const _DayTile({required this.date});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Ngày ${formatDay(date)}',
      child: ExcludeSemantics(
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: AppDimens.borderMedium,
          ),
          child: Column(
            children: [
              Text(
                weekdayLabel(date),
                style: t.text(AppTextStyles.labelMedium),
              ),
              Text('${date.day}', style: t.text(AppTextStyles.headlineMedium)),
              Text(
                'Th${date.month}/${date.year % 100}',
                style: t.text(AppTextStyles.labelMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
