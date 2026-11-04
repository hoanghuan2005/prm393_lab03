import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import 'service_guard.dart';

/// A JSON object whose fields can only take the listed values, so the model can pick
/// but never invent (budget group ids, ids of possible duplicates).
class AiChoiceSchema {
  /// field → allowed values; the answer holds exactly one of them
  final Map<String, List<String>> oneOf;

  /// field → allowed values; the answer holds a list of zero or more of them
  final Map<String, List<String>> manyOf;

  const AiChoiceSchema({this.oneOf = const {}, this.manyOf = const {}});
}

/// The only entry point to `firebase_ai`. Produces the raw JSON text for a prompt;
/// abstracted so tests can replace Gemini with a fake.
abstract interface class AiService {
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  });

  /// Classification only: the reply is limited to [schema]'s values, no free text
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  });

  /// A JSON object with exactly these string [fields] (e.g. one Decision Card reason)
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  });
}

/// Image + text prompts ("Chụp để tìm"). Kept apart from [AiService] so text-only
/// fakes in tests do not have to implement it.
abstract interface class AiImageService {
  /// A JSON object with these [fields]; list fields hold strings, the others one string
  Future<String> generateFromImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> fields,
    List<String> listFields = const [],
  });
}

/// One web page Google Search returned for a grounded answer
class WebSource {
  final String title;
  final Uri uri;

  const WebSource({required this.title, required this.uri});
}

/// Free text grounded on Google Search, with what the Gemini terms require the app to
/// show: the sources and Google's "Search suggestions" HTML ([searchEntryPointHtml]).
class GroundedText {
  final String text;
  final List<WebSource> sources;
  final String? searchEntryPointHtml;

  const GroundedText({
    required this.text,
    this.sources = const [],
    this.searchEntryPointHtml,
  });
}

/// Prompts answered with Google Search ("Chụp để tìm" → shop prices).
/// Grounding is a paid Gemini feature; callers keep it behind a Remote Config flag.
abstract interface class AiWebSearchService {
  Future<GroundedText> searchWeb({
    required String systemInstruction,
    required String prompt,
  });
}

/// Gemini through Firebase AI Logic: no API key is shipped in the app (spec 7.6)
class FirebaseAiService
    implements AiService, AiImageService, AiWebSearchService {
  final String Function() modelName;

  FirebaseAiService({required this.modelName});

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) => _generate(
    systemInstruction: systemInstruction,
    prompt: prompt,
    temperature: 0.4,
    schema: Schema.object(
      properties: {
        'summary': Schema.string(
          description: 'Đoạn chiêm nghiệm tháng, 2-3 câu',
        ),
        'cards': Schema.array(
          items: Schema.object(
            properties: {
              'id': Schema.enumString(enumValues: cardIds),
              'title': Schema.string(),
              'body': Schema.string(),
            },
          ),
        ),
      },
    ),
  );

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => _generate(
    systemInstruction: systemInstruction,
    prompt: prompt,
    temperature: 0,
    schema: Schema.object(
      properties: {
        for (final e in schema.oneOf.entries)
          e.key: Schema.enumString(enumValues: e.value),
        for (final e in schema.manyOf.entries)
          e.key: Schema.array(items: Schema.enumString(enumValues: e.value)),
      },
    ),
  );

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) => _generate(
    systemInstruction: systemInstruction,
    prompt: prompt,
    temperature: 0.4,
    schema: Schema.object(
      properties: {for (final f in fields) f: Schema.string()},
    ),
  );

  @override
  Future<String> generateFromImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> fields,
    List<String> listFields = const [],
  }) => _generate(
    systemInstruction: systemInstruction,
    prompt: prompt,
    image: InlineDataPart(mimeType, imageBytes),
    temperature: 0.2,
    schema: Schema.object(
      properties: {
        for (final f in fields) f: Schema.string(),
        for (final f in listFields) f: Schema.array(items: Schema.string()),
      },
    ),
  );

  @override
  Future<GroundedText> searchWeb({
    required String systemInstruction,
    required String prompt,
  }) => guard(() async {
    // No JSON schema here: the reply is plain text lines the caller parses
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName(),
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(temperature: 0.1),
      tools: [Tool.googleSearch()],
    );
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw const FormatException('Empty AI response');
    }
    final grounding = response.candidates.isEmpty
        ? null
        : response.candidates.first.groundingMetadata;
    final sources = <WebSource>[];
    for (final chunk
        in grounding?.groundingChunks ?? const <GroundingChunk>[]) {
      final web = chunk.web;
      final uri = Uri.tryParse(web?.uri ?? '');
      if (web == null || uri == null || uri.scheme != 'https') continue;
      sources.add(WebSource(title: web.title ?? uri.host, uri: uri));
    }
    return GroundedText(
      text: text,
      sources: sources,
      searchEntryPointHtml: grounding?.searchEntryPoint?.renderedContent,
    );
  });

  Future<String> _generate({
    required String systemInstruction,
    required String prompt,
    required double temperature,
    required Schema schema,
    InlineDataPart? image,
  }) => guard(() async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName(),
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: temperature,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
    final content = image == null
        ? Content.text(prompt)
        : Content.multi([TextPart(prompt), image]);
    final response = await model.generateContent([content]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw const FormatException('Empty AI response');
    }
    return text;
  });
}
