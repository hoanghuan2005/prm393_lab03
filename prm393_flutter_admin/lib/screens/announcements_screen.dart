import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';

/// Announcement form: writes to `announcements`, shown in every app inbox.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _alsoPush = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await context.read<AnnouncementsViewModel>().publish(
      title: _title.text,
      body: _body.text,
      alsoPush: _alsoPush,
    );
    if (!mounted) return;
    showMessage(context, result.message);
    if (result.published) {
      _formKey.currentState?.reset();
      _title.clear();
      _body.clear();
      setState(() => _alsoPush = false);
    }
  }

  Future<void> _toggleArchive(Announcement item) async {
    final vm = context.read<AnnouncementsViewModel>();
    final archive = item.status == AnnouncementStatus.published;
    if (archive) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Lưu trữ thông báo?',
        message: '"${item.title}" sẽ biến mất khỏi hộp thư của app.',
        confirmLabel: 'Lưu trữ',
      );
      if (!ok) return;
    }
    final error = await vm.setStatus(
      item,
      archive ? AnnouncementStatus.archived : AnnouncementStatus.published,
    );
    if (!mounted) return;
    showMessage(context, error ?? (archive ? 'Đã lưu trữ.' : 'Đã đăng lại.'));
  }

  Widget _form(AnnouncementsViewModel vm) {
    return SectionCard(
      title: 'Soạn thông báo',
      icon: Icons.edit_outlined,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Tiêu đề',
                hint: 'Ví dụ: Lịch sale tháng 12 đã cập nhật',
                controller: _title,
                validator: AnnouncementsViewModel.validateTitle,
              ),
              const SizedBox(height: AppDimens.space16),
              AppTextField(
                label: 'Nội dung',
                hint: 'Tối đa ${AnnouncementsViewModel.maxBody} ký tự',
                controller: _body,
                maxLines: 6,
                validator: AnnouncementsViewModel.validateBody,
              ),
              if (vm.pushAvailable)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _alsoPush,
                  onChanged: vm.publishing
                      ? null
                      : (v) => setState(() => _alsoPush = v ?? false),
                  title: Text(
                    'Gửi kèm thông báo đẩy (server push của nhóm)',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              const SizedBox(height: AppDimens.space16),
              AppButton(
                title: 'Đăng thông báo',
                icon: Icons.send_outlined,
                isLoading: vm.publishing,
                onPressed: _publish,
              ),
              const SizedBox(height: AppDimens.space12),
              Text(
                'Thông báo hiện ngay trong hộp thư của mọi người dùng đang đăng nhập app.',
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(AnnouncementsViewModel vm) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Text('Đã đăng', style: AppTextStyles.titleMedium),
          ),
          const Divider(),
          Expanded(
            child: UiStateBuilder<List<Announcement>>(
              state: vm.state,
              loadingMessage: 'Đang tải thông báo…',
              emptyIcon: Icons.campaign_outlined,
              builder: (context, items) => ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) => _AnnouncementTile(
                  item: items[i],
                  busy: vm.isBusy(items[i].id),
                  onToggleArchive: () => _toggleArchive(items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementsViewModel>();
    return AdminPage(
      title: 'Thông báo',
      subtitle: 'Gửi thông báo tới hộp thư của app. App lắng nghe Firestore nên nhận ngay, không cần server.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 960) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 420,
                    child: SingleChildScrollView(child: _form(vm)),
                  ),
                  const SizedBox(width: AppDimens.space24),
                  Expanded(child: _list(vm)),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppDimens.space24),
            children: [
              _form(vm),
              const SizedBox(height: AppDimens.space24),
              SizedBox(height: 520, child: _list(vm)),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement item;
  final bool busy;
  final VoidCallback onToggleArchive;

  const _AnnouncementTile({
    required this.item,
    required this.busy,
    required this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    final published = item.status == AnnouncementStatus.published;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppDimens.space4),
                Text(
                  item.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.space8),
                Wrap(
                  spacing: AppDimens.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: item.status.label,
                      tone: published ? BadgeTone.primary : BadgeTone.neutral,
                    ),
                    if (item.createdAt != null)
                      Text(
                        formatDateTime(item.createdAt!),
                        style: AppTextStyles.labelMedium,
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
          else
            IconButton(
              tooltip: published
                  ? 'Lưu trữ "${item.title}"'
                  : 'Đăng lại "${item.title}"',
              icon: Icon(
                published ? Icons.archive_outlined : Icons.unarchive_outlined,
              ),
              onPressed: onToggleArchive,
            ),
        ],
      ),
    );
  }
}
