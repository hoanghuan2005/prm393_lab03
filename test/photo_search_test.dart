import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/models/item_recognition.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/services/ai_photo_search_service.dart';
import 'package:prm393_lab03/services/ai_price_search_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/viewmodels/photo_search_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  bool ai = true;
  bool priceFlag = true;

  @override
  bool getBool(String key) =>
      key == RemoteConfigService.keyEnableAiPriceSearch ? priceFlag : ai;

  @override
  String getString(String key) => '';
}

class _FakeVision implements AiImageService {
  String reply = '{}';
  Object? error;
  int calls = 0;
  String? lastMime;

  /// When set, the reply waits for this future (to test a newer photo winning)
  Future<void>? gate;

  @override
  Future<String> generateFromImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> fields,
    List<String> listFields = const [],
  }) async {
    calls++;
    lastMime = mimeType;
    final g = gate;
    if (g != null) await g;
    if (error != null) throw error!;
    return reply;
  }
}

class _FakeWeb implements AiWebSearchService {
  GroundedText reply = const GroundedText(text: 'NONE');
  Object? error;
  int calls = 0;
  String? lastPrompt;

  @override
  Future<GroundedText> searchWeb({
    required String systemInstruction,
    required String prompt,
  }) async {
    calls++;
    lastPrompt = prompt;
    if (error != null) throw error!;
    return reply;
  }
}

const _mouseReply = '''
{"name":"Chuột không dây MX Master 3S","brand":"Logitech","category":"Chuột máy tính",
 "alternatives":["Logitech MX Anywhere 3","Chuột không dây MX Master 3S"],
 "priceMinVnd":"2.490.000","priceMaxVnd":"1990000","confidence":"high"}''';

final _photo = Uint8List.fromList([1, 2, 3]);

void main() {
  group('AiPhotoSearchService.parse', () {
    test('reads the fields and cleans lists and prices', () {
      final r = AiPhotoSearchService.parse(_mouseReply);
      expect(r.name, 'Chuột không dây MX Master 3S');
      expect(r.brand, 'Logitech');
      expect(r.category, 'Chuột máy tính');
      // The main guess is not repeated as an alternative
      expect(r.alternatives, ['Logitech MX Anywhere 3']);
      // Swapped min/max and dotted digits are fixed
      expect(r.priceMinVnd, 1990000);
      expect(r.priceMaxVnd, 2490000);
      expect(r.confidence, RecognitionConfidence.high);
    });

    test('drops a half or absurd price range', () {
      final half = AiPhotoSearchService.parse(
        '{"name":"Bình nước","priceMinVnd":"100000","priceMaxVnd":""}',
      );
      expect(half.hasPriceRange, isFalse);
      final absurd = AiPhotoSearchService.parse(
        '{"name":"Bình nước","priceMinVnd":"5","priceMaxVnd":"9"}',
      );
      expect(absurd.hasPriceRange, isFalse);
    });

    test('unknown confidence is low; empty name means nothing found', () {
      final r = AiPhotoSearchService.parse('{"name":"  ","confidence":"sure"}');
      expect(r.isEmpty, isTrue);
      expect(r.confidence, RecognitionConfidence.low);
    });

    test('caps long text and list sizes', () {
      final r = AiPhotoSearchService.parse(
        '{"name":"${'a' * 200}","alternatives":["1","2","2","3","4","5"]}',
      );
      expect(r.name.length, AiPhotoSearchService.maxTextLength);
      // Duplicates dropped, then capped
      expect(r.alternatives, ['1', '2', '3']);
    });

    test('rejects a reply that is not a JSON object', () {
      expect(
        () => AiPhotoSearchService.parse('not json'),
        throwsFormatException,
      );
      expect(() => AiPhotoSearchService.parse('[1]'), throwsFormatException);
    });
  });

  group('ItemRecognition links', () {
    test('adds the brand only when the name lacks it', () {
      expect(
        ItemRecognition.searchQuery('MX Master 3S', brand: 'Logitech'),
        'Logitech MX Master 3S',
      );
      expect(
        ItemRecognition.searchQuery('Logitech MX Master 3S', brand: 'logitech'),
        'Logitech MX Master 3S',
      );
    });

    test('every shop link searches the query sorted cheapest first', () {
      expect(
        ShopSite.shopee.cheapestFirstUrl('chuột không dây').toString(),
        'https://shopee.vn/search?keyword=chu%E1%BB%99t+kh%C3%B4ng+d%C3%A2y'
        '&sortBy=price&order=asc',
      );
      expect(ShopSite.lazada.cheapestFirstUrl('mx master').queryParameters, {
        'q': 'mx master',
        'sort': 'priceasc',
      });
      expect(ShopSite.tiki.cheapestFirstUrl('mx master').queryParameters, {
        'q': 'mx master',
        'sort': 'price,asc',
      });
      final google = ShopSite.googleShopping.cheapestFirstUrl('mx master');
      expect(google.host, 'www.google.com');
      expect(google.queryParameters, {
        'tbm': 'shop',
        'q': 'mx master',
        'tbs': 'p_ord:p',
      });
      for (final site in ShopSite.values) {
        expect(site.cheapestFirstUrl('x').scheme, 'https');
      }
    });
  });

  group('AiPriceSearchService.parseOffers', () {
    test('reads OFFER lines, sorts by price, keeps the cheaper duplicate', () {
      final offers = AiPriceSearchService.parseOffers('''
Đây là kết quả:
OFFER | Shopee Mall Logitech | 1.290.000đ | https://shopee.vn/logitech-m510-i.1.2
1. OFFER | **Tiki** | 1,150,000 ₫ | https://tiki.vn/m510.html
- OFFER | FPT Shop | 1.390.000 – 1.450.000 |
OFFER | tiki | 1.200.000 | https://tiki.vn/other
OFFER | Hàng xách tay | liên hệ | https://example.vn
OFFER | Shop lạ | 5 |
OFFER | Link giả | 990.000 | javascript:alert(1)
''');
      expect(
        [for (final o in offers) o.shop],
        ['Link giả', 'Tiki', 'Shopee Mall Logitech', 'FPT Shop'],
      );
      expect(
        [for (final o in offers) o.priceVnd],
        [990000, 1150000, 1290000, 1390000],
      );
      expect(offers[1].url.toString(), 'https://tiki.vn/m510.html');
      // Only https links are kept
      expect(offers[0].url, isNull);
      expect(offers[3].url, isNull);
    });

    test('NONE or free text gives no offers', () {
      expect(AiPriceSearchService.parseOffers('NONE'), isEmpty);
      expect(
        AiPriceSearchService.parseOffers('Không tìm thấy thông tin.'),
        isEmpty,
      );
    });

    test('caps the number of offers', () {
      final text = [
        for (var i = 1; i <= 10; i++) 'OFFER | Shop $i | ${i}00000 |',
      ].join('\n');
      expect(
        AiPriceSearchService.parseOffers(text).length,
        AiPriceSearchService.maxOffers,
      );
    });
  });

  group('PhotoSearchViewModel price search', () {
    late _FakeVision ai;
    late _FakeWeb web;
    late _FakeRemoteConfig config;
    var mobile = true;

    PhotoSearchViewModel build() => PhotoSearchViewModel(
      aiService: AiPhotoSearchService(generator: ai),
      priceSearchService: AiPriceSearchService(generator: web),
      remoteConfigService: RemoteConfigService(remoteConfig: config),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => true,
      platformSupportsPriceSearch: () => mobile,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ai = _FakeVision()..reply = _mouseReply;
      web = _FakeWeb();
      config = _FakeRemoteConfig();
      mobile = true;
    });

    test('flag off or not mobile: no button, no call', () async {
      config.priceFlag = false;
      final vm = build();
      await vm.identify(_photo);
      expect(vm.canSearchPrices, isFalse);
      await vm.searchPrices();
      expect(web.calls, 0);

      config.priceFlag = true;
      mobile = false;
      expect(vm.canSearchPrices, isFalse);
    });

    test('searches the selected name and keeps the cheapest first', () async {
      web.reply = const GroundedText(
        text: 'OFFER | B | 500.000 |\nOFFER | A | 450.000 |',
        sources: [],
        searchEntryPointHtml: '<div>chips</div>',
      );
      final vm = build();
      await vm.identify(_photo);
      expect(vm.canSearchPrices, isTrue);
      await vm.searchPrices();
      final s = vm.priceState as UiSuccess;
      expect(s.data.cheapest.shop, 'A');
      expect(s.data.searchEntryPointHtml, '<div>chips</div>');
      expect(web.lastPrompt, contains('Logitech Chuột không dây MX Master 3S'));
    });

    test('choosing another name clears old prices', () async {
      web.reply = const GroundedText(text: 'OFFER | A | 450.000 |');
      final vm = build();
      await vm.identify(_photo);
      await vm.searchPrices();
      vm.selectName('Logitech MX Anywhere 3');
      expect(vm.priceState, isA<UiInitial>());
    });

    test('quota error gets its own message; nothing found is empty', () async {
      final vm = build();
      await vm.identify(_photo);

      web.error = const AppException(
        'ai-quota-exceeded',
        'Phần nhận xét AI đã hết lượt dùng hôm nay.',
      );
      await vm.searchPrices();
      expect(
        (vm.priceState as UiError).message,
        PhotoSearchViewModel.priceQuotaMessage,
      );

      web
        ..error = null
        ..reply = const GroundedText(text: 'NONE');
      await vm.searchPrices();
      expect(vm.priceState, isA<UiEmpty>());
    });
  });

  group('PhotoSearchViewModel', () {
    late _FakeVision ai;
    late _FakeRemoteConfig config;
    var platformOk = true;

    PhotoSearchViewModel build() => PhotoSearchViewModel(
      aiService: AiPhotoSearchService(generator: ai),
      remoteConfigService: RemoteConfigService(remoteConfig: config),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => platformOk,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ai = _FakeVision();
      config = _FakeRemoteConfig();
      platformOk = true;
    });

    test('a recognised photo ends in success with the name selected', () async {
      ai.reply = _mouseReply;
      final vm = build();
      await vm.identify(_photo, mimeType: 'image/png');
      expect(vm.state, isA<UiSuccess<ItemRecognition>>());
      expect(vm.selectedName, 'Chuột không dây MX Master 3S');
      expect(vm.searchQuery, 'Logitech Chuột không dây MX Master 3S');
      expect(vm.imageBytes, _photo);
      expect(ai.lastMime, 'image/png');
    });

    test(
      'choosing an alternative changes the search, without the brand',
      () async {
        ai.reply = _mouseReply;
        final vm = build();
        await vm.identify(_photo);
        vm.selectName('Logitech MX Anywhere 3');
        expect(vm.searchQuery, 'Logitech MX Anywhere 3');
      },
    );

    test('nothing found shows the empty state', () async {
      ai.reply = '{"name":""}';
      final vm = build();
      await vm.identify(_photo);
      final s = vm.state;
      expect(s, isA<UiEmpty<ItemRecognition>>());
      expect((s as UiEmpty).message, PhotoSearchViewModel.notFoundMessage);
    });

    test(
      'an AI failure shows an error, and retry sends the same photo',
      () async {
        ai.error = Exception('offline');
        final vm = build();
        await vm.identify(_photo);
        expect(vm.state, isA<UiError<ItemRecognition>>());

        ai
          ..error = null
          ..reply = _mouseReply;
        // The error's retry button is wired to vm.retry
        expect((vm.state as UiError).onRetry, isNotNull);
        await vm.retry();
        expect(vm.state, isA<UiSuccess<ItemRecognition>>());
        expect(ai.calls, 2);
      },
    );

    test('AI switched off: no call, explains how to turn it on', () async {
      config.ai = false;
      final vm = build();
      await vm.identify(_photo);
      expect(ai.calls, 0);
      expect((vm.state as UiError).message, PhotoSearchViewModel.aiOffMessage);
    });

    test('user switch "Dùng AI" off also blocks the call', () async {
      SharedPreferences.setMockInitialValues({'ai_insight_enabled': false});
      final vm = build();
      await vm.identify(_photo);
      expect(ai.calls, 0);
      expect(vm.state, isA<UiError<ItemRecognition>>());
    });

    test('platform without AI support is blocked', () async {
      platformOk = false;
      final vm = build();
      await vm.identify(_photo);
      expect(ai.calls, 0);
    });

    test('reset while analysing drops the late result and the photo', () async {
      final gate = Completer<void>();
      ai
        ..gate = gate.future
        ..reply = _mouseReply;
      final vm = build();
      final running = vm.identify(_photo);
      await Future<void>.delayed(Duration.zero);
      vm.reset();
      gate.complete();
      await running;
      expect(vm.state, isA<UiInitial<ItemRecognition>>());
      expect(vm.imageBytes, isNull);
    });

    test(
      'discard on leaving the screen drops the photo silently and ignores a late reply',
      () async {
        final gate = Completer<void>();
        ai
          ..gate = gate.future
          ..reply = _mouseReply;
        final vm = build();
        final running = vm.identify(_photo);
        await Future<void>.delayed(Duration.zero);
        var notified = 0;
        vm.addListener(() => notified++);
        vm.discard();
        expect(notified, 0);
        expect(vm.imageBytes, isNull);
        gate.complete();
        await running;
        expect(vm.state, isA<UiInitial<ItemRecognition>>());
        expect(notified, 0);
      },
    );
  });
}
