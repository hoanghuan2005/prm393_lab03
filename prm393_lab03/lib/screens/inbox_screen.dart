import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/inbox_viewmodel.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/states/ui_state_builder.dart';
import '../widgets/why_i_buy_logo.dart';

/// Hộp thư: announcements from the team and messages to this user (cross-role flow)
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  Future<void> _open(BuildContext context, InboxViewModel vm, InboxEntry e) {
    vm.markRead(e);
    return AppBottomSheet.show<void>(
      context,
      title: e.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              e.isAnnouncement ? 'Thông báo chung' : 'Tin gửi riêng cho bạn',
              if (e.createdAt != null) formatRelativeDateTime(e.createdAt!),
            ].join(' · '),
            style: AppTextStyles.labelMedium.themed(context),
          ),
          const SizedBox(height: AppDimens.space12),
          Text(e.body, style: AppTextStyles.bodyLarge.themed(context)),
          if (e.isSuggestionReply) ...[
            const SizedBox(height: AppDimens.space16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.saleSuggestion);
              },
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Xem các đợt sale bạn đã báo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InboxViewModel>();
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
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Hộp thư',
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
      body: UiStateBuilder<List<InboxEntry>>(
        state: vm.state,
        loadingMessage: 'Đang tải hộp thư...',
        emptyIcon: Icons.mark_email_read_outlined,
        builder: (context, entries) => ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => InboxTile(
            entry: entries[i],
            onTap: () => _open(context, vm, entries[i]),
          ),
        ),
      ),
    );
  }
}

/// One message row; unread ones are bold with a dot (not colour alone)
class InboxTile extends StatelessWidget {
  final InboxEntry entry;
  final VoidCallback onTap;

  const InboxTile({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final e = entry;
    return MergeSemantics(
      child: ListTile(
        key: ValueKey('inbox-${e.id}'),
        contentPadding: EdgeInsets.zero,
        minTileHeight: AppDimens.minTouchTarget,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: semantic.primaryContainer,
          child: Icon(
            e.isAnnouncement ? Icons.campaign_outlined : Icons.mail_outline,
            color: semantic.onPrimaryContainer,
          ),
        ),
        title: Text(
          e.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium
              .themed(context)
              .copyWith(
                fontWeight: e.isRead ? FontWeight.w500 : FontWeight.w800,
              ),
        ),
        subtitle: Text(
          e.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.themed(context),
        ),
        trailing: e.isRead
            ? null
            : Semantics(
                label: 'Chưa đọc',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: semantic.notificationBadge,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
      ),
    );
  }
}
