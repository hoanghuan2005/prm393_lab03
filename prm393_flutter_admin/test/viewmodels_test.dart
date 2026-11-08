import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/models/user_summary.dart';
import 'package:prm393_flutter_admin/services/admin_ai_service.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
import 'package:prm393_flutter_admin/viewmodels/ai_assistant_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/announcements_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/auth_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/dashboard_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/review_queue_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/sale_events_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/users_viewmodel.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

SaleEvent event(
  String id,
  String name,
  DateTime date, {
  SaleEventStatus status = SaleEventStatus.published,
  SaleType type = SaleType.other,
}) => SaleEvent(
  id: id,
  name: name,
  date: date,
  type: type,
  confirmed: true,
  status: status,
);

SaleSuggestion suggestion(String id, {DateTime? date}) => SaleSuggestion(
  id: id,
  uid: 'user-$id',
  name: 'Sale $id',
  date: date ?? DateTime(2026, 12, 12),
);

void main() {
  group('AuthViewModel', () {
    late FakeAuthService auth;
    late AuthViewModel vm;

    setUp(() {
      auth = FakeAuthService();
      vm = AuthViewModel(
        auth,
        FakeRoleService({
          'admin-1': AppRole.admin,
          'staff-1': AppRole.staff,
          'user-1': AppRole.user,
        }),
      );
    });

    tearDown(() => vm.dispose());

    test('an admin reaches the admin pages with the admin role', () async {
      auth.emit(const AdminAccount(uid: 'admin-1', email: 'a@x.com'));
      await pump();
      expect((vm.state as AuthAdmin).isAdmin, isTrue);
    });

    test('staff reach the admin pages too', () async {
      auth.emit(const AdminAccount(uid: 'staff-1', email: 's@x.com'));
      await pump();
      expect((vm.state as AuthAdmin).role, AppRole.staff);
    });

    test('a plain user is signed out with a clear message', () async {
      auth.emit(const AdminAccount(uid: 'user-1', email: 'u@x.com'));
      await pump();
      await pump();
      expect(auth.signOutCalls, 1);
      final state = vm.state as AuthSignedOut;
      expect(state.message, contains('u@x.com'));
      expect(state.message, contains('không phải nhân viên'));
    });

    test('a cancelled Google popup shows a message, not an error', () async {
      auth.emit(null);
      await pump();
      auth.failNextSignIn = const SignInException(SignInFailure.cancelled);
      await vm.signIn();
      expect((vm.state as AuthSignedOut).message, contains('huỷ đăng nhập'));
    });

    test('email sign-in: empty fields, wrong password, then success', () async {
      auth.emit(null);
      await pump();

      await vm.signInWithEmail('  ', '');
      expect((vm.state as AuthSignedOut).message, 'Nhập email và mật khẩu.');
      expect(auth.lastEmail, isNull);

      auth.failNextSignIn = const SignInException(
        SignInFailure.wrongCredentials,
      );
      await vm.signInWithEmail('admin@x.com', 'sai');
      expect(
        (vm.state as AuthSignedOut).message,
        'Email hoặc mật khẩu không đúng.',
      );

      await vm.signInWithEmail('admin@x.com', 'dung');
      expect(auth.lastEmail, 'admin@x.com');
      // The role check that follows is the same as for Google sign-in
      auth.emit(const AdminAccount(uid: 'admin-1', email: 'admin@x.com'));
      await pump();
      await pump();
      expect(vm.state, isA<AuthAdmin>());
    });
  });

  group('DashboardViewModel', () {
    test('admins load the activity figures, staff do not', () async {
      final service = FakeDashboardService();
      final admin = DashboardViewModel(service, isAdmin: true);
      await pump();
      final stats = (admin.state as UiSuccess).data;
      expect(stats.activity!.skipRate, closeTo(0.6, 0.001));
      expect(stats.activity!.topMotive!.key, 'emotion');

      final staff = DashboardViewModel(service, isAdmin: false);
      await pump();
      expect(service.lastIncludeActivity, isFalse);
      expect((staff.state as UiSuccess).data.activity, isNull);
    });

    test('the AI gets aggregate numbers only', () async {
      final vm = DashboardViewModel(FakeDashboardService(), isAdmin: true);
      await pump();
      final m = await vm.aiMetrics();
      expect(m.totalUsers, 12);
      expect(m.dormantUsers, 2);
      expect(m.totalWishlistItems, 15);
    });

    test('a failed aggregation becomes an error state with retry', () async {
      final service = FakeDashboardService()..error = permissionDenied();
      final vm = DashboardViewModel(service, isAdmin: true);
      await pump();
      final state = vm.state as UiError;
      expect(state.message, contains('không có quyền'));
      expect(state.onRetry, isNotNull);
    });
  });

  group('SaleEventsViewModel', () {
    late FakeSaleEventService service;
    late SaleEventsViewModel vm;

    setUp(() async {
      service = FakeSaleEventService();
      vm = SaleEventsViewModel(service, byUid: 'staff-1');
      expect(vm.state, isA<UiLoading>());
      service.controller.add([
        event('a', 'Tết Sale', DateTime(2027, 1, 20)),
        event(
          'b',
          'Siêu sale 11.11',
          DateTime(2026, 11, 11),
          type: SaleType.doubleDay,
        ),
        event(
          'c',
          'Sale cũ',
          DateTime(2026, 6, 6),
          status: SaleEventStatus.archived,
        ),
        event(
          'd',
          'Nháp 12.12',
          DateTime(2026, 12, 12),
          status: SaleEventStatus.draft,
        ),
      ]);
      await pump();
    });

    tearDown(() => vm.dispose());

    test('shows published events by default and counts every filter', () {
      final items = (vm.state as UiSuccess<List<SaleEvent>>).data;
      expect(items.map((e) => e.id), ['a', 'b']);
      expect(vm.countFor(SaleEventFilter.draft), 1);
      expect(vm.countFor(SaleEventFilter.archived), 1);
      expect(vm.countFor(SaleEventFilter.all), 4);
    });

    test('search ignores Vietnamese accents and matches the day', () {
      vm.setQuery('tet');
      expect((vm.state as UiSuccess<List<SaleEvent>>).data.single.id, 'a');
      vm.setQuery('11/11/2026');
      expect((vm.state as UiSuccess<List<SaleEvent>>).data.single.id, 'b');
      vm.setQuery('không có');
      expect(vm.state, isA<UiEmpty>());
    });

    test('refuses a second published event on the same day', () async {
      final error = await vm.save(
        SaleEventDraft(
          name: 'Trùng ngày',
          date: DateTime(2026, 11, 11, 9),
          type: SaleType.other,
          confirmed: false,
        ),
      );
      expect(error, contains('Siêu sale 11.11'));
      expect(service.created, isEmpty);
    });

    test('a draft may share a day; publishing it may not', () async {
      final draft = SaleEventDraft(
        name: 'Nháp trùng ngày',
        date: DateTime(2026, 11, 11),
        type: SaleType.other,
        confirmed: false,
      );
      expect(await vm.save(draft, publish: false), isNull);
      expect(service.created.single.$2, SaleEventStatus.draft);

      final error = await vm.setStatus(
        event(
          'x',
          'Nháp',
          DateTime(2026, 11, 11),
          status: SaleEventStatus.draft,
        ),
        SaleEventStatus.published,
      );
      expect(error, contains('Siêu sale 11.11'));
    });

    test('archiving is final', () async {
      final archived = event(
        'c',
        'Sale cũ',
        DateTime(2026, 6, 6),
        status: SaleEventStatus.archived,
      );
      expect(
        await vm.setStatus(archived, SaleEventStatus.published),
        isNotNull,
      );
      expect(service.statuses, isEmpty);
      final published = event('a', 'Tết Sale', DateTime(2027, 1, 20));
      expect(await vm.setStatus(published, SaleEventStatus.archived), isNull);
      expect(service.statuses['a'], SaleEventStatus.archived);
    });

    test('validates the name (at most 40 characters)', () {
      expect(SaleEventsViewModel.validateName('  '), isNotNull);
      expect(SaleEventsViewModel.validateName('x' * 41), isNotNull);
      expect(SaleEventsViewModel.validateName('Sale 12.12'), isNull);
    });

    test('a stream error becomes an error state with retry', () async {
      service.controller.addError(permissionDenied());
      await pump();
      expect(vm.state, isA<UiError>());
    });
  });

  group('ReviewQueueViewModel', () {
    late FakeSuggestionService service;
    late ReviewQueueViewModel vm;

    setUp(() async {
      service = FakeSuggestionService();
      vm = ReviewQueueViewModel(service, byUid: 'staff-1');
      service.controllers[SuggestionStatus.pending]!.add([
        suggestion('1'),
        suggestion('2'),
      ]);
      await pump();
    });

    tearDown(() => vm.dispose());

    test('counts pending suggestions for the navigation badge', () {
      expect(vm.pendingCount, 2);
      expect((vm.state as UiSuccess<List<SaleSuggestion>>).data, hasLength(2));
    });

    test('rejecting needs a reason', () async {
      expect(await vm.reject(suggestion('1'), '   '), isNotNull);
      expect(service.rejected, isEmpty);
      expect(await vm.reject(suggestion('1'), 'Ngày sale đã qua'), isNull);
      expect(service.rejected.single, ('1', 'Ngày sale đã qua'));
    });

    test('approving sends the edited event', () async {
      final draft = ReviewQueueViewModel.draftFor(suggestion('1'));
      expect(
        draft.type,
        SaleType.doubleDay,
      ); // 12/12 follows the double-day pattern
      expect(draft.confirmed, isFalse);
      expect(await vm.approve(suggestion('1'), draft), isNull);
      expect(service.approved.single.$1, '1');
    });

    test(
      'a suggestion already reviewed elsewhere explains the refusal',
      () async {
        service.failWrites = permissionDenied();
        final error = await vm.approve(
          suggestion('1'),
          ReviewQueueViewModel.draftFor(suggestion('1')),
        );
        expect(error, contains('admin khác'));
        expect(vm.isBusy('1'), isFalse);
      },
    );
  });

  group('UsersViewModel', () {
    late FakeUserDirectory directory;
    late FakeRoleService roles;
    late FakeInboxService inbox;
    final today = DateTime(2026, 11, 6, 15);
    final users = [
      UserSummary(
        uid: 'me',
        displayName: 'Admin',
        role: AppRole.admin,
        createdAt: DateTime(2026, 10, 1),
      ),
      UserSummary(
        uid: 'u1',
        displayName: 'Nguyễn Hoàng Huân',
        email: 'huan@x.com',
        createdAt: DateTime(2026, 11, 6, 9),
      ),
      UserSummary(
        uid: 'u2',
        displayName: 'Trần Mai',
        createdAt: DateTime(2026, 11, 2),
      ),
    ];

    UsersViewModel make({required bool isAdmin}) => UsersViewModel(
      directory,
      roles,
      inbox,
      myUid: 'me',
      isAdmin: isAdmin,
      now: () => today,
    );

    setUp(() {
      directory = FakeUserDirectory()
        ..activity['u1'] = const UserActivity(wishlistItems: 3, purchases: 1);
      roles = FakeRoleService({});
      inbox = FakeInboxService();
    });

    test('filters, accent-free search and admin-only activity', () async {
      final vm = make(isAdmin: true);
      directory.controller.add(users);
      await pump();
      await pump();
      expect(vm.countFor(UserFilter.newToday), 1);
      expect(vm.countFor(UserFilter.newThisWeek), 2);
      expect(vm.countFor(UserFilter.team), 1);
      expect(vm.countFor(UserFilter.dormant), 2); // me and u2: nothing saved
      vm.setQuery('huan');
      expect((vm.state as UiSuccess<List<UserSummary>>).data.single.uid, 'u1');

      final staff = make(isAdmin: false);
      expect(staff.filters, isNot(contains(UserFilter.dormant)));
      vm.dispose();
      staff.dispose();
    });

    test('only admins change roles, never their own', () async {
      final vm = make(isAdmin: true);
      expect(await vm.setRole(users[0], AppRole.user), isNotNull);
      expect(await vm.setRole(users[1], AppRole.staff), isNull);
      expect(roles.roles['u1'], AppRole.staff);
      final staff = make(isAdmin: false);
      expect(await staff.setRole(users[1], AppRole.admin), isNotNull);
      vm.dispose();
      staff.dispose();
    });

    test('a personal message goes to the user inbox', () async {
      final vm = make(isAdmin: false);
      expect(await vm.sendMessage(users[1], title: ' ', body: 'x'), isNotNull);
      expect(
        await vm.sendMessage(users[1], title: 'Chào bạn', body: 'Cảm ơn góp ý'),
        isNull,
      );
      expect(inbox.sent.single, ('u1', 'Chào bạn', 'Cảm ơn góp ý'));
      vm.dispose();
    });
  });

  group('AnnouncementsViewModel', () {
    test(
      'publishes to Firestore without push when no push server is set',
      () async {
        final service = FakeAnnouncementService();
        final push = FakePushService();
        final vm = AnnouncementsViewModel(service, push, byUid: 'staff-1');
        final result = await vm.publish(
          title: 'Lịch sale',
          body: 'Đã cập nhật',
          alsoPush: true,
        );
        expect(result.published, isTrue);
        expect(service.published.single, ('Lịch sale', 'Đã cập nhật'));
        expect(push.calls, 0);
        vm.dispose();
      },
    );

    test('a failed push keeps the announcement and says so', () async {
      final push = FakePushService(isConfigured: true)
        ..failure = const PushException('Không kết nối được server push.');
      final vm = AnnouncementsViewModel(
        FakeAnnouncementService(),
        push,
        byUid: 'staff-1',
      );
      final result = await vm.publish(title: 'A', body: 'B', alsoPush: true);
      expect(result.published, isTrue);
      expect(result.message, contains('thất bại'));
      expect(vm.publishing, isFalse);
      vm.dispose();
    });

    test('validates the body limit of the rules (500)', () async {
      final service = FakeAnnouncementService();
      final vm = AnnouncementsViewModel(service, FakePushService(), byUid: 's');
      final result = await vm.publish(title: 'A', body: 'b' * 501);
      expect(result.published, isFalse);
      expect(service.published, isEmpty);
      vm.dispose();
    });

    test('an archived announcement stays archived', () async {
      final service = FakeAnnouncementService();
      final vm = AnnouncementsViewModel(service, FakePushService(), byUid: 's');
      const archived = Announcement(
        id: 'n1',
        title: 'A',
        body: 'B',
        status: AnnouncementStatus.archived,
      );
      expect(await vm.archive(archived), isNotNull);
      expect(service.statuses, isEmpty);
      vm.dispose();
    });

    test('a draft from the AI is handed to the form once', () {
      final vm = AnnouncementsViewModel(
        FakeAnnouncementService(),
        FakePushService(),
        byUid: 's',
      );
      vm.prefill(const AnnouncementDraft(title: 'T', body: 'B', source: 'AI'));
      expect(vm.takeDraft()!.title, 'T');
      expect(vm.takeDraft(), isNull);
      vm.dispose();
    });
  });

  group('AiAssistantViewModel', () {
    test('always ends with a labelled result', () async {
      final vm = AiAssistantViewModel(
        AdminAiService(generator: (m, p) async => throw Exception('quota')),
        () async => const AdminAiMetrics(
          totalUsers: 1,
          newUsersToday: 0,
          activeUsersToday: 0,
          dormantUsers: 1,
          totalWishlistItems: 0,
        ),
      );
      await vm.suggest('');
      expect(vm.state, isA<UiInitial>());
      await vm.suggest('Trà sữa');
      final result = (vm.state as UiSuccess<AdminAiResult>).data;
      expect(result.fromAi, isFalse);
      expect(result.fallbackReason, 'AI đã hết lượt dùng.');
    });
  });
}
