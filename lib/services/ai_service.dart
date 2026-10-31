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
}

/// Gemini through Firebase AI Logic: no API key is shipped in the app (spec 7.6)
class FirebaseAiService implements AiService {
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

  Future<String> _generate({
    required String systemInstruction,
    required String prompt,
    required double temperature,
    required Schema schema,
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
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw const FormatException('Empty AI response');
    }
    return text;
  });
}
