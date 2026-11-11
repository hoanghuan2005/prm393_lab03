import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/screens/inbox_screen.dart';
import 'package:prm393_lab03/screens/sale_suggestion_screen.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/inbox_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/sale_suggestion_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart' as core;

import 'support/test_theme.dart';

/// Cross-role flow, mobile side (plan X-5). The staff side runs through the same
/// `packages/core` service the web admin uses, on one fake Firestore.

const _uid = 'user-a';
const _staff = 'staff-1';
final _today = DateTime(2026, 11, 11, 9);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

SaleSuggestionViewModel _suggestions(
  FakeFirebaseFirestore db, {
  String? uid = _uid,
  bool anonymous = false,
}) => SaleSuggestionViewModel(
  service: core.FirestoreSaleSuggestionService(db),
  now: () => _today,
)..updateUser(uid, isAnonymous: anonymous);

InboxViewModel _inbox(FakeFirebaseFirestore db, {String? uid = _uid}) =>
    InboxViewModel(
      announcementService: core.FirestoreAnnouncementService(db),
      inboxService: core.FirestoreInboxService(db),
      preferencesService: PreferencesService(),
    )..updateUid(uid);

class _NoAi implements AiService {
  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) => throw UnimplementedError();

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => throw UnimplementedError();

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) => throw UnimplementedError();
}

/// Remote Config `sale_calendar` says 11.11 is only expected
class _Config extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => true;

  @override
  String getString(String key) => key == RemoteConfigService.keySaleCalendar
      ? '[{"date":"2026-11-20","name":"Theo Remote Config","type":"other","confirmed":false}]'
      : '';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('X-2: "Báo đợt sale"', () {
    test(
      'a report is saved pending, with only the fields the rules allow',
      () async {
        final db = FakeFirebaseFirestore();
        final vm = _suggestions(db);
        await _settle();
        expect(vm.canSuggest, isTrue);
        expect(vm.mine, isA<UiEmpty<List<core.SaleSuggestion>>>());

        final ok = await vm.submit(
          name: '  12.12 Sale sinh nhật ',
          date: DateTime(2026, 12, 12),
          source: 'https://shopee.vn/m/12-12',
        );
        expect(ok, isTrue);
        await _settle();

        final docs = (await db.collection('saleSuggestions').get()).docs;
        expect(docs, hasLength(1));
        final data = docs.single.data();
        expect(data.keys.toSet(), {
          'uid',
          'name',
          'date',
          'note',
          'status',
          'createdAt',
        });
        expect(data['uid'], _uid);
        expect(data['name'], '12.12 Sale sinh nhật');
        expect(data['status'], 'pending');
        expect(data['note'], 'https://shopee.vn/m/12-12');

        final mine = vm.mine as UiSuccess<List<core.SaleSuggestion>>;
        expect(mine.data.single.status, core.SuggestionStatus.pending);
        vm.dispose();
      },
    );

    test('guests cannot report: the rules refuse anonymous accounts', () async {
      final db = FakeFirebaseFirestore();
      final vm = _suggestions(db, uid: 'anon', anonymous: true);
      await _settle();
      expect(vm.canSuggest, isFalse);
      expect(vm.isGuest, isTrue);
      expect(
        await vm.submit(
          name: '12.12',
          date: DateTime(2026, 12, 12),
          source: 'x',
        ),
        isFalse,
      );
      expect(vm.actionError, contains('Google'));
      expect((await db.collection('saleSuggestions').get()).docs, isEmpty);
      vm.dispose();
    });

    test('name, day and source are checked before anything is sent', () async {
      final db = FakeFirebaseFirestore();
      final vm = _suggestions(db);
      await _settle();

      expect(SaleSuggestionViewModel.validateName(''), isNotNull);
      expect(SaleSuggestionViewModel.validateName('a' * 41), isNotNull);
      expect(SaleSuggestionViewModel.validateName('11.11'), isNull);
      expect(SaleSuggestionViewModel.validateSource(' '), isNotNull);
      expect(SaleSuggestionViewModel.validateSource('a' * 201), isNotNull);
      expect(vm.validateDate(null), isNotNull);
      expect(vm.validateDate(DateTime(2026, 11, 10)), 'Đợt sale này đã qua.');
      expect(vm.validateDate(DateTime(2026, 11, 11)), isNull);
      expect(vm.validateDate(DateTime(2027, 11, 12)), isNotNull);

      expect(
        await vm.submit(
          name: '11.11',
          date: DateTime(2026, 11, 1),
          source: 'x',
        ),
        isFalse,
      );
      expect((await db.collection('saleSuggestions').get()).docs, isEmpty);
      vm.dispose();
    });

    test('the same pending report is not sent twice', () async {
      final db = FakeFirebaseFirestore();
      final vm = _suggestions(db);
      await _settle();
      final date = DateTime(2026, 12, 12);
      expect(await vm.submit(name: '12.12', date: date, source: 'x'), isTrue);
      await _settle();
      expect(
        await vm.submit(name: ' 12.12 ', date: date, source: 'y'),
        isFalse,
      );
      expect(vm.actionError, contains('đang chờ'));
      expect((await db.collection('saleSuggestions').get()).docs, hasLength(1));
      vm.dispose();
    });

    test('another user\'s reports are never listed', () async {
      final db = FakeFirebaseFirestore();
      final other = _suggestions(db, uid: 'user-b');
      await other.submit(
        name: '12.12',
        date: DateTime(2026, 12, 12),
        source: 'x',
      );
      final vm = _suggestions(db);
      await _settle();
      expect(vm.mine, isA<UiEmpty<List<core.SaleSuggestion>>>());
      vm.dispose();
      other.dispose();
    });
  });

  group('X-2 → web → X-3 / X-4: the whole loop on one Firestore', () {
    late FakeFirebaseFirestore db;
    late SaleSuggestionViewModel suggestions;
    late InboxViewModel inbox;
    late DecisionSupportViewModel sales;

    setUp(() async {
      db = FakeFirebaseFirestore();
      suggestions = _suggestions(db);
      inbox = _inbox(db);
      sales = DecisionSupportViewModel(
        budgetService: FirestoreBudgetService(db),
        wishlistService: FirestoreWishlistService(db),
        aiDecisionService: AiDecisionService(generator: _NoAi()),
        remoteConfigService: RemoteConfigService(remoteConfig: _Config()),
        preferencesService: PreferencesService(),
        saleEventService: core.FirestoreSaleEventService(db),
        platformSupportsAi: () => false,
        now: () => _today,
      )..updateUid(_uid);
      await _settle();
    });

    tearDown(() {
      suggestions.dispose();
      inbox.dispose();
      sales.dispose();
    });

    Future<core.SaleSuggestion> report() async {
      await suggestions.submit(
        name: 'Sale 20.11',
        date: DateTime(2026, 11, 20),
        source: 'Banner trên app Shopee',
      );
      await _settle();
      return (suggestions.mine as UiSuccess<List<core.SaleSuggestion>>)
          .data
          .single;
    }

    test(
      'approved: the sale is in Lịch sale and the answer in Hộp thư',
      () async {
        final s = await report();
        expect(inbox.unreadCount, 0);

        // Staff on the web admin (same core service as review_queue_viewmodel)
        await core.FirestoreSaleSuggestionService(db).approve(
          suggestion: s,
          byUid: _staff,
          event: core.SaleEventDraft(
            name: s.name,
            date: s.date,
            type: core.SaleType.other,
            confirmed: true,
          ),
        );
        await _settle();

        final mine = suggestions.mine as UiSuccess<List<core.SaleSuggestion>>;
        expect(mine.data.single.status, core.SuggestionStatus.approved);

        // The published event replaces Remote Config's on the same day
        final day = sales.upcomingSales.where(
          (e) => SaleEvent.dayId(e.date) == '2026-11-20',
        );
        expect(day.single.name, 'Sale 20.11');
        expect(day.single.confirmed, isTrue);

        expect(inbox.unreadCount, 1);
        final entry = (inbox.state as UiSuccess<List<InboxEntry>>).data.single;
        expect(entry.isSuggestionReply, isTrue);
        expect(entry.title, 'Đề xuất sale đã được duyệt');

        await inbox.markRead(entry);
        await _settle();
        expect(inbox.unreadCount, 0);
        final saved = await db.collection('users/$_uid/inbox').get();
        expect(saved.docs.single.data()['readAt'], isA<Timestamp>());
      },
    );

    test(
      'rejected: the reason reaches the user, nothing is published',
      () async {
        final s = await report();
        await core.FirestoreSaleSuggestionService(db).reject(
          suggestion: s,
          byUid: _staff,
          reason: 'Shopee chưa công bố đợt này',
        );
        await _settle();

        final mine = suggestions.mine as UiSuccess<List<core.SaleSuggestion>>;
        expect(mine.data.single.status, core.SuggestionStatus.rejected);
        expect(mine.data.single.reason, 'Shopee chưa công bố đợt này');
        expect(inbox.unreadCount, 1);
        expect(
          sales.upcomingSales
              .where((e) => SaleEvent.dayId(e.date) == '2026-11-20')
              .single
              .name,
          'Theo Remote Config',
        );
      },
    );

    test('a draft event is not shown; archiving takes it away', () async {
      final events = core.FirestoreSaleEventService(db);
      final draft = core.SaleEventDraft(
        name: 'Nháp 22.11',
        date: DateTime(2026, 11, 22),
        type: core.SaleType.other,
        confirmed: true,
      );
      final id = await events.create(
        byUid: _staff,
        draft: draft,
        status: core.SaleEventStatus.draft,
      );
      await _settle();
      expect(sales.upcomingSales.any((e) => e.name == 'Nháp 22.11'), isFalse);

      await events.setStatus(id, core.SaleEventStatus.published, byUid: _staff);
      await _settle();
      expect(sales.upcomingSales.any((e) => e.name == 'Nháp 22.11'), isTrue);

      await events.setStatus(id, core.SaleEventStatus.archived, byUid: _staff);
      await _settle();
      expect(sales.upcomingSales.any((e) => e.name == 'Nháp 22.11'), isFalse);
    });
  });

  group('X-3: Hộp thư', () {
    test('announcements and personal messages, newest first', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('announcements').add({
        'title': 'Cũ',
        'body': 'a',
        'status': 'published',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      await db.collection('announcements').add({
        'title': 'Đã lưu trữ',
        'body': 'b',
        'status': 'archived',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 9)),
      });
      await db.collection('users/$_uid/inbox').add({
        'title': 'Tin riêng',
        'body': 'c',
        'kind': 'message',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 5)),
      });
      final vm = _inbox(db);
      await _settle();

      final list = (vm.state as UiSuccess<List<InboxEntry>>).data;
      expect(list.map((e) => e.title), ['Tin riêng', 'Cũ']);
      expect(vm.unreadCount, 2);

      // An announcement is read on this device only
      await vm.markRead(list.last);
      expect(vm.unreadCount, 1);
      expect(await PreferencesService().getReadAnnouncements(), {list.last.id});

      // Remembered after a restart
      final again = _inbox(db);
      await _settle();
      expect(again.unreadCount, 1);
      vm.dispose();
      again.dispose();
    });

    test('empty, then signed out', () async {
      final db = FakeFirebaseFirestore();
      final vm = _inbox(db);
      await _settle();
      expect(vm.state, isA<UiEmpty<List<InboxEntry>>>());
      vm.updateUid(null);
      await _settle();
      expect(vm.state, isA<UiInitial<List<InboxEntry>>>());
      expect(vm.unreadCount, 0);
      vm.dispose();
    });
  });

  group('X-5: screens', () {
    Widget wrap(Widget child, List<ChangeNotifier> vms) => MultiProvider(
      providers: [
        for (final vm in vms)
          if (vm is SaleSuggestionViewModel)
            ChangeNotifierProvider<SaleSuggestionViewModel>.value(value: vm)
          else if (vm is InboxViewModel)
            ChangeNotifierProvider<InboxViewModel>.value(value: vm),
      ],
      child: MaterialApp(
        theme: testAppTheme,
        home: child,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );

    testWidgets('guest sees why the form is missing', (tester) async {
      final vm = _suggestions(
        FakeFirebaseFirestore(),
        uid: 'anon',
        anonymous: true,
      );
      await tester.pumpWidget(wrap(const SaleSuggestionScreen(), [vm]));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sale-suggestion-guest')),
        findsOneWidget,
      );
      expect(find.text('Gửi cho nhóm kiểm tra'), findsNothing);
      vm.dispose();
    });

    testWidgets('empty form: each field says what is missing', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final vm = _suggestions(FakeFirebaseFirestore());
      await tester.pumpWidget(wrap(const SaleSuggestionScreen(), [vm]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gửi cho nhóm kiểm tra'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nhập tên đợt sale'), findsOneWidget);
      expect(find.text('Chọn ngày diễn ra đợt sale.'), findsOneWidget);
      expect(find.textContaining('Ghi nơi sàn công bố'), findsOneWidget);
      expect(find.text('Bạn chưa báo đợt sale nào.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      vm.dispose();
    });

    testWidgets('a report and its answer: status, reason, inbox row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = FakeFirebaseFirestore();
      final vm = _suggestions(db);
      final inbox = _inbox(db);
      await tester.runAsync(() async {
        await vm.submit(
          name: '12.12',
          date: DateTime(2026, 12, 12),
          source: 'x',
        );
        await _settle();
        final s = (vm.mine as UiSuccess<List<core.SaleSuggestion>>).data.single;
        await core.FirestoreSaleSuggestionService(db).reject(
          suggestion: s,
          byUid: _staff,
          reason: 'Chưa có nguồn chính thức',
        );
        await _settle();
      });

      await tester.pumpWidget(wrap(const SaleSuggestionScreen(), [vm, inbox]));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Lý do: Chưa có nguồn chính thức'),
        findsOneWidget,
      );

      await tester.pumpWidget(wrap(const InboxScreen(), [vm, inbox]));
      await tester.pumpAndSettle();
      expect(find.text('Đề xuất sale chưa được duyệt'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Chưa đọc')), findsOneWidget);

      await tester.tap(find.text('Đề xuất sale chưa được duyệt'));
      await tester.pumpAndSettle();
      expect(find.text('Xem các đợt sale bạn đã báo'), findsOneWidget);
      await tester.tap(find.text('Xem các đợt sale bạn đã báo'));
      await tester.pumpAndSettle();
      expect(find.text('Báo đợt sale'), findsOneWidget);
      expect(tester.takeException(), isNull);
      vm.dispose();
      inbox.dispose();
    });
  });
}
