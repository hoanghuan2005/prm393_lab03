import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/admin_ai_service.dart';
import '../services/admin_auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/push_service.dart';
import '../services/user_directory_service.dart';
import '../utils/tokens.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/review_queue_viewmodel.dart';
import '../viewmodels/sale_events_viewmodel.dart';
import '../viewmodels/shell_viewmodel.dart';
import '../viewmodels/users_viewmodel.dart';
import '../widgets/brand_mark.dart';
import 'ai_assistant_screen.dart';
import 'announcements_screen.dart';
import 'dashboard_screen.dart';
import 'review_queue_screen.dart';
import 'sale_events_screen.dart';
import 'users_screen.dart';

/// Signed-in area (staff and admins). The ViewModels live here so they are
/// created with the account's uid and role, and disposed on sign-out.
class AdminShell extends StatelessWidget {
  final AdminAccount account;
  final AppRole role;

  const AdminShell({super.key, required this.account, required this.role});

  bool get _isAdmin => role == AppRole.admin;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (c) =>
              DashboardViewModel(c.read<DashboardService>(), isAdmin: _isAdmin),
        ),
        ChangeNotifierProvider(
          create: (c) => UsersViewModel(
            c.read<UserDirectoryService>(),
            c.read<RoleService>(),
            c.read<InboxService>(),
            myUid: account.uid,
            isAdmin: _isAdmin,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => SaleEventsViewModel(
            c.read<SaleEventService>(),
            byUid: account.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => ReviewQueueViewModel(
            c.read<SaleSuggestionService>(),
            byUid: account.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => AnnouncementsViewModel(
            c.read<AnnouncementService>(),
            c.read<PushService>(),
            byUid: account.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => AiAssistantViewModel(
            c.read<AdminAiService>(),
            c.read<DashboardViewModel>().aiMetrics,
          ),
        ),
      ],
      child: _ShellBody(account: account, role: role),
    );
  }
}

class _ShellBody extends StatelessWidget {
  final AdminAccount account;
  final AppRole role;

  const _ShellBody({required this.account, required this.role});

  static const _pages = {
    AdminSection.dashboard: DashboardScreen(),
    AdminSection.users: UsersScreen(),
    AdminSection.saleEvents: SaleEventsScreen(),
    AdminSection.reviews: ReviewQueueScreen(),
    AdminSection.announcements: AnnouncementsScreen(),
    AdminSection.assistant: AiAssistantScreen(),
  };

  Future<void> _signOut(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ quay lại màn hình đăng nhập.',
      confirmLabel: 'Đăng xuất',
    );
    if (ok && context.mounted) await context.read<AuthViewModel>().signOut();
  }

  void _select(BuildContext context, AdminSection section) {
    final shell = context.read<ShellViewModel>();
    if (section == AdminSection.dashboard &&
        shell.section != AdminSection.dashboard) {
      // Figures change after reviews: refresh when coming back to the dashboard
      context.read<DashboardViewModel>().load();
    }
    shell.goTo(section);
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellViewModel>();
    final pending = context.select<ReviewQueueViewModel, int>(
      (vm) => vm.pendingCount,
    );
    final width = MediaQuery.sizeOf(context).width;
    final sections = AdminSection.values;
    final index = sections.indexOf(shell.section);

    final pages = IndexedStack(
      index: index,
      children: [for (final s in sections) _pages[s]!],
    );
    final content = Column(
      children: [
        _TopBar(
          account: account,
          role: role,
          compact: width < 900,
          onSignOut: () => _signOut(context),
        ),
        Expanded(child: pages),
      ],
    );

    Widget icon(AdminSection s, {required bool selected}) {
      final i = Icon(selected ? s.selectedIcon : s.icon);
      if (s != AdminSection.reviews || pending == 0) return i;
      return Badge(label: Text('$pending'), child: i);
    }

    if (width < 720) {
      return Scaffold(
        body: SafeArea(child: content),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (i) => _select(context, sections[i]),
          destinations: [
            for (final s in sections)
              NavigationDestination(
                icon: icon(s, selected: false),
                selectedIcon: icon(s, selected: true),
                label: s.label,
              ),
          ],
        ),
      );
    }

    final navigation = width >= 1100
        ? _Sidebar(
            selected: shell.section,
            pending: pending,
            onSelect: (s) => _select(context, s),
          )
        : NavigationRail(
            selectedIndex: index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => _select(context, sections[i]),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.space16),
              child: BrandMark(),
            ),
            destinations: [
              for (final s in sections)
                NavigationRailDestination(
                  icon: icon(s, selected: false),
                  selectedIcon: icon(s, selected: true),
                  label: Text(s.label),
                ),
            ],
          );

    return Scaffold(
      body: Row(
        children: [
          navigation,
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// Wide-screen sidebar: brand, menu with counters, project footer
class _Sidebar extends StatelessWidget {
  final AdminSection selected;
  final int pending;
  final ValueChanged<AdminSection> onSelect;

  const _Sidebar({
    required this.selected,
    required this.pending,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 264,
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.space20),
            child: Row(
              children: [
                const BrandMark(),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why I Buy',
                        style: t.text(AppTextStyles.titleLarge),
                      ),
                      Text(
                        'Cổng quản trị',
                        style: t.text(AppTextStyles.labelMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: t.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.space20,
              AppDimens.space20,
              AppDimens.space20,
              AppDimens.space8,
            ),
            child: Text(
              'MENU ĐIỀU HÀNH',
              style: t
                  .text(AppTextStyles.labelMedium)
                  .copyWith(letterSpacing: 0.8),
            ),
          ),
          for (final s in AdminSection.values)
            _NavItem(
              section: s,
              selected: s == selected,
              badge: switch (s) {
                AdminSection.reviews when pending > 0 => '$pending',
                AdminSection.assistant => 'Gemini',
                _ => null,
              },
              onTap: () => onSelect(s),
            ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(AppDimens.space12),
            padding: const EdgeInsets.all(AppDimens.space12),
            decoration: BoxDecoration(
              color: t.surfaceMuted,
              borderRadius: AppDimens.borderMedium,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_iphone,
                  color: AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App: Why I Buy',
                        style: t.text(AppTextStyles.labelLarge),
                      ),
                      Text(
                        'Firebase: prm393-34056',
                        style: t.text(AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AdminSection section;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.section,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space2,
      ),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? t.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.borderMedium,
            side: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: AppDimens.borderMedium,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimens.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : t.surfaceMuted,
                        borderRadius: AppDimens.borderSmall,
                      ),
                      child: Icon(
                        selected ? section.selectedIcon : section.icon,
                        size: 20,
                        color: selected ? AppColors.onPrimary : t.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Text(
                        section.label,
                        style: t
                            .text(AppTextStyles.labelLarge)
                            .copyWith(
                              color: selected ? t.textPrimary : t.textSecondary,
                            ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space6,
                          vertical: AppDimens.space2,
                        ),
                        decoration: BoxDecoration(
                          color: section == AdminSection.reviews
                              ? t.errorContainer
                              : t.warningContainer,
                          borderRadius: AppDimens.borderSmall,
                        ),
                        child: Text(
                          badge!,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: section == AdminSection.reviews
                                ? t.onErrorContainer
                                : t.onWarningContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AdminAccount account;
  final AppRole role;
  final bool compact;
  final VoidCallback onSignOut;

  const _TopBar({
    required this.account,
    required this.role,
    required this.compact,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shell = context.watch<ShellViewModel>();
    final themeLabel = shell.isDark ? 'Chế độ sáng' : 'Chế độ tối';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shell.section.label,
              overflow: TextOverflow.ellipsis,
              style: t.text(AppTextStyles.titleLarge),
            ),
          ),
          if (compact)
            IconButton(
              tooltip: themeLabel,
              onPressed: shell.toggleTheme,
              icon: Icon(shell.isDark ? Icons.light_mode : Icons.dark_mode),
            )
          else
            TextButton.icon(
              onPressed: shell.toggleTheme,
              icon: Icon(
                shell.isDark ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              label: Text(themeLabel),
            ),
          const SizedBox(width: AppDimens.space8),
          if (!compact)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space6,
                AppDimens.space4,
                AppDimens.space12,
                AppDimens.space4,
              ),
              decoration: BoxDecoration(
                color: t.surfaceMuted,
                borderRadius: AppDimens.borderPill,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      account.label.characters.first.toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      account.label,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(AppTextStyles.labelLarge),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Text(
                    role.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: t.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
