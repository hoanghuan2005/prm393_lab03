import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/brand_mark.dart';
import '../widgets/status_badge.dart';

/// Announcement form: writes to `announcements`, shown in every app inbox.
/// One-tap templates, a draft from the AI assistant, and a phone preview.
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

  /// Where the text in the form came from (AI draft), until it is sent or cleared
  String? _draftSource;

  @override
  void initState() {
    super.initState();
    // The preview follows what is typed
    _title.addListener(_refresh);
    _body.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _fill(String title, String body, {String? source}) {
    _title.text = title;
    _body.text = body;
    setState(() => _draftSource = source);
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
      setState(() {
        _alsoPush = false;
        _draftSource = null;
      });
    }
  }

  Future<void> _archive(Announcement item) async {
    final vm = context.read<AnnouncementsViewModel>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Lưu trữ thông báo?',
      message:
          '"${item.title}" sẽ biến mất khỏi hộp thư của app. '
          'Thông báo đã lưu trữ không đăng lại được.',
      confirmLabel: 'Lưu trữ',
    );
    if (!ok) return;
    final error = await vm.archive(item);
    if (mounted) showMessage(context, error ?? 'Đã lưu trữ.');
  }

  Widget _form(AnnouncementsViewModel vm) {
    final t = context.tokens;
    return SectionCard(
      title: 'Soạn thông báo',
      icon: Icons.edit_outlined,
      children: [
        Text(
          'Mẫu soạn sẵn (1 chạm, sửa lại trước khi đăng):',
          style: t.text(AppTextStyles.labelMedium),
        ),
        const SizedBox(height: AppDimens.space8),
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          children: [
            for (final tpl in AnnouncementsViewModel.templates)
              ActionChip(
                avatar: const Icon(Icons.flash_on_outlined, size: 18),
                label: Text(tpl.label),
                onPressed: vm.publishing
                    ? null
                    : () => _fill(tpl.title, tpl.body),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        if (_draftSource != null) ...[
          MessageBox(
            tone: MessageTone.warning,
            message:
                'Bản nháp từ $_draftSource. Hãy đọc và sửa lại trước khi đăng.',
          ),
          const SizedBox(height: AppDimens.space16),
        ],
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
                maxLines: 5,
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
                    style: t.text(AppTextStyles.labelLarge),
                  ),
                ),
              const SizedBox(height: AppDimens.space16),
              AppButton(
                title: 'Đăng thông báo',
                icon: Icons.send_outlined,
                isLoading: vm.publishing,
                onPressed: _publish,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preview() {
    final t = context.tokens;
    return SectionCard(
      title: 'Xem trước trong app',
      icon: Icons.phone_iphone,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.space12),
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: AppDimens.borderLarge,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(size: 28),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Why I Buy · Hộp thư',
                            style: t.text(AppTextStyles.labelMedium),
                          ),
                        ),
                        Text('Bây giờ', style: t.text(AppTextStyles.caption)),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      _title.text.trim().isEmpty
                          ? 'Tiêu đề thông báo…'
                          : _title.text.trim(),
                      style: t.text(AppTextStyles.labelLarge),
                    ),
                    Text(
                      _body.text.trim().isEmpty
                          ? 'Nội dung người dùng nhận được…'
                          : _body.text.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(AnnouncementsViewModel vm) {
    final t = context.tokens;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Lịch sử thông báo',
                    style: t.text(AppTextStyles.titleMedium),
                  ),
                ),
                Icon(Icons.history, color: t.textSecondary),
              ],
            ),
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
                  onArchive: () => _archive(items[i]),
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
    // A draft from the AI assistant: take it once, after this frame
    if (vm.pendingDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final draft = vm.takeDraft();
        if (draft != null && mounted) {
          _fill(draft.title, draft.body, source: draft.source);
        }
      });
    }
    return AdminPage(
      title: 'Thông báo',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 980) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(child: _form(vm)),
                  ),
                  const SizedBox(width: AppDimens.space24),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _preview(),
                        const SizedBox(height: AppDimens.space16),
                        Expanded(child: _list(vm)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppDimens.space24),
            children: [
              _form(vm),
              const SizedBox(height: AppDimens.space16),
              _preview(),
              const SizedBox(height: AppDimens.space16),
              SizedBox(height: 480, child: _list(vm)),
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
  final VoidCallback onArchive;

  const _AnnouncementTile({
    required this.item,
    required this.busy,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
                Text(item.title, style: t.text(AppTextStyles.titleMedium)),
                const SizedBox(height: AppDimens.space4),
                Text(
                  item.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.text(AppTextStyles.bodyMedium),
                ),
                const SizedBox(height: AppDimens.space8),
                Wrap(
                  spacing: AppDimens.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: item.status.label,
                      tone: published ? BadgeTone.success : BadgeTone.neutral,
                    ),
                    if (item.createdAt != null)
                      Text(
                        formatDateTime(item.createdAt!),
                        style: t.text(AppTextStyles.labelMedium),
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
          else if (published)
            IconButton(
              tooltip: 'Lưu trữ "${item.title}"',
              icon: const Icon(Icons.archive_outlined),
              onPressed: onArchive,
            ),
        ],
      ),
    );
  }
}
