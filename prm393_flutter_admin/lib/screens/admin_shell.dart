import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/admin_auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/push_service.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/review_queue_viewmodel.dart';
import '../viewmodels/sale_events_viewmodel.dart';
import 'announcements_screen.dart';
import 'dashboard_screen.dart';
import 'review_queue_screen.dart';
import 'sale_events_screen.dart';

/// Signed-in admin area. The ViewModels live here so they are created with the
/// admin's uid and disposed on sign-out.
class AdminShell extends StatelessWidget {
  final AdminAccount account;

  const AdminShell({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (c) => DashboardViewModel(c.read<DashboardService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => SaleEventsViewModel(
            c.read<SaleEventService>(),
            adminUid: account.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => ReviewQueueViewModel(
            c.read<SaleSuggestionService>(),
            adminUid: account.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => AnnouncementsViewModel(
            c.read<AnnouncementService>(),
            c.read<PushService>(),
            adminUid: account.uid,
          ),
        ),
      ],
      child: _ShellBody(account: account),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination(this.icon, this.selectedIcon, this.label);
}

const _destinations = [
  _Destination(Icons.insights_outlined, Icons.insights, 'Tổng quan'),
  _Destination(Icons.event_outlined, Icons.event, 'Sự kiện sale'),
  _Destination(Icons.fact_check_outlined, Icons.fact_check, 'Duyệt đề xuất'),
  _Destination(Icons.campaign_outlined, Icons.campaign, 'Thông báo'),
];

class _ShellBody extends StatefulWidget {
  final AdminAccount account;

  const _ShellBody({required this.account});

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  int _index = 0;

  void _select(int index) {
    if (index == 0 && _index != 0) {
      // Figures change after reviews: refresh when coming back to the dashboard
      context.read<DashboardViewModel>().load();
    }
    setState(() => _index = index);
  }

  Future<void> _signOut() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ quay lại màn hình đăng nhập.',
      confirmLabel: 'Đăng xuất',
    );
    if (ok && mounted) await context.read<AuthViewModel>().signOut();
  }

  Widget _icon(int i, {required bool selected, required int pending}) {
    final d = _destinations[i];
    final icon = Icon(selected ? d.selectedIcon : d.icon);
    if (i != 2 || pending == 0) return icon;
    return Badge(label: Text('$pending'), child: icon);
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ReviewQueueViewModel, int>(
      (vm) => vm.pendingCount,
    );
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    final pages = IndexedStack(
      index: _index,
      children: const [
        DashboardScreen(),
        SaleEventsScreen(),
        ReviewQueueScreen(),
        AnnouncementsScreen(),
      ],
    );

    final content = Column(
      children: [
        _TopBar(
          account: widget.account,
          onSignOut: _signOut,
          compact: !useRail,
        ),
        Expanded(child: pages),
      ],
    );

    if (!useRail) {
      return Scaffold(
        body: SafeArea(child: content),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationDestination(
                icon: _icon(i, selected: false, pending: pending),
                selectedIcon: _icon(i, selected: true, pending: pending),
                label: _destinations[i].label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: width >= 1200,
            minExtendedWidth: 232,
            selectedIndex: _index,
            onDestinationSelected: _select,
            labelType: width >= 1200 ? null : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppDimens.borderMedium,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            destinations: [
              for (var i = 0; i < _destinations.length; i++)
                NavigationRailDestination(
                  icon: _icon(i, selected: false, pending: pending),
                  selectedIcon: _icon(i, selected: true, pending: pending),
                  label: Text(_destinations[i].label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AdminAccount account;
  final VoidCallback onSignOut;
  final bool compact;

  const _TopBar({
    required this.account,
    required this.onSignOut,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Why I Buy · Quản trị',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium,
            ),
          ),
          if (!compact) ...[
            const Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimens.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                '${account.label} · ${AppRole.admin.label}',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space8),
          ],
          if (compact)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
            )
          else
            TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Đăng xuất'),
            ),
        ],
      ),
    );
  }
}
