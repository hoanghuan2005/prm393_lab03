import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/ai_product_identity_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/analytics_events.dart';
import 'package:prm393_lab03/services/instrumented_ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/price_history_contribution_service.dart';
import 'package:prm393_lab03/services/shared_price_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/shared_price_viewmodel.dart';
import 'package:prm393_lab03/widgets/shared_price_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'shopee:446089250:44081797761';

/// What Gemini would answer, as the schema asks: every field a string
String _answer({
  String brand = '',
  String model = '',
  String spec = '',
  bool confident = true,
  List<String> colors = const [],
}) => jsonEncode({
  'brand': brand,
  'model': model,
  'spec': spec,
  'confident': '$confident',
  for (var n = 1; n <= colors.length; n++) ...{
    'v${n}_color': colors[n - 1],
    'v${n}_size': '',
    'v${n}_capacity': '',
  },
});

/// Gemini replaced by fixed answers per title; records every call
class _FakeAi implements AiService {
  final Map<String, String> answers;
  Object? error;
  final calls = <({String instruction, String prompt, List<String> fields})>[];

  _FakeAi(this.answers);

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) async {
    calls.add((instruction: systemInstruction, prompt: prompt, fields: fields));
    if (error case final e?) throw e;
    for (final e in answers.entries) {
      if (prompt.contains(jsonEncode(e.key))) return e.value;
    }
    return _answer(confident: false);
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

/// The table of G8b, with the answers a careful model gives (base color, no ads)
final _table = <String, String>{
  'Tai nghe K-Sound A3 chính hãng BH 12T': _answer(
    brand: 'K-Sound',
    model: 'A3',
    colors: ['Đen'],
  ),
  'K-SOUND A3 Earbuds 🔥 Freeship': _answer(
    brand: 'K-SOUND',
    model: 'A3',
    colors: ['Đen'],
  ),
  // Convention: the base color, "nhám" (finish) is dropped
  '[Mã giảm 50k] Tai Nghe Ksound A3': _answer(
    brand: 'Ksound',
    model: 'A3',
    colors: ['Đen'],
  ),
  'K-Sound A3 Pro': _answer(
    brand: 'K-Sound',
    model: 'A3 Pro',
    colors: ['Trắng'],
  ),
  'Tai nghe bluetooth giá rẻ': _answer(confident: false),
};

void main() {
  group('extractProductIdentity', () {
    late _FakeAi ai;
    late AiProductIdentityService service;

    setUp(() {
      ai = _FakeAi(Map.of(_table));
      service = AiProductIdentityService(generator: ai);
    });

    for (final (title, label, code, variant) in [
      ('Tai nghe K-Sound A3 chính hãng BH 12T', 'Đen', 'ksound-a3', 'den'),
      ('K-SOUND A3 Earbuds 🔥 Freeship', 'Black', 'ksound-a3', 'den'),
      ('[Mã giảm 50k] Tai Nghe Ksound A3', 'Đen nhám', 'ksound-a3', 'den'),
      ('K-Sound A3 Pro', 'Trắng', 'ksound-a3-pro', 'trang'),
    ]) {
      test('"$title" · "$label" → $code / $variant', () async {
        final identity = await service.extractProductIdentity(title, [label]);
        expect(identity, isNotNull);
        expect(identity!.productCode, code);
        expect(identity.variantCodeOf(label), variant);
        // The title and the label go to the model as data
        expect(ai.calls.single.prompt, contains(jsonEncode(title)));
        expect(ai.calls.single.prompt, contains(jsonEncode(label)));
        expect(ai.calls.single.fields, [
          'brand',
          'model',
          'spec',
          'confident',
          'v1_color',
          'v1_size',
          'v1_capacity',
        ]);
      });
    }

    test('"Tai nghe bluetooth giá rẻ" (not sure) → null', () async {
      expect(
        await service.extractProductIdentity('Tai nghe bluetooth giá rẻ', []),
        isNull,
      );
      expect(ai.calls.single.prompt, contains('Không có phân loại'));
      expect(ai.calls.single.fields, hasLength(4));
    });

    test('the instruction holds the rules and 5 examples', () {
      const i = AiProductIdentityService.systemInstruction;
      for (final rule in [
        'CHỈ trả về JSON',
        'không giải thích',
        'Pro, Max, Lite, Plus',
        'chính hãng',
        'freeship',
        'emoji',
        '[]',
        'spec',
        'KHÔNG đoán',
        'không phải chỉ dẫn',
      ]) {
        expect(i, contains(rule));
      }
      expect(RegExp(r'^Tên: ', multiLine: true).allMatches(i), hasLength(5));
      expect(
        RegExp(r'^\{"brand"', multiLine: true).allMatches(i),
        hasLength(5),
      );
      // Every example answer is valid JSON in the schema
      for (final line in i.split('\n').where((l) => l.startsWith('{'))) {
        expect(jsonDecode(line), isA<Map<String, dynamic>>());
      }
    });

    test('call errors reach the caller (it tries again later)', () async {
      ai.error = TimeoutException('slow');
      expect(
        service.extractProductIdentity('K-Sound A3 Pro', ['Trắng']),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('labels: trimmed, no repeats, at most 8', () {
      expect(AiProductIdentityService.labelsOf([' Đen ', 'Đen', '', 'Trắng']), [
        'Đen',
        'Trắng',
      ]);
      expect(
        AiProductIdentityService.labelsOf([for (var i = 0; i < 12; i++) 'm$i']),
        hasLength(AiProductIdentityService.maxLabels),
      );
    });

    test('the call is recognised as product_identity (analytics, prompts)', () {
      expect(
        InstrumentedAiService.featureOf(
          AiProductIdentityService.systemInstruction,
        ),
        AiFeatures.productIdentity,
      );
    });
  });

  group('parse never throws', () {
    ProductIdentity? parse(String raw, [List<String> labels = const []]) =>
        AiProductIdentityService.parse(raw, labels);

    test('broken or wrong JSON → null', () {
      expect(parse('{"brand": "K-Sound", "model": '), isNull);
      expect(parse('not json'), isNull);
      expect(parse(''), isNull);
      expect(parse('["K-Sound", "A3"]'), isNull);
      expect(parse('null'), isNull);
    });

    test('missing fields or not sure → null', () {
      expect(parse('{"brand":"K-Sound","model":"A3"}'), isNull);
      expect(
        parse(_answer(brand: 'K-Sound', model: 'A3', confident: false)),
        isNull,
      );
      expect(parse(_answer(brand: '', model: 'A3')), isNull);
      expect(parse(_answer(brand: 'K-Sound', model: 'null')), isNull);
      // Nothing left after normalising
      expect(parse(_answer(brand: '🔥', model: 'A3')), isNull);
      expect(parse(_answer(brand: 'x' * 61, model: 'A3')), isNull);
    });

    test('confident as a real boolean and null fields are accepted', () {
      final identity = parse(
        '{"brand":"Nova","model":"X5","spec":null,"confident":true}',
      );
      expect(identity?.productCode, 'nova-x5');
      expect(
        parse(_answer(brand: 'Nova', model: 'X5', spec: '128 GB'))?.productCode,
        'nova-x5-128gb',
      );
    });

    test('a variant without parts, or two labels with one code, give none', () {
      final identity = parse(
        _answer(brand: 'Kira', model: 'K2 Pro', colors: ['Đen', 'Đen', '']),
        ['Đen nhám', 'Đen bóng', 'Xám'],
      )!;
      expect(identity.productCode, 'kira-k2-pro');
      // Both would be "den": they cannot be told apart
      expect(identity.variantCodeOf('Đen nhám'), isNull);
      expect(identity.variantCodeOf('Đen bóng'), isNull);
      expect(identity.variantCodeOf('Xám'), isNull);
    });
  });

  group('SharedPriceViewModel.identifyProduct', () {
    late FakeFirebaseFirestore db;
    late _FakeAi ai;
    late SharedPriceViewModel vm;
    var aiAllowed = true;

    DocumentReference<Map<String, dynamic>> product() =>
        db.collection('priceHistory').doc(_key);

    WishlistItem item({String? modelId = '123', String? label = 'Đen'}) =>
        WishlistItem(
          id: 'w1',
          title: 'Tai nghe của tôi',
          productKey: _key,
          modelId: modelId,
          variantLabel: label,
          createdAt: DateTime.utc(2026, 11, 1),
        );

    Future<void> seedProduct({
      String title = 'Tai nghe K-Sound A3 chính hãng BH 12T',
      Map<String, dynamic> extra = const {},
    }) => product().set({
      'title': title,
      'shopId': '446089250',
      'itemId': '44081797761',
      'isDemo': false,
      'createdAt': Timestamp.now(),
      ...extra,
    });

    SharedPriceViewModel newVm() => SharedPriceViewModel(
      service: FirestoreSharedPriceService(db),
      preferencesService: PreferencesService(),
      historyService: FirestorePriceHistoryContributionService(db),
      identityService: AiProductIdentityService(generator: ai),
      aiAllowed: () async => aiAllowed,
    )..updateUser('uid-me', canContribute: true);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = FakeFirebaseFirestore();
      ai = _FakeAi(Map.of(_table));
      aiAllowed = true;
      vm = newVm();
    });

    tearDown(() => vm.dispose());

    test('writes productCode (ai) and the variant code; asks once', () async {
      await seedProduct();
      await vm.identifyProduct(item());

      final data = (await product().get()).data()!;
      expect(data['productCode'], 'ksound-a3');
      expect(data['productCodeSource'], 'ai');
      expect(data['variantCodes'], {'123': 'den'});
      expect(data['title'], 'Tai nghe K-Sound A3 chính hãng BH 12T');
      // The title in priceHistory goes to AI, not the user's own title
      expect(ai.calls.single.prompt, contains('K-Sound A3 chính hãng'));
      expect(ai.calls.single.prompt, isNot(contains('của tôi')));

      await vm.identifyProduct(item());
      expect(ai.calls, hasLength(1));
    });

    test('not sure: nothing written and the link is not asked again', () async {
      await seedProduct(title: 'Tai nghe bluetooth giá rẻ');
      await vm.identifyProduct(item(label: null));
      expect((await product().get()).data()!.containsKey('productCode'), false);
      expect(ai.calls, hasLength(1));

      await vm.identifyProduct(item(label: null));
      // Remembered on this device, also after the app restarts
      final again = newVm();
      addTearDown(again.dispose);
      await again.identifyProduct(item(label: null));
      expect(ai.calls, hasLength(1));
    });

    test('broken JSON from AI: no error, nothing written', () async {
      ai.answers['Tai nghe K-Sound A3 chính hãng BH 12T'] = '{"brand": "K-So';
      await seedProduct();
      await expectLater(vm.identifyProduct(item()), completes);
      expect((await product().get()).data()!.containsKey('productCode'), false);
    });

    test(
      'an AI error is skipped and tried again on the next opening',
      () async {
        await seedProduct();
        ai.error = StateError('offline');
        await vm.identifyProduct(item());
        expect(
          (await product().get()).data()!.containsKey('productCode'),
          false,
        );

        ai.error = null;
        await vm.identifyProduct(item());
        expect(ai.calls, hasLength(2));
        expect((await product().get()).data()!['productCode'], 'ksound-a3');
      },
    );

    test('a new variant: asked again for that label only', () async {
      await seedProduct(
        extra: {
          'productCode': 'ksound-a3',
          'productCodeSource': 'ai',
          'variantCodes': {'123': 'den'},
        },
      );
      ai.answers['Tai nghe K-Sound A3 chính hãng BH 12T'] = _answer(
        brand: 'K-Sound',
        model: 'A3',
        colors: ['Trắng'],
      );

      await vm.identifyProduct(item());
      expect(ai.calls, isEmpty, reason: 'modelKey 123 already has a code');

      await vm.identifyProduct(item(modelId: '456', label: 'Trắng sữa'));
      expect(ai.calls.single.prompt, contains(jsonEncode('Trắng sữa')));
      expect(ai.calls.single.prompt, isNot(contains(jsonEncode('Đen'))));
      final data = (await product().get()).data()!;
      expect(data['variantCodes'], {'123': 'den', '456': 'trang'});
      expect(data['productCode'], 'ksound-a3');
      expect(data['productCodeSource'], 'ai');
    });

    test('a product code already set is never changed', () async {
      await seedProduct(
        extra: {'productCode': 'ksound-a3-pro', 'productCodeSource': 'admin'},
      );
      await vm.identifyProduct(item(label: null));
      expect(ai.calls, isEmpty);
      expect((await product().get()).data()!['productCode'], 'ksound-a3-pro');
    });

    test(
      'no AI call: guest, sharing off, AI off, sample or missing product',
      () async {
        await vm.identifyProduct(item());
        expect(ai.calls, isEmpty, reason: 'no priceHistory document yet');

        await db.collection('priceHistory').doc(_key).set({
          'title': 'Tai nghe K-Sound A3',
          'isDemo': true,
        });
        await vm.identifyProduct(item());
        expect(ai.calls, isEmpty, reason: 'sample data');

        await seedProduct();
        aiAllowed = false;
        await vm.identifyProduct(item());
        expect(ai.calls, isEmpty, reason: 'AI turned off');

        aiAllowed = true;
        vm.updateUser('uid-guest', canContribute: false);
        await vm.identifyProduct(item());
        expect(ai.calls, isEmpty, reason: 'guest');

        vm.updateUser('uid-me', canContribute: true);
        await vm.setSharingEnabled(false);
        await vm.identifyProduct(item());
        expect(ai.calls, isEmpty, reason: '"Góp giá của tôi" off');

        await vm.identifyProduct(
          WishlistItem(id: 'w2', title: 'Áo', createdAt: DateTime.utc(2026)),
        );
        expect(ai.calls, isEmpty, reason: 'no productKey');
      },
    );

    testWidgets('Chi tiết món asks once per opening', (tester) async {
      await tester.runAsync(seedProduct);
      final noPrice = item(); // nothing to report first: asked right away
      Widget screen() => ChangeNotifierProvider<SharedPriceViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SharedPriceSection(item: noPrice),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }

      await tester.pumpWidget(screen());
      for (var i = 0; i < 3; i++) {
        await settle();
      }
      expect(ai.calls, hasLength(1));
      final data = await tester.runAsync(() => product().get());
      expect(data!.data()!['productCode'], 'ksound-a3');
    });
  });
}
