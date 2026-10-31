import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/budget_group.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/item_suggestion.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/add_item_screen.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/ai_suggestion_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/viewmodels/item_suggestion_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/purchase_harness.dart';

class _FakeAi implements AiService {
  String response = '{}';
  Object? error;
  final prompts = <String>[];

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
  }) async {
    prompts.add(prompt);
    if (error != null) throw error!;
    return response;
  }
}

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  bool suggestionsEnabled = true;

  @override
  bool getBool(String key) => key == RemoteConfigService.keyEnableAiSuggestions
      ? suggestionsEnabled
      : true;
}

final _now = DateTime(2026, 10, 31, 12);

PurchaseItem _purchase(
  String id,
  String title,
  String group, {
  int daysAgo = 5,
  int amount = 450000,
}) => PurchaseItem(
  id: id,
  title: title,
  amountVnd: amount,
  motive: BuyingMotive.want,
  occurredAt: _now.subtract(Duration(days: daysAgo)),
  budgetGroupId: group,
);

WishlistItem _wish(
  String id,
  String title, {
  String? group,
  int? price,
  WishlistStatus status = WishlistStatus.considering,
}) => WishlistItem(
  id: id,
  title: title,
  budgetGroupId: group,
  latestPriceVnd: price,
  status: status,
  createdAt: _now.subtract(const Duration(days: 2)),
);

void main() {
  late _FakeAi ai;
  late _FakeRemoteConfig remoteConfig;
  late ItemSuggestionViewModel vm;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ai = _FakeAi();
    remoteConfig = _FakeRemoteConfig();
    vm = ItemSuggestionViewModel(
      aiSuggestionService: AiSuggestionService(generator: ai),
      remoteConfigService: RemoteConfigService(remoteConfig: remoteConfig),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => true,
      now: () => _now,
    );
  });

  group('Code first: titles and keywords', () {
    test('titles are compared without diacritics or punctuation', () {
      expect(
        normalizeTitle('Tai nghe Sony WH-1000XM5!'),
        'tai nghe sony wh 1000xm5',
      );
      expect(normalizeTitle('Đồng hồ  ĐẸP'), 'dong ho dep');
    });

    test('the longest keyword decides the group', () {
      expect(guessBudgetGroup('Trà sữa trân châu'), 'food');
      expect(guessBudgetGroup('Kem chống nắng Anessa'), 'beauty');
      expect(guessBudgetGroup('Tai nghe Sony'), 'tech');
      expect(guessBudgetGroup('Đồng hồ thông minh Xiaomi'), 'tech');
      expect(guessBudgetGroup('Máy tính Casio fx-580'), 'study');
      expect(guessBudgetGroup('Phần mềm diệt virus'), 'tech');
      // Whole words only: "Sony" is not "son" (lipstick)
      expect(guessBudgetGroup('Sony'), isNull);
    });

    test('shared words decide how alike two titles are', () {
      Set<String> t(String s) => titleTokens(s);
      expect(
        compareTitles(t('Tai nghe Sony'), t('Tai nghe JBL Tune')),
        TitleSimilarity.likely,
      );
      expect(
        compareTitles(t('Áo thun trắng'), t('Áo khoác')),
        TitleSimilarity.possible,
      );
      expect(
        compareTitles(t('Tai nghe'), t('Headphone')),
        TitleSimilarity.none,
      );
      expect(
        compareTitles(t('Tai nghe'), t('Headphone'), sameGroup: true),
        TitleSimilarity.possible,
      );
      // A shared number alone is not a match
      expect(
        compareTitles(t('iPhone 15'), t('Áo size 15')),
        TitleSimilarity.none,
      );
    });
  });

  group('AI feature 3: budget group suggestion', () {
    test('a keyword answers without calling AI', () async {
      final s = await vm.suggestGroup('Tai nghe Sony', defaultBudgetGroups);
      expect(s?.groupId, 'tech');
      expect(s?.fromAi, isFalse);
      expect(ai.prompts, isEmpty);
    });

    test('AI is asked when no keyword matches, and labelled as AI', () async {
      ai.response = jsonEncode({'groupId': 'fashion'});
      final s = await vm.suggestGroup('Gối ôm Totoro', defaultBudgetGroups);
      expect(s?.groupId, 'fashion');
      expect(s?.fromAi, isTrue);
      expect(ai.prompts.single, contains('"Gối ôm Totoro"'));
    });

    test(
      'an invented group, "none", "Khác" or an error gives no suggestion',
      () async {
        for (final response in [
          jsonEncode({'groupId': 'toys'}),
          jsonEncode({'groupId': AiSuggestionService.noneValue}),
          jsonEncode({'groupId': BudgetGroup.otherId}),
          'not json',
        ]) {
          ai.response = response;
          expect(
            await vm.suggestGroup('Gối ôm $response', defaultBudgetGroups),
            isNull,
          );
        }
        ai.error = Exception('offline');
        expect(
          await vm.suggestGroup('Gối ôm Pikachu', defaultBudgetGroups),
          isNull,
        );
      },
    );

    test(
      'AI turned off by the user or Remote Config: keywords still work',
      () async {
        await PreferencesService().setAiInsightEnabled(false);
        expect(
          await vm.suggestGroup('Gối ôm Totoro', defaultBudgetGroups),
          isNull,
        );
        expect(
          (await vm.suggestGroup('Son kem lì', defaultBudgetGroups))?.groupId,
          'beauty',
        );

        await PreferencesService().setAiInsightEnabled(true);
        remoteConfig.suggestionsEnabled = false;
        expect(
          await vm.suggestGroup('Gối ôm Totoro', defaultBudgetGroups),
          isNull,
        );
        expect(ai.prompts, isEmpty);
      },
    );

    test('the same title is not sent twice', () async {
      ai.response = jsonEncode({'groupId': 'fashion'});
      await vm.suggestGroup('Gối ôm Totoro', defaultBudgetGroups);
      await vm.suggestGroup('gối ôm totoro!', defaultBudgetGroups);
      expect(ai.prompts, hasLength(1));
    });
  });

  group('AI feature 4: possible duplicates', () {
    setUp(() {
      vm.updateSources(
        purchases: [
          _purchase('p1', 'Tai nghe JBL Tune', 'tech'),
          _purchase('p2', 'Headphone Sony cũ', 'tech', daysAgo: 45),
          _purchase('p3', 'Trà sữa', 'food', daysAgo: 1),
        ],
        wishlistItems: [
          _wish('w1', 'Earbuds Xiaomi', group: 'tech'),
          _wish(
            'w2',
            'Tai nghe gaming',
            group: 'tech',
            status: WishlistStatus.skipped,
          ),
          _wish('self', 'Tai nghe Sony', group: 'tech', price: 900000),
        ],
      );
    });

    test(
      'only the last 30 days of purchases and items still being considered',
      () {
        final ids = vm.candidates(excludeItemId: 'self').map((c) => c.id);
        expect(ids, unorderedEquals(['purchase:p1', 'wishlist:w1']));
      },
    );

    test(
      'a clear match comes from code; AI picks among same-group items',
      () async {
        ai.response = jsonEncode({
          'ids': ['c1', 'c9'],
        });
        final matches = await vm.findDuplicates(
          'Tai nghe Sony',
          excludeItemId: 'self',
          budgetGroupId: 'tech',
        );
        expect(matches.map((m) => (m.candidate.id, m.fromAi)), [
          ('purchase:p1', false),
          ('wishlist:w1', true),
        ]);
        // Only the ambiguous item went to AI, under a short id instead of the document id
        expect(ai.prompts.single, contains('c1: "Earbuds Xiaomi"'));
        expect(ai.prompts.single, isNot(contains('w1')));
      },
    );

    test('without AI the clear match is still shown', () async {
      ai.error = Exception('offline');
      final matches = await vm.findDuplicates(
        'Tai nghe Sony',
        excludeItemId: 'self',
      );
      expect(matches.map((m) => m.candidate.id), ['purchase:p1']);
    });

    test('food and drinks are never duplicates', () async {
      expect(await vm.findDuplicates('Trà sữa trân châu'), isEmpty);
      expect(ai.prompts, isEmpty);
    });
  });

  group('Thêm món screen', () {
    late PurchaseHarness h;

    setUp(() => h = PurchaseHarness());
    tearDown(() => h.dispose());

    testWidgets(
      'suggests a group, applies it on tap and shows a similar purchase',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        vm.updateSources(
          purchases: [_purchase('p1', 'Tai nghe JBL Tune', 'tech')],
          wishlistItems: const [],
        );
        await h.initialize();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: vm,
            child: h.app(const AddItemScreen()),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Tai nghe Sony',
        );
        await tester.pump(); // rebuild with the new title starts the debounce
        expect(find.text('Gợi ý nhóm: Công nghệ'), findsNothing);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('Gợi ý nhóm: Công nghệ'), findsOneWidget);
        expect(find.text('Bạn đã có món tương tự'), findsOneWidget);
        expect(
          find.textContaining('Tai nghe JBL Tune · đã mua'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('budget-group-suggestion')));
        await tester.pumpAndSettle();
        expect(find.text('Gợi ý nhóm: Công nghệ'), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('wishlist-budget-group')),
            matching: find.text('Công nghệ'),
          ),
          findsOneWidget,
        );
        expect(
          ai.prompts,
          isEmpty,
          reason: 'keywords and clear matches need no AI',
        );
      },
    );
  });
}
