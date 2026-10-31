import 'dart:async';
import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/formatters/money_format.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/spending_insight.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/services/ai_insight_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/pending_writes.dart';
import 'package:prm393_lab03/services/reflection_service.dart';
import 'package:prm393_lab03/services/report_service.dart';
import 'package:prm393_lab03/services/service_guard.dart';
import 'package:prm393_lab03/viewmodels/reflection_viewmodel.dart';
import 'package:prm393_lab03/widgets/states/error_view.dart';
import 'package:prm393_lab03/widgets/states/loading_view.dart';
import 'package:prm393_lab03/widgets/states/state_view.dart';
import 'package:prm393_lab03/widgets/undo_snack_bar.dart';

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 10: loading, empty and error states', () {
    test(
      'loading and errors get their own view; data and empty fall through',
      () {
        var retried = false;
        expect(stateView([const UiLoading<int>()]), isA<LoadingView>());
        expect(stateView([const UiInitial<int>()]), isA<LoadingView>());
        final error = stateView([
          const UiSuccess<int>(1),
          UiError<int>(message: 'Mất mạng', onRetry: () => retried = true),
        ]);
        expect(error, isA<ErrorView>());
        (error! as ErrorView).onRetry!();
        expect(retried, isTrue);
        // Error wins over loading so there is always a "Thử lại"
        expect(
          stateView([const UiLoading<int>(), const UiError<int>(message: 'x')]),
          isA<ErrorView>(),
        );
        expect(stateView([const UiSuccess<int>(1)]), isNull);
        expect(stateView([const UiEmpty<int>(message: 'Chưa có')]), isNull);
      },
    );
  });

  group('Item 10: offline writes (E04)', () {
    test(
      'a write the server does not confirm counts as saved on this device',
      () async {
        final server = Completer<void>();
        await awaitWrite(
          server.future,
          timeout: const Duration(milliseconds: 20),
        );
        expect(PendingWrites.instance.count, 1);

        server.complete(); // connection is back, Firestore syncs
        await _settle();
        expect(PendingWrites.instance.count, 0);
      },
    );

    test('an error that arrives in time still reaches the screen', () async {
      expect(
        () => awaitWrite(Future<void>.error(StateError('permission-denied'))),
        throwsStateError,
      );
      expect(PendingWrites.instance.count, 0);
    });

    test('a confirmed write is not tracked as pending', () async {
      await awaitWrite(Future<void>.value());
      expect(PendingWrites.instance.count, 0);
    });

    test(
      'another account does not see the previous account\'s queue',
      () async {
        final oldAccount = Completer<void>();
        await awaitWrite(
          oldAccount.future,
          timeout: const Duration(milliseconds: 20),
        );
        expect(PendingWrites.instance.count, 1);

        PendingWrites.instance.reset(); // sign-out / account switch
        expect(PendingWrites.instance.count, 0);

        final newAccount = Completer<void>();
        await awaitWrite(
          newAccount.future,
          timeout: const Duration(milliseconds: 20),
        );
        oldAccount.complete(); // old account signs in again later and syncs
        await _settle();
        expect(
          PendingWrites.instance.count,
          1,
          reason: 'only the new account write',
        );

        newAccount.complete();
        await _settle();
        expect(PendingWrites.instance.count, 0);
      },
    );
  });

  group('Item 10: tabs and transient messages', () {
    testWidgets('Hoàn tác snack bar disappears by itself after 5 seconds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showUndoSnackBar(context, 'Đã chuyển sang Chờ', () {}),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsNothing);
    });
  });

  group('Item 11: skipped items without a price are never 0 ₫', () {
    WishlistItem skipped(String id, int? price) => WishlistItem(
      id: id,
      title: id,
      status: WishlistStatus.skipped,
      latestPriceVnd: price,
      createdAt: DateTime(2026, 9, 1),
      decidedAt: DateTime(2026, 10, 3),
    );

    MonthlySpendingStats statsFor(List<WishlistItem> items) =>
        MonthlySpendingStats.compute(
          month: DateTime(2026, 10),
          purchases: const [],
          wishlistItems: items,
        );

    test('no price recorded: "chưa ghi giá" and no total for the AI', () {
      final stats = statsFor([skipped('a', null)]);
      expect(stats.skippedValueText, 'chưa ghi giá');
      final data = stats.toPromptData()['monDaQuyetDinhKhongMua'] as Map;
      expect(data.containsKey('tongGiaDaGhiText'), isFalse);
      expect(data['soMonChuaGhiGia'], 1);
    });

    test('some prices recorded: total plus how many have no price', () {
      final stats = statsFor([skipped('a', 600000), skipped('b', null)]);
      expect(
        stats.skippedValueText,
        'tổng giá đã ghi ${formatVnd(600000)} (1 món chưa ghi giá)',
      );
      final text = _templateText(stats);
      expect(text, contains(stats.skippedValueText));
      // "600.000 ₫" ends in "0 ₫", so look for a standalone zero amount
      expect(RegExp(r'(^|\s)0 ₫').hasMatch(text), isFalse);
    });
  });

  group('Item 11: Chiêm nghiệm is saved for the month on screen', () {
    test('rating and goal go to users/{uid}/reflections/{yyyy-MM}', () async {
      final db = FakeFirebaseFirestore();
      final vm =
          ReflectionViewModel(reflectionService: FirestoreReflectionService(db))
            ..updateUid('user-a')
            ..updateMonth(DateTime(2025, 3, 18));
      await _settle();

      vm.selectRating(4);
      expect(await vm.save('Ít mua sau 22 giờ'), isTrue);
      final march = await db.doc('users/user-a/reflections/2025-03').get();
      expect(march.data()!['rating'], 4);
      expect(march.data()!['goal'], 'Ít mua sau 22 giờ');

      // Another month starts empty and saves to its own document
      vm.updateMonth(DateTime(2025, 4, 1));
      await _settle();
      expect(vm.rating, isNull);
      vm.selectRating(2);
      await vm.save('');
      expect(
        (await db.doc('users/user-a/reflections/2025-04').get())
            .data()!['rating'],
        2,
      );
      expect(
        (await db.doc('users/user-a/reflections/2025-03').get())
            .data()!['rating'],
        4,
      );
      vm.dispose();
    });
  });

  group('Item 11: PDF report', () {
    final month = DateTime(2026, 10);
    final purchases = [
      for (var i = 1; i <= 120; i++)
        PurchaseItem(
          id: 'p$i',
          title: 'Trà sữa nướng đường đen số $i',
          amountVnd: 45000 + i,
          motive: BuyingMotive.values[i % BuyingMotive.values.length],
          occurredAt: DateTime(2026, 10, 1 + i % 28, 20, 15),
        ),
    ];
    final decided = [
      WishlistItem(
        id: 'w1',
        title: 'Đồng hồ',
        status: WishlistStatus.skipped,
        latestPriceVnd: 600000,
        createdAt: DateTime(2026, 9, 1),
        decidedAt: DateTime(2026, 10, 3),
      ),
    ];

    Future<(List<int>, List<String>)> render() async {
      final logs = <String>[];
      late List<int> bytes;
      await runZoned(
        () async {
          bytes = await ReportService().generateMonthlyReportPdf(
            userName: 'Nguyễn Hải Nam',
            month: month,
            purchases: purchases,
            decidedItems: decided,
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );
      return (bytes, logs);
    }

    test(
      'Vietnamese text and ₫ use the embedded font (no missing glyphs)',
      () async {
        final (bytes, logs) = await render();
        expect(bytes.length, greaterThan(1000));
        expect(
          logs.where((l) => l.contains('Unable to find a font')),
          isEmpty,
          reason: logs.join('\n'),
        );
        expect(
          latin1.decode(bytes, allowInvalid: true),
          contains('BeVietnamPro'),
        );
      },
    );

    test('a long purchase list continues on more pages', () async {
      final (bytes, _) = await render();
      final pdf = latin1.decode(bytes, allowInvalid: true);
      final pages = RegExp(r'/Type\s*/Page\b').allMatches(pdf).length;
      expect(pages, greaterThan(1));
    });
  });
}

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
  }) => throw UnimplementedError('Not used by Góc nhìn');
}

/// Every sentence the template (AI off/failed) shows
String _templateText(MonthlySpendingStats stats) {
  final report = AiInsightService(generator: _NoAi())
      .buildTemplateReport(stats);
  return [report.summary, for (final c in report.cards) c.body].join('\n');
}
