import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/purchase_csv.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/models/budget_group.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/screens/profile_screen.dart';
import 'package:prm393_lab03/screens/reminder_permission_screen.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/data_export_service.dart';
import 'package:prm393_lab03/services/demo_data_service.dart';
import 'package:prm393_lab03/services/feedback_service.dart';
import 'package:prm393_lab03/services/notification_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/viewmodels/settings_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_notification_history_store.dart';

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => true;

  @override
  int getInt(String key) => 0;

  @override
  String getString(String key) => '';
}

/// `sale_reminder_enabled` changes only when fetchAndActivate runs
class _SwitchableRemoteConfig extends _FakeRemoteConfig {
  bool saleReminders = false;
  bool _next = false;

  void publish({required bool saleReminders}) => _next = saleReminders;

  @override
  bool getBool(String key) =>
      key == RemoteConfigService.keySaleReminderEnabled ? saleReminders : true;

  @override
  Future<bool> fetchAndActivate() async {
    saleReminders = _next;
    return true;
  }
}

class _FakeReminders implements ReviewReminderService {
  bool grant = true;
  int permissionRequests = 0;
  (int, int)? daily;

  /// System notifications shown so far
  final immediate = <({String title, String body})>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize({
    VoidCallback? onOpen,
    VoidCallback? onOpenDaily,
    void Function(Map<String, dynamic> data)? onOpenSale,
  }) async {}

  /// Sale reminders handed over by the last sync
  List<({String saleId, String saleType, String body, DateTime at})>
  saleReminders = const [];

  @override
  Future<void> scheduleSaleReminders(
    List<({String saleId, String saleType, String body, DateTime at})>
    reminders,
  ) async => saleReminders = reminders;

  @override
  bool consumeLaunchedFromReminder() => false;

  @override
  bool consumeLaunchedFromDailyReminder() => false;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancel(String itemId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async =>
      daily = (hour, minute);

  @override
  Future<void> cancelDaily() async => daily = null;

  List<DateTime>? reflectionReminders;

  @override
  Future<void> scheduleReflectionReminders(List<DateTime> at) async =>
      reflectionReminders = at;

  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async => immediate.add((title: title, body: body));
}

class _FakeExport implements DataExportService {
  String? name;
  String? content;
  bool fail = false;

  @override
  Future<String?> saveCsv(String fileName, String content) async {
    if (fail) throw StateError('disk full');
    name = fileName;
    this.content = content;
    return '/Download/$fileName.csv';
  }
}

PurchaseItem _purchase(
  String id,
  String title,
  DateTime at, {
  int amount = 45000,
  BuyingMotive motive = BuyingMotive.emotion,
  String group = 'food',
  String? note,
  int? satisfaction,
}) => PurchaseItem(
  id: id,
  title: title,
  amountVnd: amount,
  motive: motive,
  occurredAt: at,
  budgetGroupId: group,
  note: note,
  satisfaction: satisfaction,
);

const _groups = [
  BudgetGroup(id: 'food', name: 'Ăn uống', order: 0),
  BudgetGroup(id: 'tech', name: 'Công nghệ', order: 2),
];

void main() {
  group('PurchaseCsv', () {
    test('BOM, header, oldest first, group names and motive labels', () {
      final csv = PurchaseCsv.build([
        _purchase(
          'b',
          'Tai nghe Bluetooth',
          DateTime(2026, 10, 18, 23, 40),
          amount: 389000,
          motive: BuyingMotive.sale,
          group: 'tech',
          satisfaction: 4,
        ),
        _purchase('a', 'Trà sữa nướng', DateTime(2026, 10, 11, 9, 5)),
      ], _groups);

      expect(csv.startsWith(PurchaseCsv.bom), isTrue);
      final lines = csv.substring(1).split('\r\n');
      expect(lines, hasLength(3));
      expect(lines[0], PurchaseCsv.header.join(','));
      expect(
        lines[1],
        '2026-10-11,09:05,Trà sữa nướng,45000,Cảm xúc,Ăn uống,,Không,,Không',
      );
      expect(
        lines[2],
        '2026-10-18,23:40,Tai nghe Bluetooth,389000,Khuyến mãi,Công nghệ,,Không,4,Không',
      );
    });

    test(
      'quotes commas, quotes and line breaks; unknown group keeps its id',
      () {
        final csv = PurchaseCsv.build([
          _purchase(
            'a',
            'Áo, size M',
            DateTime(2026, 10, 1),
            group: 'gone',
            note: 'Nói "đẹp"\nmua luôn',
          ),
        ], _groups);
        final row = csv.substring(1).split('\r\n').skip(1).join('\r\n');
        expect(row, contains('"Áo, size M"'));
        expect(row, contains('"Nói ""đẹp""\nmua luôn"'));
        expect(row, contains(',gone,'));
      },
    );

    test('text that looks like a formula is neutralised, numbers are kept', () {
      expect(PurchaseCsv.escape('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      expect(PurchaseCsv.escape('+84'), "'+84");
      expect(PurchaseCsv.escape('@me'), "'@me");
      expect(PurchaseCsv.escape('-5'), '-5');
      expect(PurchaseCsv.escape('45000'), '45000');
    });

    test('file name follows Figma: whyibuy-MM-yyyy', () {
      expect(PurchaseCsv.fileName(DateTime(2026, 10, 2)), 'whyibuy-10-2026');
      expect(PurchaseCsv.fileName(DateTime(2027, 1, 31)), 'whyibuy-01-2027');
    });
  });

  group('SettingsViewModel', () {
    late FakeFirebaseFirestore db;
    late _FakeReminders reminders;
    late _FakeExport export;

    SettingsViewModel build({
      RemoteConfigService? remoteConfig,
      NotificationService? notifications,
    }) => SettingsViewModel(
      remoteConfigService:
          remoteConfig ??
          RemoteConfigService(remoteConfig: _FakeRemoteConfig()),
      crashlyticsService: CrashlyticsService(),
      notificationService: notifications ?? NotificationService(),
      userService: FirestoreUserService(db),
      demoDataService: FirestoreDemoDataService(db),
      reminderService: reminders,
      preferencesService: PreferencesService(),
      exportService: export,
      feedbackService: FirestoreFeedbackService(db),
    );

    /// Lets the preferences load in the constructor finish
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = FakeFirebaseFirestore();
      reminders = _FakeReminders();
      export = _FakeExport();
    });

    test('refreshing Remote Config re-filters sale messages at once', () async {
      final fake = _SwitchableRemoteConfig();
      final remoteConfig = RemoteConfigService(remoteConfig: fake);
      final store = InMemoryNotificationHistoryStore();
      await store.add(
        AppNotificationItem(
          id: 's1',
          title: 'Sắp tới đợt sale',
          body: '',
          receivedAt: DateTime(2026, 11, 2, 20),
          data: const {'type': 'sale'},
          source: NotificationSource.background,
        ),
      );
      final notifications = NotificationService(
        historyStore: store,
        saleRemindersEnabled: () => remoteConfig.saleReminderEnabled,
      );
      await notifications.reload();
      final vm = build(
        remoteConfig: remoteConfig,
        notifications: notifications,
      );
      await settle();
      expect(vm.notifications, isEmpty);

      fake.publish(saleReminders: true);
      await vm.refreshRemoteConfig();
      await settle();
      expect(vm.notifications.map((n) => n.id), ['s1']);
    });

    test(
      '05a is offered once, and not when the reminder is already on',
      () async {
        final vm = build();
        await settle();
        expect(vm.dailyReminderEnabled, isFalse);
        expect(vm.dailyReminderTimeText, '21:00');
        expect(await vm.shouldOfferDailyReminder(), isTrue);

        await vm.markDailyReminderOffered();
        expect(await vm.shouldOfferDailyReminder(), isFalse);
      },
    );

    test('"Bật nhắc nhở" asks permission and schedules 21:00 daily', () async {
      final vm = build();
      await settle();
      expect(await vm.enableDailyReminder(), isTrue);
      expect(reminders.permissionRequests, 1);
      expect(reminders.daily, (21, 0));
      expect(vm.dailyReminderEnabled, isTrue);
      expect(await vm.shouldOfferDailyReminder(), isFalse);

      // Saved on the device: a new ViewModel (next launch) re-arms it
      reminders.daily = null;
      final next = build();
      await settle();
      expect(next.dailyReminderEnabled, isTrue);
      expect(reminders.daily, (21, 0));
    });

    test('denied permission leaves the reminder off', () async {
      reminders.grant = false;
      final vm = build();
      await settle();
      expect(await vm.enableDailyReminder(), isFalse);
      expect(reminders.daily, isNull);
      expect(vm.dailyReminderEnabled, isFalse);
    });

    test('changing the time reschedules; turning off cancels', () async {
      final vm = build();
      await settle();
      await vm.setDailyReminderTime(20, 30);
      expect(reminders.daily, isNull, reason: 'off: only the time is saved');
      expect(vm.dailyReminderTimeText, '20:30');

      await vm.enableDailyReminder();
      expect(reminders.daily, (20, 30));
      await vm.setDailyReminderTime(22, 5);
      expect(reminders.daily, (22, 5));

      await vm.disableDailyReminder();
      expect(reminders.daily, isNull);
      expect(vm.dailyReminderEnabled, isFalse);
    });

    test('export: nothing to export, saved file name, failure', () async {
      final vm = build();
      await settle();
      final now = DateTime(2026, 10, 20);
      expect(
        await vm.exportPurchasesCsv(const [], _groups, now: now),
        isA<ExportNothing>(),
      );

      final result = await vm.exportPurchasesCsv(
        [_purchase('a', 'Cơm tấm', DateTime(2026, 10, 19, 12, 15))],
        _groups,
        now: now,
      );
      expect(
        result,
        isA<ExportSaved>().having(
          (r) => r.fileName,
          'fileName',
          'whyibuy-10-2026.csv',
        ),
      );
      expect(export.name, 'whyibuy-10-2026');
      expect(export.content, contains('Cơm tấm,45000,Cảm xúc,Ăn uống'));

      export.fail = true;
      expect(
        await vm.exportPurchasesCsv(
          [_purchase('a', 'Cơm tấm', DateTime(2026, 10, 19))],
          _groups,
          now: now,
        ),
        isA<ExportFailed>(),
      );
      expect(vm.isExporting, isFalse);
    });

    test('feedback is stored under the signed-in user', () async {
      final vm = build()..updateUid('u1');
      await settle();
      expect(await vm.sendFeedback('   '), 'Bạn chưa viết góp ý.');
      expect(await vm.sendFeedback('  App rất hay  '), isNull);

      final docs = await db.collection('users/u1/feedback').get();
      expect(docs.docs, hasLength(1));
      expect(docs.docs.single.data()['message'], 'App rất hay');
      expect(docs.docs.single.data()['appVersion'], isA<String>());
    });

    test('feedback needs a signed-in user', () async {
      final vm = build();
      await settle();
      expect(await vm.sendFeedback('Hi'), 'Bạn cần đăng nhập để gửi góp ý.');
    });

    test('test notifications name their source, no UID', () async {
      final vm = build();
      await settle();
      await vm.sendTestNotification();
      await vm.testHandledNonFatalError('uid-123');

      expect(reminders.immediate.map((n) => n.title), [
        'Thử thông báo trên máy',
        'Đã ghi lỗi có xử lý (Crashlytics)',
      ]);
      expect(
        reminders.immediate.first.body,
        'Đây là thông báo cục bộ do app tạo, không đi qua Firebase Cloud Messaging.',
      );
      expect(
        reminders.immediate.last.body,
        'Lỗi thử đã được gửi lên Firebase Crashlytics & Admin Web.',
      );
      for (final n in reminders.immediate) {
        expect('${n.title}${n.body}', isNot(contains('uid-123')));
        // No emoji: Vietnamese letters stay below U+2000
        expect('${n.title}${n.body}'.runes.every((r) => r < 0x2000), isTrue);
      }
    });

    Widget demoTools(SettingsViewModel vm, {required bool visible}) =>
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FirebaseDemoTools(userId: 'uid-123', visible: visible),
              ),
            ),
          ),
        );

    const demoButtons = [
      'Bắn lỗi có xử lý (Non-Fatal)',
      'Kích hoạt thử nghiệm Crash thật',
      'Thử thông báo trên máy',
    ];

    testWidgets('release build shows none of the test buttons', (tester) async {
      final vm = build();
      await tester.runAsync(settle);
      await tester.pumpWidget(demoTools(vm, visible: false));

      expect(find.text('Khu trình diễn (chỉ bản thử nghiệm)'), findsNothing);
      for (final title in demoButtons) {
        expect(find.text(title), findsNothing);
      }
    });

    testWidgets('debug build groups the buttons; crash asks first', (
      tester,
    ) async {
      final vm = build();
      await tester.runAsync(settle);
      await tester.pumpWidget(demoTools(vm, visible: true));

      expect(find.text('Khu trình diễn (chỉ bản thử nghiệm)'), findsOneWidget);
      for (final title in demoButtons) {
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.text('Thông báo FCM thật gửi từ Firebase Console.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Kích hoạt thử nghiệm Crash thật'));
      await tester.pumpAndSettle();
      expect(find.text('Crash thử ứng dụng?'), findsOneWidget);

      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(find.text('Crash thử ứng dụng?'), findsNothing);
      // Cancelled: no "Sắp crash thử" notification, no crash
      expect(reminders.immediate, isEmpty);
    });

    testWidgets('05a: "Bật nhắc nhở" turns the reminder on and closes', (
      tester,
    ) async {
      final vm = build();
      await tester.runAsync(settle);
      bool? popped;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    popped = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReminderPermissionScreen(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Để Why I Buy? nhắc bạn mỗi tối?'), findsOneWidget);
      expect(find.textContaining('lúc 21:00'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('enable-daily-reminder')));
        await settle();
      });
      await tester.pumpAndSettle();
      expect(popped, isTrue);
      expect(reminders.daily, (21, 0));
      expect(await tester.runAsync(vm.shouldOfferDailyReminder), isFalse);
    });
  });
}
