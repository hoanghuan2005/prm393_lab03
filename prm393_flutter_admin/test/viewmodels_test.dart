import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/services/admin_auth_service.dart';
import 'package:prm393_flutter_admin/services/push_service.dart';
import 'package:prm393_flutter_admin/viewmodels/announcements_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/auth_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/dashboard_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/review_queue_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/sale_events_viewmodel.dart';
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
        FakeRoleService({'admin-1': AppRole.admin, 'user-1': AppRole.user}),
      );
    });

    tearDown(() => vm.dispose());

    test('an admin account reaches the admin pages', () async {
      auth.emit(const AdminAccount(uid: 'admin-1', email: 'a@x.com'));
      await pump();
      expect(vm.state, isA<AuthAdmin>());
    });

    test('a non-admin account is signed out with a clear message', () async {
      auth.emit(const AdminAccount(uid: 'user-1', email: 'u@x.com'));
      await pump();
      await pump();
      expect(auth.signOutCalls, 1);
      final state = vm.state as AuthSignedOut;
      expect(state.message, contains('u@x.com'));
      expect(state.message, contains('không có quyền quản trị'));
    });

    test('a cancelled Google popup shows a message, not an error', () async {
      auth.emit(null);
      await pump();
      auth.failNextSignIn = const SignInException(SignInFailure.cancelled);
      await vm.signIn();
      expect((vm.state as AuthSignedOut).message, contains('huỷ đăng nhập'));
    });
  });

  group('DashboardViewModel', () {
    test('loads the figures', () async {
      final vm = DashboardViewModel(FakeDashboardService());
      await pump();
      final stats = (vm.state as UiSuccess).data;
      expect(stats.skipRate, closeTo(0.6, 0.001));
    });

    test('a failed aggregation becomes an error state with retry', () async {
      final service = FakeDashboardService()..error = permissionDenied();
      final vm = DashboardViewModel(service);
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
      vm = SaleEventsViewModel(service, adminUid: 'admin-1');
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
      ]);
      await pump();
    });

    tearDown(() => vm.dispose());

    test('shows published events by default and counts every filter', () {
      final items = (vm.state as UiSuccess<List<SaleEvent>>).data;
      expect(items.map((e) => e.id), ['a', 'b']);
      expect(vm.countFor(SaleEventFilter.archived), 1);
      expect(vm.countFor(SaleEventFilter.all), 3);
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

    test('editing an event may keep its own day', () async {
      final error = await vm.save(
        SaleEventDraft(
          name: 'Siêu sale 11.11 (sửa)',
          date: DateTime(2026, 11, 11),
          type: SaleType.doubleDay,
          confirmed: true,
        ),
        id: 'b',
      );
      expect(error, isNull);
      expect(service.updated['b']!.name, 'Siêu sale 11.11 (sửa)');
    });

    test('validates the name', () async {
      expect(SaleEventsViewModel.validateName('  '), isNotNull);
      expect(SaleEventsViewModel.validateName('x' * 61), isNotNull);
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
      vm = ReviewQueueViewModel(service, adminUid: 'admin-1');
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
      final error = await vm.reject(suggestion('1'), '   ');
      expect(error, isNotNull);
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

    test('other tabs load their own list', () async {
      vm.setTab(SuggestionStatus.rejected);
      expect(vm.state, isA<UiLoading>());
      service.controllers[SuggestionStatus.rejected]!.add([]);
      await pump();
      expect(vm.state, isA<UiEmpty>());
    });
  });

  group('AnnouncementsViewModel', () {
    test(
      'publishes to Firestore without push when no push server is set',
      () async {
        final service = FakeAnnouncementService();
        final push = FakePushService();
        final vm = AnnouncementsViewModel(service, push, adminUid: 'admin-1');
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
      final service = FakeAnnouncementService();
      final push = FakePushService(isConfigured: true)
        ..failure = const PushException('Không kết nối được server push.');
      final vm = AnnouncementsViewModel(service, push, adminUid: 'admin-1');
      final result = await vm.publish(title: 'A', body: 'B', alsoPush: true);
      expect(result.published, isTrue);
      expect(result.message, contains('thất bại'));
      expect(vm.publishing, isFalse);
      vm.dispose();
    });

    test('validates title and body before writing', () async {
      final service = FakeAnnouncementService();
      final vm = AnnouncementsViewModel(
        service,
        FakePushService(),
        adminUid: 'admin-1',
      );
      final result = await vm.publish(title: ' ', body: 'B');
      expect(result.published, isFalse);
      expect(service.published, isEmpty);
      vm.dispose();
    });
  });
}
