import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prm393_flutter_admin/models/dashboard_stats.dart';
import 'package:prm393_flutter_admin/models/shopee_voucher.dart';
import 'package:prm393_flutter_admin/models/user_summary.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/dashboard_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
import 'package:prm393_flutter_admin/services/shopee_voucher_service.dart';
import 'package:prm393_flutter_admin/services/user_directory_service.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// Lets microtasks and stream events run
Future<void> pump() => Future<void>.delayed(Duration.zero);

FirebaseException permissionDenied() =>
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');

class FakeAuthService implements AdminAuthService {
  final _controller = StreamController<AdminAccount?>.broadcast();
  SignInException? failNextSignIn;
  int signOutCalls = 0;

  void emit(AdminAccount? account) => _controller.add(account);

  @override
  Stream<AdminAccount?> authStateChanges() => _controller.stream;

  @override
  Future<void> signInWithGoogle() async {
    final failure = failNextSignIn;
    failNextSignIn = null;
    if (failure != null) throw failure;
  }

  String? lastEmail;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    lastEmail = email;
    final failure = failNextSignIn;
    failNextSignIn = null;
    if (failure != null) throw failure;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }

  @override
  Future<String?> idToken() async => 'token';
}

class FakeRoleService implements RoleService {
  final Map<String, AppRole> roles;
  Object? failSetRole;

  FakeRoleService(this.roles);

  @override
  Future<AppRole> roleOf(String uid) async => roles[uid] ?? AppRole.user;

  @override
  Future<void> setRole(String uid, AppRole role) async {
    if (failSetRole != null) throw failSetRole!;
    roles[uid] = role;
  }
}

const sampleActivity = ActivityStats(
  considering: 5,
  purchased: 4,
  skipped: 6,
  skippedWithPrice: 4,
  skippedValueVnd: 1500000,
  purchaseCount: 9,
  totalSpendingVnd: 4820000,
  motives: {'emotion': 4, 'sale': 3, 'need': 2},
  activeUsersToday: 3,
  dormantUsers: 2,
);

class FakeDashboardService implements DashboardService {
  Object? error;
  bool? lastIncludeActivity;

  @override
  Future<DashboardStats> load({
    required bool includeActivity,
    DateTime? now,
  }) async {
    lastIncludeActivity = includeActivity;
    if (error != null) throw error!;
    return DashboardStats(
      totalUsers: 12,
      newUsersToday: 1,
      newUsersLast7Days: 3,
      pendingSuggestions: 2,
      activity: includeActivity ? sampleActivity : null,
      loadedAt: DateTime(2026, 11, 5),
    );
  }
}

class FakeUserDirectory implements UserDirectoryService {
  final controller = StreamController<List<UserSummary>>.broadcast();
  final Map<String, UserActivity> activity = {};

  @override
  Stream<List<UserSummary>> watchUsers() => controller.stream;

  @override
  Future<UserActivity> activityOf(String uid) async =>
      activity[uid] ?? const UserActivity(wishlistItems: 0, purchases: 0);
}

class FakeInboxService implements InboxService {
  final List<(String, String, String)> sent = [];

  @override
  Stream<List<InboxMessage>> watch(String uid) => const Stream.empty();

  @override
  Future<void> markRead(String uid, String messageId) async {}

  @override
  Future<void> send({
    required String toUid,
    required String byUid,
    required String title,
    required String body,
  }) async => sent.add((toUid, title, body));
}

class FakeVoucherRecordService implements VoucherRecordService {
  final controller = StreamController<List<VoucherRecord>>.broadcast();
  final List<VoucherDraft> created = [];
  final Map<String, (VoucherDraft, bool)> updated = {};
  final Map<String, bool> active = {};
  Object? failWrites;

  @override
  Stream<List<VoucherRecord>> watchAll() => controller.stream;

  @override
  Future<String> create({
    required String byUid,
    required VoucherDraft draft,
  }) async {
    if (failWrites != null) throw failWrites!;
    created.add(draft);
    return 'new-${created.length}';
  }

  @override
  Future<void> update(
    String id,
    VoucherDraft draft, {
    required bool isActive,
    required String byUid,
  }) async {
    if (failWrites != null) throw failWrites!;
    updated[id] = (draft, isActive);
  }

  @override
  Future<void> setActive(
    String id,
    bool isActive, {
    required String byUid,
  }) async {
    if (failWrites != null) throw failWrites!;
    active[id] = isActive;
  }
}

class FakeSaleEventService implements SaleEventService {
  final controller = StreamController<List<SaleEvent>>.broadcast();
  final List<(SaleEventDraft, SaleEventStatus)> created = [];
  final Map<String, SaleEventDraft> updated = {};
  final Map<String, SaleEventStatus> statuses = {};
  Object? failWrites;

  @override
  Stream<List<SaleEvent>> watchAll() => controller.stream;

  @override
  Stream<List<SaleEvent>> watchPublished() => controller.stream;

  @override
  Future<String> create({
    required String byUid,
    required SaleEventDraft draft,
    SaleEventStatus status = SaleEventStatus.published,
  }) async {
    if (failWrites != null) throw failWrites!;
    created.add((draft, status));
    return 'new-${created.length}';
  }

  @override
  Future<void> update(
    String id,
    SaleEventDraft draft, {
    required String byUid,
  }) async {
    if (failWrites != null) throw failWrites!;
    updated[id] = draft;
  }

  @override
  Future<void> setStatus(
    String id,
    SaleEventStatus status, {
    required String byUid,
  }) async {
    if (failWrites != null) throw failWrites!;
    statuses[id] = status;
  }
}

class FakeSuggestionService implements SaleSuggestionService {
  final Map<SuggestionStatus, StreamController<List<SaleSuggestion>>>
  controllers = {
    for (final s in SuggestionStatus.values) s: StreamController.broadcast(),
  };
  final List<(String, SaleEventDraft)> approved = [];
  final List<(String, String)> rejected = [];
  Object? failWrites;

  @override
  Stream<List<SaleSuggestion>> watchByStatus(SuggestionStatus status) =>
      controllers[status]!.stream;

  @override
  Stream<List<SaleSuggestion>> watchMine(String uid) => const Stream.empty();

  @override
  Future<void> submit({
    required String uid,
    required String name,
    required DateTime date,
    String? note,
  }) async {}

  @override
  Future<String> approve({
    required SaleSuggestion suggestion,
    required String byUid,
    required SaleEventDraft event,
  }) async {
    if (failWrites != null) throw failWrites!;
    approved.add((suggestion.id, event));
    return 'event-1';
  }

  @override
  Future<void> reject({
    required SaleSuggestion suggestion,
    required String byUid,
    required String reason,
  }) async {
    if (failWrites != null) throw failWrites!;
    rejected.add((suggestion.id, reason));
  }
}

class FakeAnnouncementService implements AnnouncementService {
  final controller = StreamController<List<Announcement>>.broadcast();
  final List<(String, String)> published = [];
  final Map<String, AnnouncementStatus> statuses = {};
  Object? failWrites;

  @override
  Stream<List<Announcement>> watchAll() => controller.stream;

  @override
  Stream<List<Announcement>> watchPublished() => controller.stream;

  @override
  Future<void> publish({
    required String byUid,
    required String title,
    required String body,
  }) async {
    if (failWrites != null) throw failWrites!;
    published.add((title, body));
  }

  @override
  Future<void> setStatus(String id, AnnouncementStatus status) async =>
      statuses[id] = status;
}

class FakePushService implements PushService {
  @override
  bool isConfigured;
  PushException? failure;
  int calls = 0;

  FakePushService({this.isConfigured = false});

  @override
  Future<int> broadcast({required String title, required String body}) async {
    calls++;
    if (failure != null) throw failure!;
    return 3;
  }
}

class FakeShopeeVoucherService implements ShopeeVoucherService {
  final controller = StreamController<List<ShopeeVoucher>>.broadcast();
  final List<String> deleted = [];
  Object? deleteError;

  @override
  Stream<List<ShopeeVoucher>> watchVouchers() => controller.stream;

  @override
  Future<void> delete(String id) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(id);
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    if (deleteError != null) throw deleteError!;
    deleted.addAll(ids);
  }
}
