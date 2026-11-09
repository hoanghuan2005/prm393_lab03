import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/available_budget.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/owned_item.dart';
import 'package:prm393_lab03/models/pre_purchase_check.dart';
import 'package:prm393_lab03/models/pre_purchase_facts.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/pre_purchase_result_screen.dart';
import 'package:prm393_lab03/screens/pre_purchase_screen.dart';
import 'package:prm393_lab03/services/ai_pre_purchase_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/viewmodels/pre_purchase_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  bool ai = true;

  @override
  bool getBool(String key) => ai;

  @override
  int getInt(String key) => 0;

  @override
  String getString(String key) => '';
}

class _FakeAi implements AiService {
  String reply = '{}';
  Object? error;
  int calls = 0;

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) async {
    calls++;
    if (error != null) throw error!;
    return reply;
  }

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
}

/// Figma example: Tai nghe Bluetooth · 389.000 ₫ · Mong muốn + Khuyến mãi + Chưa chắc
PrePurchaseAnswers _headphones({
  WhyAnswer why = WhyAnswer.want,
  InfluenceAnswer influence = InfluenceAnswer.sale,
  WithoutSaleAnswer? withoutSale = WithoutSaleAnswer.unsure,
  UsageAnswer usage = UsageAnswer.daily,
  SimilarOwnedAnswer similar = SimilarOwnedAnswer.none,
  MoodAnswer? mood,
  int? price = 389000,
}) => PrePurchaseAnswers(
  title: ' Tai nghe Bluetooth ',
  priceVnd: price,
  why: why,
  influence: influence,
  withoutSale: withoutSale,
  usage: usage,
  similar: similar,
  mood: mood,
);

PurchaseItem _bought(
  String title,
  DateTime at, {
  BuyingMotive motive = BuyingMotive.sale,
  int? satisfaction,
  int amount = 100000,
}) => PurchaseItem(
  id: title,
  title: title,
  amountVnd: amount,
  motive: motive,
  occurredAt: at,
  satisfaction: satisfaction,
);

void main() {
  group('PrePurchaseRules', () {
    test('Figma screen 18 example: two cards, summary and question', () {
      final insight = PrePurchaseRules.templateInsight(_headphones());
      expect(insight.observations.map((o) => o.chip), [
        'Mong muốn',
        'Khuyến mãi',
        'Dùng: Hằng ngày',
        'Đồ tương tự: Chưa có',
      ]);
      expect(
        insight.observations.first.text,
        'Bạn chọn Mong muốn: món này hấp dẫn bạn, hơn là một nhu cầu bạn đã '
        'xác định.',
      );
      expect(insight.observations[1].text, contains('chưa chắc'));
      expect(
        insight.summary,
        'Câu trả lời cho thấy cả món đồ lẫn ưu đãi đều quan trọng với bạn.',
      );
      expect(
        insight.question,
        'Không có khuyến mãi, điều gì khiến món này đáng mua với bạn?',
      );
      expect(insight.usesAi, isFalse);
    });

    test('the sale answer only after "Khuyến mãi", mood only after "Cảm xúc"', () {
      final a = _headphones(
        influence: InfluenceAnswer.social,
        mood: MoodAnswer.stressed,
      );
      expect(a.withoutSale, isNull);
      expect(a.mood, isNull);
      expect(PrePurchaseAnswers.asksAboutSale(InfluenceAnswer.sale), isTrue);
      expect(PrePurchaseAnswers.asksAboutSale(InfluenceAnswer.none), isFalse);
      expect(a.title, 'Tai nghe Bluetooth');

      final emotional = _headphones(
        why: WhyAnswer.emotion,
        mood: MoodAnswer.stressed,
      );
      expect(emotional.mood, MoodAnswer.stressed);
      expect(
        PrePurchaseRules.observationsFor(emotional).map((o) => o.chip),
        contains('Tâm trạng: Căng thẳng'),
      );
    });

    test('the most telling answer picks the open question', () {
      expect(
        PrePurchaseRules.templateQuestion(
          _headphones(similar: SimilarOwnedAnswer.working),
        ),
        'Món mới sẽ làm được điều gì mà món bạn đang có chưa làm được?',
      );
      expect(
        PrePurchaseRules.templateQuestion(
          _headphones(why: WhyAnswer.emotion, mood: MoodAnswer.down),
        ),
        'Nếu tâm trạng khác đi, bạn có còn muốn món này không?',
      );
      expect(
        PrePurchaseRules.templateQuestion(_headphones(usage: UsageAnswer.unsure)),
        'Bạn hình dung mình sẽ dùng món này vào lúc nào?',
      );
      expect(
        PrePurchaseRules.templateSummary(
          _headphones(similar: SimilarOwnedAnswer.working),
        ),
        endsWith('Bạn cũng đang có một món tương tự vẫn dùng tốt.'),
      );
    });

    test('motive pre-filled for "Vẫn mua"', () {
      expect(_headphones().suggestedMotive, BuyingMotive.want);
      expect(
        _headphones(withoutSale: WithoutSaleAnswer.no).suggestedMotive,
        BuyingMotive.sale,
      );
      expect(
        _headphones(
          why: WhyAnswer.other,
          influence: InfluenceAnswer.ads,
        ).suggestedMotive,
        BuyingMotive.ads,
      );
      expect(
        _headphones(
          why: WhyAnswer.other,
          influence: InfluenceAnswer.none,
        ).suggestedMotive,
        BuyingMotive.other,
      );
    });

    test('every template is neutral (no banned wording)', () {
      for (final why in WhyAnswer.values) {
        for (final influence in InfluenceAnswer.values) {
          for (final w in [null, ...WithoutSaleAnswer.values]) {
            final insight = PrePurchaseRules.templateInsight(
              _headphones(
                why: why,
                influence: influence,
                withoutSale: w,
                usage: UsageAnswer.values[w?.index ?? 3],
                similar: SimilarOwnedAnswer.values[why.index % 3],
                mood: MoodAnswer.values[influence.index],
              ),
            );
            final all = [
              insight.summary,
              insight.question,
              ...insight.observations.map((o) => o.text),
            ].join(' ').toLowerCase();
            for (final banned in ['nên mua', 'không nên', 'lãng phí']) {
              expect(all, isNot(contains(banned)));
            }
            expect(insight.question.endsWith('?'), isTrue);
          }
        }
      }
    });
  });

  group('PrePurchaseFacts', () {
    final now = DateTime(2026, 11, 2, 12);

    test('reads owned items, similar purchases, wishlist, budget and history', () {
      final facts = PrePurchaseFacts.build(
        answers: _headphones(),
        now: now,
        purchases: [
          _bought('Tai nghe Bluetooth Sony', DateTime(2026, 10, 20), amount: 450000),
          _bought('Áo khoác', DateTime(2026, 10, 25), satisfaction: 2),
          _bought('Giày', DateTime(2026, 10, 28), satisfaction: 5),
        ],
        wishlist: [
          WishlistItem(
            id: 'w1',
            title: 'Tai nghe Bluetooth JBL',
            createdAt: DateTime(2026, 10, 30),
          ),
        ],
        owned: [
          OwnedItem(
            id: 'o1',
            name: 'AirPods',
            tags: const ['tai nghe'],
            note: 'dùng 2 năm',
            createdAt: DateTime(2025),
          ),
        ],
      );
      // Only the three most telling facts
      expect(facts.map((f) => f.text), [
        'Hồ sơ mua sắm ghi bạn đang có "AirPods" (dùng 2 năm).',
        '13 ngày trước bạn đã mua "Tai nghe Bluetooth Sony" (450.000 ₫).',
        'Bạn đang cân nhắc "Tai nghe Bluetooth JBL" trong danh sách mong muốn.',
      ]);
    });

    test('budget share, satisfaction average and motive count', () {
      final facts = PrePurchaseFacts.build(
        answers: _headphones(),
        now: now,
        purchases: [
          _bought('Áo khoác', DateTime(2026, 10, 25), satisfaction: 2),
          _bought('Giày', DateTime(2026, 10, 28), satisfaction: 5),
        ],
        groupName: 'Công nghệ',
        available: const AvailableBudget(
          limit: 1000000,
          spent: 40000,
          windowDays: 0,
          dailyAverage: 0,
          daysLeft: 28,
          hasEnoughHistory: false,
        ),
      );
      expect(facts.map((f) => f.text), [
        'Món này bằng khoảng 45% phần khả dụng của nhóm Công nghệ tháng này '
            '(864.000 ₫).',
        'Các món bạn mua vì Khuyến mãi được bạn chấm trung bình 3,5/5 (2 món).',
        '30 ngày qua bạn đã ghi 2 khoản mua vì Khuyến mãi.',
      ]);
    });

    test('no data, no facts', () {
      expect(
        PrePurchaseFacts.build(answers: _headphones(price: null), now: now),
        isEmpty,
      );
      expect(PrePurchaseFacts.formatAverage(4), '4');
      expect(PrePurchaseFacts.formatAverage(3.66), '3,7');
    });

    test('AI may repeat the numbers of the facts, not invent others', () {
      const facts = [
        PrePurchaseFact(
          icon: Icons.history,
          text: '13 ngày trước bạn đã mua "Tai nghe Sony" (450.000 ₫).',
        ),
      ];
      final text = AiPrePurchaseService.parse(
        jsonEncode({
          'summary': 'Bạn đã mua một tai nghe 450.000 ₫ cách đây 13 ngày.',
          'question': 'Còn 20 ngày nữa thì sao?',
        }),
        _headphones(),
        facts: facts,
      );
      expect(text.summary, isNotNull);
      expect(text.question, isNull);
    });
  });

  group('AiPrePurchaseService.parse', () {
    final answers = _headphones();

    test('keeps acceptable sentences', () {
      final text = AiPrePurchaseService.parse(
        jsonEncode({
          'summary': 'Món tai nghe và ưu đãi 389.000 ₫ đều có sức hút với bạn.',
          'question': 'Bạn sẽ dùng tai nghe này vào lúc nào?',
        }),
        answers,
      );
      expect(text.summary, startsWith('Món tai nghe'));
      expect(text.question, 'Bạn sẽ dùng tai nghe này vào lúc nào?');
    });

    test('drops invented numbers, banned wording and a question without "?"', () {
      final text = AiPrePurchaseService.parse(
        jsonEncode({
          'summary': 'Bạn nên mua khi giảm 50%.',
          'question': 'Hãy nghĩ thêm.',
        }),
        answers,
      );
      expect(text.summary, isNull);
      expect(text.question, isNull);

      final invented = AiPrePurchaseService.parse(
        jsonEncode({'summary': 'Giá 299.000 ₫ hợp lý.', 'question': 'Vì sao?'}),
        answers,
      );
      expect(invented.summary, isNull);
      expect(invented.question, 'Vì sao?');
    });

    test('invalid JSON gives nothing', () {
      final text = AiPrePurchaseService.parse('not json', answers);
      expect(text.summary, isNull);
      expect(text.question, isNull);
    });
  });

  group('PrePurchaseViewModel', () {
    late _FakeAi ai;
    late _FakeRemoteConfig config;
    var platformAi = true;

    PrePurchaseViewModel build() => PrePurchaseViewModel(
      aiService: AiPrePurchaseService(generator: ai),
      remoteConfigService: RemoteConfigService(remoteConfig: config),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => platformAi,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ai = _FakeAi();
      config = _FakeRemoteConfig();
      platformAi = true;
    });

    testWidgets(
      'cached and fallback results do not force an extra loading delay',
      (tester) async {
        final vm = build();
        var completed = false;
        final running = vm.analyze(_headphones()).then((_) => completed = true);
        await tester.pump();
        expect(completed, isTrue);
        await running;
        vm.dispose();
      },
    );

    test(
      'reset before the preference check avoids an obsolete AI request',
      () async {
        final vm = build();
        final running = vm.analyze(_headphones());
        vm.reset();
        await running;
        expect(ai.calls, 0);
        expect(vm.state, isA<UiInitial<PrePurchaseInsight>>());
        vm.dispose();
      },
    );

    test('no AI on this platform (no token): template result, AI not called', () async {
      platformAi = false;
      final vm = build();
      await vm.analyze(_headphones());
      final insight = (vm.state as UiSuccess<PrePurchaseInsight>).data;
      expect(insight.usesAi, isFalse);
      expect(ai.calls, 0);
    });

    test('AI sentences replace the template when accepted', () async {
      ai.reply = jsonEncode({
        'summary': 'Cả món đồ lẫn ưu đãi đều kéo bạn về phía tai nghe này.',
        'question': 'Nếu hết sale, bạn còn muốn nó không?',
      });
      final vm = build();
      await vm.analyze(_headphones());
      final insight = (vm.state as UiSuccess<PrePurchaseInsight>).data;
      expect(insight.summaryFromAi, isTrue);
      expect(insight.questionFromAi, isTrue);
      expect(insight.question, 'Nếu hết sale, bạn còn muốn nó không?');
      expect(insight.observations, hasLength(4));
    });

    test('AI failure still ends in a result', () async {
      ai.error = StateError('App Check token missing');
      final vm = build();
      await vm.analyze(_headphones());
      final insight = (vm.state as UiSuccess<PrePurchaseInsight>).data;
      expect(insight.usesAi, isFalse);
      expect(insight.summary, isNotEmpty);
    });

    test('user turned AI off: template', () async {
      SharedPreferences.setMockInitialValues({'ai_insight_enabled': false});
      final vm = build();
      await vm.analyze(_headphones());
      expect(ai.calls, 0);
    });
  });

  testWidgets('Flow 9: 3 questions → result → "Vẫn mua" pre-fills Ghi khoản mua', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final vm = PrePurchaseViewModel(
      aiService: AiPrePurchaseService(generator: _FakeAi()),
      remoteConfigService: RemoteConfigService(
        remoteConfig: _FakeRemoteConfig(),
      ),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => false,
      minLoading: Duration.zero,
    );
    RecordPurchaseArgs? recordArgs;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.prePurchase),
                child: const Text('home'),
              ),
            ),
          ),
          onGenerateRoute: (settings) => MaterialPageRoute<dynamic>(
            settings: settings,
            builder: (_) => switch (settings.name) {
              AppRoutes.prePurchase => const PrePurchaseScreen(),
              AppRoutes.prePurchaseResult => PrePurchaseResultScreen(
                answers: (settings.arguments! as PrePurchaseArgs).answers,
              ),
              _ => Builder(
                builder: (_) {
                  recordArgs = settings.arguments as RecordPurchaseArgs?;
                  return const Scaffold(body: Text('record purchase'));
                },
              ),
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();

    // Step 1: name is required
    expect(find.text('BƯỚC 1/4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pre-purchase-next')));
    await tester.pumpAndSettle();
    expect(find.text('BƯỚC 1/4'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('pre-purchase-title')),
        matching: find.byType(EditableText),
      ),
      'Tai nghe Bluetooth',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('pre-purchase-price')),
        matching: find.byType(EditableText),
      ),
      '389000',
    );
    await tester.tap(find.byKey(const ValueKey('pre-purchase-next')));
    await tester.pumpAndSettle();

    // Step 2: both answers needed; until it is answered the possible sale step is counted
    expect(find.text('BƯỚC 2/4'), findsOneWidget);
    expect(find.text('Tai nghe Bluetooth · 389.000 ₫'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('why-want')));
    await tester.tap(find.byKey(const ValueKey('influence-sale')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pre-purchase-next')));
    await tester.pumpAndSettle();

    // Step 3: "Khuyến mãi" keeps the sale step, so the total stays 4
    expect(find.text('BƯỚC 3/4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('without-sale-unsure')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pre-purchase-next')));
    await tester.pumpAndSettle();

    // Step 4: usage and similar items (no mood question: not "Cảm xúc")
    expect(find.text('BƯỚC 4/4'), findsOneWidget);
    expect(find.text('Lúc này bạn đang cảm thấy thế nào?'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('usage-daily')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('similar-none')));
    await tester.tap(find.byKey(const ValueKey('similar-none')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pre-purchase-next')));
    await tester.pumpAndSettle();

    // Screen 18
    expect(find.text('Nhận định trước khi mua'), findsOneWidget);
    expect(find.text('Mong muốn'), findsOneWidget);
    // Below the fold of the 800×600 test screen
    await tester.scrollUntilVisible(
      find.text('Câu mẫu'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pre-purchase-question')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Không có khuyến mãi, điều gì khiến món này đáng mua với bạn?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('pre-purchase-buy-anyway')));
    await tester.pumpAndSettle();
    expect(find.text('record purchase'), findsOneWidget);
    expect(recordArgs?.initialTitle, 'Tai nghe Bluetooth');
    expect(recordArgs?.initialAmount, 389000);
    expect(recordArgs?.initialMotive, BuyingMotive.want);
  });

  testWidgets('"Để mình nghĩ thêm" goes home without anything else', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final vm = PrePurchaseViewModel(
      aiService: AiPrePurchaseService(generator: _FakeAi()),
      remoteConfigService: RemoteConfigService(
        remoteConfig: _FakeRemoteConfig(),
      ),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => false,
      minLoading: Duration.zero,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PrePurchaseResultScreen(
                      answers: _headphones(
                        influence: InfluenceAnswer.none,
                        withoutSale: null,
                      ),
                    ),
                  ),
                ),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    // The observation cards come after the summary and the question
    await tester.scrollUntilVisible(find.text('Không có tác động'), 200);
    expect(find.text('Không có tác động'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pre-purchase-think-more')));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(vm.state, isA<UiInitial<PrePurchaseInsight>>());
  });
}
