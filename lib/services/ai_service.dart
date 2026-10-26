import 'package:firebase_ai/firebase_ai.dart';

import 'service_guard.dart';

/// The only entry point to `firebase_ai`. Produces the raw JSON text for a prompt;
/// abstracted so tests can replace Gemini with a fake.
abstract interface class AiService {
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
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
  }) => guard(() async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName(),
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
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
