import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/user_summary.dart';
import '../services/user_directory_service.dart';
import 'safe_notifier.dart';
import 'sale_events_viewmodel.dart' show foldVietnamese;

enum UserFilter {
  all('Tất cả'),
  newToday('Mới hôm nay'),
  newThisWeek('Mới 7 ngày'),
  dormant('Cài app chưa dùng'),
  team('Nhân viên & admin');

  final String label;

  const UserFilter(this.label);
}

/// Web user list: search, filters, a personal inbox message (staff and admins)
/// and role changes (admins only, never their own: firestore.rules).
class UsersViewModel extends ChangeNotifier with SafeNotifier {
  static const int maxTitle = InboxMessage.maxTitle;
  static const int maxBody = InboxMessage.maxBody;

  final UserDirectoryService _directory;
  final RoleService _roles;
  final InboxService _inbox;
  final String myUid;
  final bool isAdmin;

  /// Fixed when tests need a stable "today"
  final DateTime Function() _now;

  StreamSubscription<List<UserSummary>>? _subscription;
  List<UserSummary>? _users;
  String? _error;
  String _query = '';
  UserFilter _filter = UserFilter.all;
  final Map<String, UserActivity> _activity = {};
  final Set<String> _busy = {};

  UsersViewModel(
    this._directory,
    this._roles,
    this._inbox, {
    required this.myUid,
    required this.isAdmin,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _users = null;
    _error = null;
    _subscription = _directory.watchUsers().listen(
      (users) {
        _users = users;
        _error = null;
        notifySafely();
        if (isAdmin) _loadActivity(users);
      },
      onError: (Object e) {
        _error = describeFirestoreError(e);
        notifySafely();
      },
    );
  }

  /// Item / purchase counts for users not counted yet (admins only)
  Future<void> _loadActivity(List<UserSummary> users) async {
    final missing = [
      for (final u in users)
        if (!_activity.containsKey(u.uid)) u.uid,
    ];
    if (missing.isEmpty) return;
    try {
      final counts = await Future.wait(missing.map(_directory.activityOf));
      for (var i = 0; i < missing.length; i++) {
        _activity[missing[i]] = counts[i];
      }
      notifySafely();
    } catch (e) {
      debugPrint('User activity not loaded: $e');
    }
  }

  void retry() {
    _subscribe();
    notifySafely();
  }

  String get query => _query;
  UserFilter get filter => _filter;
  bool isBusy(String uid) => _busy.contains(uid);
  UserActivity? activityOf(String uid) => _activity[uid];

  /// Filters this account can use ("chưa dùng" needs the admin-only counts)
  List<UserFilter> get filters => [
    for (final f in UserFilter.values)
      if (f != UserFilter.dormant || isAdmin) f,
  ];

  void setQuery(String value) {
    _query = value;
    notifySafely();
  }

  void setFilter(UserFilter value) {
    _filter = value;
    notifySafely();
  }

  int countFor(UserFilter filter) =>
      _users?.where((u) => _inFilter(u, filter)).length ?? 0;

  UiState<List<UserSummary>> get state {
    final error = _error;
    if (error != null) return UiError(message: error, onRetry: retry);
    final users = _users;
    if (users == null) return const UiLoading();
    if (users.isEmpty) {
      return const UiEmpty(
        message: 'Chưa có người dùng nào đăng nhập vào app.',
      );
    }
    final q = foldVietnamese(_query.trim());
    final visible = [
      for (final u in users)
        if (_inFilter(u, _filter) &&
            (q.isEmpty ||
                foldVietnamese(
                  '${u.displayName ?? ''} ${u.email ?? ''} ${u.uid}',
                ).contains(q)))
          u,
    ];
    if (visible.isEmpty) {
      return UiEmpty(
        message: _query.trim().isEmpty
            ? 'Không có người dùng nào ở mục "${_filter.label}".'
            : 'Không có người dùng nào khớp "${_query.trim()}".',
      );
    }
    return UiSuccess(visible);
  }

  bool _inFilter(UserSummary u, UserFilter filter) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final created = u.createdAt;
    return switch (filter) {
      UserFilter.all => true,
      UserFilter.newToday => created != null && !created.isBefore(today),
      UserFilter.newThisWeek =>
        created != null &&
            !created.isBefore(now.subtract(const Duration(days: 7))),
      UserFilter.dormant => _activity[u.uid]?.isDormant ?? false,
      UserFilter.team => u.role.canUseWebAdmin,
    };
  }

  /// Admins change other people's role; nobody changes their own
  bool canChangeRole(UserSummary u) => isAdmin && u.uid != myUid;

  Future<String?> setRole(UserSummary user, AppRole role) async {
    if (!canChangeRole(user)) {
      return 'Chỉ admin đổi vai trò, và không ai tự đổi vai trò của mình.';
    }
    if (role == user.role) return null;
    _busy.add(user.uid);
    notifySafely();
    try {
      await _roles.setRole(user.uid, role);
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    } finally {
      _busy.remove(user.uid);
      notifySafely();
    }
  }

  static String? validateTitle(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Nhập tiêu đề';
    if (t.length > maxTitle) return 'Tối đa $maxTitle ký tự';
    return null;
  }

  static String? validateBody(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Nhập nội dung';
    if (t.length > maxBody) return 'Tối đa $maxBody ký tự';
    return null;
  }

  /// A personal message in the user's app inbox. Returns an error, or null.
  Future<String?> sendMessage(
    UserSummary user, {
    required String title,
    required String body,
  }) async {
    final invalid = validateTitle(title) ?? validateBody(body);
    if (invalid != null) return invalid;
    try {
      await _inbox.send(
        toUid: user.uid,
        byUid: myUid,
        title: title,
        body: body,
      );
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
