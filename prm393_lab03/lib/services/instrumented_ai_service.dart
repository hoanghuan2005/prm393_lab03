import 'dart:async';
import 'dart:typed_data';

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

  Future<T> _call<T>(
    String feature,
    Future<T> Function(String instruction) run,
    String builtIn,
  ) async {
    final instruction = promptFor(feature) ?? builtIn;
    unawaited(
      analyticsService?.logAiRequest(feature: feature, model: modelName()) ??
          Future<void>.value(),
    );
    try {
      return await run(instruction)
          .timeout(_timeouts[feature] ?? _defaultTimeout);
    } catch (e) {
      unawaited(
        analyticsService?.logAiError(
              feature: feature,
              errorType: errorTypeOf(e),
            ) ??
            Future<void>.value(),
      );
      rethrow;
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
  );
}
