import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/errors/app_exception.dart';
import 'ai_decision_service.dart';
import 'ai_insight_service.dart';
import 'ai_photo_search_service.dart';
import 'ai_pre_purchase_service.dart';
import 'ai_price_search_service.dart';
import 'ai_product_identity_service.dart';
import 'ai_service.dart';
import 'ai_suggestion_service.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// Wraps the one Gemini client for every AI feature (Final assignment section 8):
/// * the system instruction can be replaced from Remote Config `ai_prompts`;
/// * every call logs `ai_request`, and a failed one `ai_error` with its type.
///
/// The feature is recognised from the built-in instruction the caller passes, so the
/// feature services stay unchanged. Errors are rethrown: each feature keeps its own
/// fallback (template sentence or no suggestion).
class InstrumentedAiService
    implements AiService, AiImageService, AiWebSearchService {
  final AiService text;
  final AiImageService image;
  final AiWebSearchService web;
  final AppAnalyticsService? analyticsService;
  final String Function() modelName;

  /// Instruction set in the console for a feature; null keeps the built-in one
  final String? Function(String feature) promptFor;

  // Only share requests while they are running; feature services own result caches.
  final Map<String, Future<Object>> _inFlight = {};

  InstrumentedAiService({
    required this.text,
    required this.image,
    required this.web,
    required this.modelName,
    required this.promptFor,
    this.analyticsService,
  });

  /// Built-in instruction → feature. Group and duplicate share one instruction and
  /// are told apart by the answer they ask for.
  static final Map<String, String> _features = {
    AiInsightService.systemInstruction: AiFeatures.insight,
    AiDecisionService.systemInstruction: AiFeatures.decisionReason,
    AiDecisionService.planInstruction: AiFeatures.salePlan,
    AiSuggestionService.systemInstruction: AiFeatures.group,
    AiPrePurchaseService.systemInstruction: AiFeatures.prePurchase,
    AiPhotoSearchService.systemInstruction: AiFeatures.photoSearch,
    AiPriceSearchService.systemInstruction: AiFeatures.priceSearch,
    AiProductIdentityService.systemInstruction: AiFeatures.productIdentity,
  };

  static String featureOf(String instruction, {AiChoiceSchema? schema}) {
    final feature = _features[instruction] ?? AiFeatures.other;
    if (feature == AiFeatures.group && (schema?.manyOf.isNotEmpty ?? false)) {
      return AiFeatures.duplicate;
    }
    return feature;
  }

  /// A little shorter than each feature service's own timeout, so the timeout is
  /// noticed (and logged) here before the service gives up
  static const Map<String, Duration> _timeouts = {
    AiFeatures.insight: Duration(seconds: 24),
    AiFeatures.salePlan: Duration(seconds: 24),
    AiFeatures.photoSearch: Duration(seconds: 24),
    AiFeatures.priceSearch: Duration(seconds: 39),
  };
  static const Duration _defaultTimeout = Duration(seconds: 11);

  static String errorTypeOf(Object error) => switch (error) {
    TimeoutException() => AiErrorTypes.timeout,
    FormatException() => AiErrorTypes.emptyReply,
    AppException(code: 'ai-quota-exceeded') => AiErrorTypes.quota,
    AppException(code: 'ai-blocked') => AiErrorTypes.blocked,
    AppException(code: 'network') => AiErrorTypes.network,
    _ => AiErrorTypes.unavailable,
  };

  Future<T> _call<T extends Object>(
    String feature,
    Future<T> Function(String instruction) run,
    String builtIn,
    List<Object> input,
  ) async {
    final instruction = promptFor(feature) ?? builtIn;
    final model = modelName();
    final key = sha256
        .convert(
          utf8.encode(jsonEncode([feature, model, instruction, ...input])),
        )
        .toString();
    final running = _inFlight[key];
    if (running != null) return await (running as Future<T>);

    final request = _run(feature, model, instruction, run);
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      unawaited(_inFlight.remove(key));
    }
  }

  Future<T> _run<T>(
    String feature,
    String model,
    String instruction,
    Future<T> Function(String instruction) run,
  ) async {
    final stopwatch = Stopwatch()..start();
    var succeeded = false;
    unawaited(
      analyticsService?.logAiRequest(feature: feature, model: model) ??
          Future<void>.value(),
    );
    try {
      final result = await run(instruction)
          .timeout(_timeouts[feature] ?? _defaultTimeout);
      succeeded = true;
      return result;
    } catch (e) {
      unawaited(
        analyticsService?.logAiError(
              feature: feature,
              errorType: errorTypeOf(e),
            ) ??
            Future<void>.value(),
      );
      rethrow;
    } finally {
      stopwatch.stop();
      unawaited(
        analyticsService?.logAiResponse(
              feature: feature,
              model: model,
              durationMs: stopwatch.elapsedMilliseconds,
              succeeded: succeeded,
            ) ??
            Future<void>.value(),
      );
    }
  }

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) => _call(
    featureOf(systemInstruction),
    (instruction) => text.generateJson(
      systemInstruction: instruction,
      prompt: prompt,
      cardIds: cardIds,
    ),
    systemInstruction,
    ['json', prompt, cardIds],
  );

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => _call(
    featureOf(systemInstruction, schema: schema),
    (instruction) => text.generateChoice(
      systemInstruction: instruction,
      prompt: prompt,
      schema: schema,
    ),
    systemInstruction,
    ['choice', prompt, schema.oneOf, schema.manyOf],
  );

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) => _call(
    featureOf(systemInstruction),
    (instruction) => text.generateFields(
      systemInstruction: instruction,
      prompt: prompt,
      fields: fields,
    ),
    systemInstruction,
    ['fields', prompt, fields],
  );

  @override
  Future<String> generateFromImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> fields,
    List<String> listFields = const [],
  }) => _call(
    featureOf(systemInstruction),
    (instruction) => image.generateFromImage(
      systemInstruction: instruction,
      prompt: prompt,
      imageBytes: imageBytes,
      mimeType: mimeType,
      fields: fields,
      listFields: listFields,
    ),
    systemInstruction,
    [
      'image',
      prompt,
      mimeType,
      fields,
      listFields,
      sha256.convert(imageBytes).toString(),
    ],
  );

  @override
  Future<GroundedText> searchWeb({
    required String systemInstruction,
    required String prompt,
  }) => _call(
    featureOf(systemInstruction),
    (instruction) =>
        web.searchWeb(systemInstruction: instruction, prompt: prompt),
    systemInstruction,
    ['web', prompt],
  );
}
