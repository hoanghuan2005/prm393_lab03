import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_insight_service.dart';
import 'package:prm393_lab03/services/ai_photo_search_service.dart';
import 'package:prm393_lab03/services/ai_pre_purchase_service.dart';
import 'package:prm393_lab03/services/ai_price_search_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/ai_suggestion_service.dart';
import 'package:prm393_lab03/services/analytics_events.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/instrumented_ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/viewmodels/item_suggestion_viewmodel.dart';

class _Analytics extends Fake implements AppAnalyticsService {
  final events = <String>[];
  final responses =
      <({String feature, String model, int durationMs, bool succeeded})>[];

  @override
  Future<void> logAiResponse({
    required String feature,
    required String model,
    required int durationMs,
    required bool succeeded,
  }) async => responses.add((
    feature: feature,
    model: model,
    durationMs: durationMs,
    succeeded: succeeded,
  ));

  @override
  Future<void> logAiRequest({
    required String feature,
    required String model,
  }) async => events.add('request:$feature:$model');

  @override
  Future<void> logAiError({
    required String feature,
    required String errorType,
  }) async => events.add('error:$feature:$errorType');

  @override
  Future<void> logAiResultAccepted({required String feature}) async =>
      events.add('accepted:$feature');
}

/// Records the instruction it was given; fails with [error] when set
class _Gemini implements AiService, AiImageService, AiWebSearchService {
  String? lastInstruction;
  Object? error;
  int calls = 0;
  Future<void>? gate;

  Future<String> _reply(String instruction) async {
    calls++;
    lastInstruction = instruction;
    final wait = gate;
    if (wait != null) await wait;
    if (error != null) throw error!;
    return '{}';
  }

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) => _reply(systemInstruction);

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => _reply(systemInstruction);

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) => _reply(systemInstruction);

  @override
  Future<String> generateFromImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> fields,
    List<String> listFields = const [],
  }) => _reply(systemInstruction);

  @override
  Future<GroundedText> searchWeb({
    required String systemInstruction,
    required String prompt,
  }) async => GroundedText(text: await _reply(systemInstruction));
}

class _Config extends Fake implements FirebaseRemoteConfig {
  String prompts = '{}';
  String model = 'gemini-test';

  @override
  String getString(String key) => switch (key) {
    RemoteConfigService.keyAiPrompts => prompts,
    RemoteConfigService.keyAiInsightModel => model,
    _ => '',
  };

  @override
  bool getBool(String key) => true;
}

void main() {
  late _Analytics analytics;
  late _Gemini gemini;
  late _Config config;
  late InstrumentedAiService ai;

  setUp(() {
    analytics = _Analytics();
    gemini = _Gemini();
    config = _Config();
    final remote = RemoteConfigService(remoteConfig: config);
    ai = InstrumentedAiService(
      text: gemini,
      image: gemini,
      web: gemini,
      modelName: () => remote.aiInsightModel,
      promptFor: remote.aiPromptFor,
      analyticsService: analytics,
    );
  });

  test('each built-in instruction is recognised as its feature', () {
    String of(String i, [AiChoiceSchema? s]) =>
        InstrumentedAiService.featureOf(i, schema: s);
    expect(of(AiInsightService.systemInstruction), AiFeatures.insight);
    expect(of(AiDecisionService.systemInstruction), AiFeatures.decisionReason);
    expect(of(AiDecisionService.planInstruction), AiFeatures.salePlan);
    expect(
      of(
        AiSuggestionService.systemInstruction,
        const AiChoiceSchema(
          oneOf: {
            'groupId': ['tech'],
          },
        ),
      ),
      AiFeatures.group,
    );
    expect(
      of(
        AiSuggestionService.systemInstruction,
        const AiChoiceSchema(
          manyOf: {
            'ids': ['c1'],
          },
        ),
      ),
      AiFeatures.duplicate,
    );
    expect(of(AiPrePurchaseService.systemInstruction), AiFeatures.prePurchase);
    expect(of(AiPhotoSearchService.systemInstruction), AiFeatures.photoSearch);
    expect(of(AiPriceSearchService.systemInstruction), AiFeatures.priceSearch);
    expect(of('something else'), AiFeatures.other);
  });

  test('every call logs ai_request with the feature and the model', () async {
    await ai.generateJson(
      systemInstruction: AiInsightService.systemInstruction,
      prompt: 'p',
      cardIds: const ['dominant_motive'],
    );
    expect(analytics.events, ['request:insight:gemini-test']);
    expect(gemini.lastInstruction, AiInsightService.systemInstruction);
    expect(analytics.responses.single.feature, AiFeatures.insight);
    expect(analytics.responses.single.model, 'gemini-test');
    expect(analytics.responses.single.succeeded, isTrue);
    expect(analytics.responses.single.durationMs, greaterThanOrEqualTo(0));
  });

  test(
    'identical concurrent requests share one call, completed results do not',
    () async {
      final gate = Completer<void>();
      gemini.gate = gate.future;
      Future<String> request() => ai.generateFields(
        systemInstruction: AiPrePurchaseService.systemInstruction,
        prompt: 'same answers',
        fields: const ['summary'],
      );
      final first = request();
      final second = request();
      expect(gemini.calls, 1);
      gate.complete();
      expect(await Future.wait([first, second]), ['{}', '{}']);
      expect(analytics.responses, hasLength(1));
      await request();
      expect(gemini.calls, 2);
    },
  );

  test(
    'different prompts, schemas and remote instructions are not shared',
    () async {
      final gate = Completer<void>();
      gemini.gate = gate.future;
      Future<String> request(String prompt, List<String> fields) =>
          ai.generateFields(
            systemInstruction: AiPrePurchaseService.systemInstruction,
            prompt: prompt,
            fields: fields,
          );
      final calls = [
        request('a', ['summary']),
        request('b', ['summary']),
        request('a', ['question']),
      ];
      config.prompts = '{"pre_purchase":"new instruction"}';
      calls.add(request('a', ['summary']));
      expect(gemini.calls, 4);
      gate.complete();
      await Future.wait(calls);
    },
  );

  test(
    'identical photo bytes share a call, a different photo does not',
    () async {
      final gate = Completer<void>();
      gemini.gate = gate.future;
      Future<String> request(List<int> bytes) => ai.generateFromImage(
        systemInstruction: AiPhotoSearchService.systemInstruction,
        prompt: 'photo',
        imageBytes: Uint8List.fromList(bytes),
        mimeType: 'image/jpeg',
        fields: const ['name'],
      );
      final calls = [
        request([1, 2]),
        request([1, 2]),
        request([1, 3]),
      ];
      expect(gemini.calls, 2);
      gate.complete();
      await Future.wait(calls);
    },
  );

  test(
    'shared failures are removed so an explicit retry can succeed',
    () async {
      final gate = Completer<void>();
      gemini
        ..gate = gate.future
        ..error = StateError('offline');
      Future<String> request() => ai.generateFields(
        systemInstruction: AiPrePurchaseService.systemInstruction,
        prompt: 'same answers',
        fields: const ['summary'],
      );
      final first = expectLater(request(), throwsStateError);
      final second = expectLater(request(), throwsStateError);
      expect(gemini.calls, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(analytics.responses.single.succeeded, isFalse);
      gemini.error = null;
      expect(await request(), '{}');
      expect(gemini.calls, 2);
    },
  );

  test(
    'a prompt set in Remote Config replaces that feature\'s instruction only',
    () async {
      config.prompts = '{"insight": "Prompt từ Console", "group": "  "}';
      await ai.generateJson(
        systemInstruction: AiInsightService.systemInstruction,
        prompt: 'p',
        cardIds: const [],
      );
      expect(gemini.lastInstruction, 'Prompt từ Console');

      // Blank value: keeps the built-in instruction
      await ai.generateChoice(
        systemInstruction: AiSuggestionService.systemInstruction,
        prompt: 'p',
        schema: const AiChoiceSchema(
          oneOf: {
            'groupId': ['tech'],
          },
        ),
      );
      expect(gemini.lastInstruction, AiSuggestionService.systemInstruction);
    },
  );

  test('invalid ai_prompts JSON keeps every built-in instruction', () {
    config.prompts = '{not json';
    expect(
      RemoteConfigService(remoteConfig: config).aiPromptFor('insight'),
      isNull,
    );
  });

  for (final method in ['json', 'choice', 'web']) {
    test(
      '$method calls with the same input share one pending request',
      () async {
        final gate = Completer<void>();
        gemini.gate = gate.future;
        Future<Object> request() => switch (method) {
          'json' => ai.generateJson(
            systemInstruction: AiInsightService.systemInstruction,
            prompt: 'same',
            cardIds: const ['dominant_motive'],
          ),
          'choice' => ai.generateChoice(
            systemInstruction: AiSuggestionService.systemInstruction,
            prompt: 'same',
            schema: const AiChoiceSchema(
              oneOf: {
                'groupId': ['tech'],
              },
            ),
          ),
          _ => ai.searchWeb(
            systemInstruction: AiPriceSearchService.systemInstruction,
            prompt: 'same',
          ),
        };
        final calls = [request(), request()];
        expect(gemini.calls, 1);
        gate.complete();
        await Future.wait(calls);
      },
    );
  }

  test(
    'changing the model does not share a previous pending request',
    () async {
      final gate = Completer<void>();
      gemini.gate = gate.future;
      Future<String> request() => ai.generateFields(
        systemInstruction: AiPrePurchaseService.systemInstruction,
        prompt: 'same',
        fields: const ['summary'],
      );
      final first = request();
      config.model = 'new-model';
      final second = request();
      expect(gemini.calls, 2);
      gate.complete();
      await Future.wait([first, second]);
    },
  );

  testWidgets(
    'a timeout allows retry while the original response is still pending',
    (tester) async {
      final oldGate = Completer<void>();
      gemini.gate = oldGate.future;
      Future<String> request() => ai.generateFields(
        systemInstruction: AiPrePurchaseService.systemInstruction,
        prompt: 'same',
        fields: const ['summary'],
      );
      final expired = expectLater(request(), throwsA(isA<TimeoutException>()));
      await tester.pump(const Duration(seconds: 12));
      await expired;
      expect(analytics.responses.single.succeeded, isFalse);
      final retryGate = Completer<void>();
      gemini.gate = retryGate.future;
      final retry = request();
      oldGate.complete();
      await tester.pump();
      final sharedRetry = request();
      expect(gemini.calls, 2);
      retryGate.complete();
      await tester.pump();
      await Future.wait([retry, sharedRetry]);
    },
  );

  test('a failed call logs ai_error with its type and still fails', () async {
    gemini.error = const AppException('ai-quota-exceeded', 'hết lượt');
    await expectLater(
      ai.generateFields(
        systemInstruction: AiPrePurchaseService.systemInstruction,
        prompt: 'p',
        fields: const ['summary'],
      ),
      throwsA(isA<AppException>()),
    );
    expect(analytics.events, [
      'request:pre_purchase:gemini-test',
      'error:pre_purchase:quota',
    ]);
    expect(analytics.responses.single.succeeded, isFalse);
  });

  test('errors are sorted into the planned error types', () {
    String of(Object e) => InstrumentedAiService.errorTypeOf(e);
    expect(of(TimeoutException('slow')), AiErrorTypes.timeout);
    expect(
      of(const FormatException('Empty AI response')),
      AiErrorTypes.emptyReply,
    );
    expect(of(const AppException('ai-quota-exceeded', '')), AiErrorTypes.quota);
    expect(of(const AppException('ai-blocked', '')), AiErrorTypes.blocked);
    expect(of(const AppException('network', '')), AiErrorTypes.network);
    expect(
      of(const AppException('ai-unavailable', '')),
      AiErrorTypes.unavailable,
    );
  });

  test('accepting an AI suggestion logs ai_result_accepted', () {
    final vm = ItemSuggestionViewModel(
      aiSuggestionService: AiSuggestionService(generator: gemini),
      remoteConfigService: RemoteConfigService(remoteConfig: config),
      preferencesService: PreferencesService(),
      analyticsService: analytics,
    );
    vm.aiResultAccepted(AiFeatures.group);
    expect(analytics.events, ['accepted:group']);
    vm.dispose();
  });
}
