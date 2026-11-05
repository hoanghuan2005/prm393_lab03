import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prm393_flutter_admin/models/dashboard_stats.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/dashboard_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
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

  FakeRoleService(this.roles);

  @override
  Future<AppRole> roleOf(String uid) async => roles[uid] ?? AppRole.user;
}

class FakeDashboardService implements DashboardService {
  Object? error;
  DashboardStats stats = DashboardStats(
    totalUsers: 12,
    newUsersLast7Days: 3,
    pendingSuggestions: 2,
    considering: 5,
    purchased: 4,
    skipped: 6,
    skippedWithPrice: 4,
    skippedValueVnd: 1500000,
    loadedAt: DateTime(2026, 11, 5),
  );

  @override
  Future<DashboardStats> load({DateTime? now}) async {
    if (error != null) throw error!;
    return stats;
  }
}

class FakeSaleEventService implements SaleEventService {
  final controller = StreamController<List<SaleEvent>>.broadcast();
  final List<SaleEventDraft> created = [];
  final Map<String, SaleEventDraft> updated = {};
  final Map<String, SaleEventStatus> statuses = {};
  Object? failWrites;

  @override
  Stream<List<SaleEvent>> watchAll() => controller.stream;

  @override
  Stream<List<SaleEvent>> watchPublished() => controller.stream;

  @override
  Future<String> create({
    required String adminUid,
    required SaleEventDraft draft,
  }) async {
    if (failWrites != null) throw failWrites!;
    created.add(draft);
    return 'new-${created.length}';
  }

  @override
  Future<void> update(String id, SaleEventDraft draft) async {
    if (failWrites != null) throw failWrites!;
    updated[id] = draft;
  }

  @override
  Future<void> setStatus(String id, SaleEventStatus status) async {
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
    required String adminUid,
    required SaleEventDraft event,
  }) async {
    if (failWrites != null) throw failWrites!;
    approved.add((suggestion.id, event));
    return 'event-1';
  }

  @override
  Future<void> reject({
    required SaleSuggestion suggestion,
    required String adminUid,
    required String reason,
  }) async {
    if (failWrites != null) throw failWrites!;
    rejected.add((suggestion.id, reason));
  }
}

class FakeAnnouncementService implements AnnouncementService {
  final controller = StreamController<List<Announcement>>.broadcast();
  final List<(String, String)> published = [];
  Object? failWrites;

  @override
  Stream<List<Announcement>> watchAll() => controller.stream;

  @override
  Stream<List<Announcement>> watchPublished() => controller.stream;

  @override
  Future<void> publish({
    required String adminUid,
    required String title,
    required String body,
  }) async {
    if (failWrites != null) throw failWrites!;
    published.add((title, body));
  }

  @override
  Future<void> setStatus(String id, AnnouncementStatus status) async {}
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
