import 'package:flutter/material.dart';

import 'safe_notifier.dart';

enum AdminSection {
  dashboard('Tổng quan', Icons.insights_outlined, Icons.insights),
  users('Người dùng', Icons.people_alt_outlined, Icons.people_alt),
  saleEvents('Sự kiện sale', Icons.event_outlined, Icons.event),
  reviews('Duyệt đề xuất', Icons.fact_check_outlined, Icons.fact_check),
  announcements('Thông báo', Icons.campaign_outlined, Icons.campaign),
  codes('Mã giảm giá', Icons.sell_outlined, Icons.sell),
  vouchers('Voucher Shopee', Icons.local_offer_outlined, Icons.local_offer),
  assistant('Trợ lý AI', Icons.auto_awesome_outlined, Icons.auto_awesome);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AdminSection(this.label, this.icon, this.selectedIcon);
}

/// Which admin page is open, and light / dark mode (kept for the session).
class ShellViewModel extends ChangeNotifier with SafeNotifier {
  AdminSection _section = AdminSection.dashboard;
  ThemeMode _themeMode = ThemeMode.light;

  AdminSection get section => _section;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void goTo(AdminSection section) {
    if (section == _section) return;
    _section = section;
    notifySafely();
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifySafely();
  }
}
