import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/user_summary.dart';
import '../utils/formatters.dart';
import '../utils/tokens.dart';
import '../viewmodels/users_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_message_dialog.dart';

/// Users and their activity: search, filters, a personal message, role changes.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _message(UserSummary user) async {
    final vm = context.read<UsersViewModel>();
    final sent = await UserMessageDialog.show(
      context,
      recipient: user.label,
      onSubmit: (title, body) => vm.sendMessage(user, title: title, body: body),
    );
    if (sent && mounted) {
      showMessage(context, 'Đã gửi vào hộp thư của ${user.label}.');
    }
  }

  Future<void> _changeRole(UserSummary user, AppRole role) async {
    final vm = context.read<UsersViewModel>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Đổi vai trò?',
      message:
          '${user.label}: ${user.role.label} → ${role.label}. '
          '${role.canUseWebAdmin ? 'Tài khoản này sẽ vào được trang quản trị.' : 'Tài khoản này sẽ không vào được trang quản trị nữa.'}',
      confirmLabel: 'Đổi vai trò',
    );
    if (!ok || !mounted) return;
    final error = await vm.setRole(user, role);
    if (mounted) {
      showMessage(context, error ?? 'Đã đổi vai trò của ${user.label}.');
    }
  }

  Widget _filters(UsersViewModel vm) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Wrap(
        spacing: AppDimens.space16,
        runSpacing: AppDimens.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 340,
            child: AppTextField(
              controller: _search,
              hint: 'Tìm theo tên, email hoặc UID',
              prefixIcon: Icons.search,
              onChanged: vm.setQuery,
            ),
          ),
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              for (final f in vm.filters)
                ChoiceChip(
                  label: Text('${f.label} (${vm.countFor(f)})'),
                  selected: vm.filter == f,
                  onSelected: (_) => vm.setFilter(f),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsersViewModel>();
    final t = context.tokens;
    return AdminPage(
      title: 'Người dùng',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filters = _filters(vm);
          Widget rows(List<UserSummary> users, {required bool scroll}) {
            final wide = constraints.maxWidth >= 900;
            Widget row(int i) => _UserRow(
              user: users[i],
              wide: wide,
              onMessage: () => _message(users[i]),
              onRole: (role) => _changeRole(users[i], role),
            );
            final header = wide
                ? Container(
                    color: t.surfaceMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                      vertical: AppDimens.space12,
                    ),
                    child: const _HeaderRow(),
                  )
                : null;
            return Card(
              clipBehavior: Clip.antiAlias,
              child: scroll
                  ? Column(
                      children: [
                        ?header,
                        Expanded(
                          child: ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (_, i) => row(i),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        ?header,
                        for (var i = 0; i < users.length; i++) ...[
                          if (i > 0) const Divider(),
                          row(i),
                        ],
                      ],
                    ),
            );
          }

          Widget list({required bool scroll}) =>
              UiStateBuilder<List<UserSummary>>(
                state: vm.state,
                loadingMessage: 'Đang tải người dùng…',
                emptyIcon: Icons.people_outline,
                builder: (context, users) => rows(users, scroll: scroll),
              );

          // Short or narrow screens: filters and rows scroll together, so the
          // list never shrinks to nothing under the filters
          if (constraints.maxWidth < 720 || constraints.maxHeight < 560) {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppDimens.space24),
              children: [
                filters,
                const SizedBox(height: AppDimens.space16),
                list(scroll: false),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: AppDimens.space16),
              Expanded(child: list(scroll: true)),
              const SizedBox(height: AppDimens.space24),
            ],
          );
        },
      ),
    );
  }
}

const _flexUser = 4, _flexRole = 2, _flexJoined = 2, _flexActivity = 2;
const double _actionsWidth = 248;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = context.tokens
        .text(AppTextStyles.labelMedium)
        .copyWith(letterSpacing: 0.4);
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );
    return Row(
      children: [
        cell('NGƯỜI DÙNG', _flexUser),
        cell('VAI TRÒ', _flexRole),
        cell('THAM GIA', _flexJoined),
        cell('HOẠT ĐỘNG', _flexActivity),
        SizedBox(
          width: _actionsWidth,
          child: Text('THAO TÁC', style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserSummary user;
  final bool wide;
  final VoidCallback onMessage;
  final ValueChanged<AppRole> onRole;

  const _UserRow({
    required this.user,
    required this.wide,
    required this.onMessage,
    required this.onRole,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsersViewModel>();
    final t = context.tokens;
    final activity = vm.activityOf(user.uid);
    final now = DateTime.now();
    final isNewToday =
        user.createdAt != null &&
        !user.createdAt!.isBefore(DateTime(now.year, now.month, now.day));

    final identity = Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: t.primaryContainer,
          child: Text(
            user.label.characters.first.toUpperCase(),
            style: AppTextStyles.titleMedium.copyWith(
              color: t.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.label,
                overflow: TextOverflow.ellipsis,
                style: t.text(AppTextStyles.titleMedium),
              ),
              Text(
                user.email ?? shortId(user.uid),
                overflow: TextOverflow.ellipsis,
                style: t.text(AppTextStyles.labelMedium),
              ),
            ],
          ),
        ),
      ],
    );
    final role = Wrap(
      spacing: AppDimens.space4,
      runSpacing: AppDimens.space4,
      children: [
        StatusBadge(
          label: user.role.label,
          tone: switch (user.role) {
            AppRole.admin => BadgeTone.primary,
            AppRole.staff => BadgeTone.info,
            AppRole.user => BadgeTone.neutral,
          },
        ),
        if (isNewToday)
          const StatusBadge(label: 'Mới hôm nay', tone: BadgeTone.success),
        if (activity?.isDormant ?? false)
          const StatusBadge(label: 'Chưa dùng', tone: BadgeTone.error),
      ],
    );
    final joined = Text(
      user.createdAt == null ? '—' : formatDateTime(user.createdAt!),
      style: t.text(AppTextStyles.bodyMedium),
    );
    final usage = Text(
      activity == null
          ? (vm.isAdmin ? 'Đang đếm…' : 'Chỉ admin xem')
          : '${activity.wishlistItems} món · ${activity.purchases} khoản mua',
      style: t.text(AppTextStyles.bodyMedium),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onMessage,
          icon: const Icon(Icons.mail_outline, size: 18),
          label: const Text('Nhắn tin'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppDimens.minTouchTarget),
            foregroundColor: t.textPrimary,
            side: BorderSide(color: t.outline),
          ),
        ),
        const SizedBox(width: AppDimens.space4),
        if (vm.isBusy(user.uid))
          const Padding(
            padding: EdgeInsets.all(AppDimens.space12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          PopupMenuButton<AppRole>(
            enabled: vm.canChangeRole(user),
            tooltip: vm.canChangeRole(user)
                ? 'Đổi vai trò của ${user.label}'
                : (vm.isAdmin
                      ? 'Không tự đổi vai trò của mình'
                      : 'Chỉ admin đổi vai trò'),
            icon: const Icon(Icons.manage_accounts_outlined),
            onSelected: onRole,
            itemBuilder: (_) => [
              for (final r in AppRole.values)
                CheckedPopupMenuItem(
                  value: r,
                  checked: r == user.role,
                  child: Text(r.label),
                ),
            ],
          ),
      ],
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space12,
        ),
        child: Row(
          children: [
            Expanded(flex: _flexUser, child: identity),
            Expanded(
              flex: _flexRole,
              child: Align(alignment: Alignment.centerLeft, child: role),
            ),
            Expanded(flex: _flexJoined, child: joined),
            Expanded(flex: _flexActivity, child: usage),
            SizedBox(
              width: _actionsWidth,
              child: Align(alignment: Alignment.centerRight, child: actions),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          identity,
          const SizedBox(height: AppDimens.space8),
          role,
          const SizedBox(height: AppDimens.space8),
          Wrap(spacing: AppDimens.space16, children: [joined, usage]),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      ),
    );
  }
}
