import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../models/spending_insight.dart';

/// Produces the raw JSON text for a prompt. Abstracted so tests can replace Gemini with a fake.
abstract class InsightTextGenerator {
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  });
}

/// Gemini through Firebase AI Logic: no API key is shipped in the app (spec 7.6)
class FirebaseAiInsightGenerator implements InsightTextGenerator {
  final String Function() modelName;

  FirebaseAiInsightGenerator({required this.modelName});

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName(),
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'summary': Schema.string(description: 'Đoạn chiêm nghiệm tháng, 2-3 câu'),
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
  }
}

/// Writes Góc nhìn / Chiêm nghiệm wording. Code computes every number; AI only phrases them.
/// Any AI sentence with an unknown number or judgmental wording is replaced by the template.
class AiInsightService {
  final InsightTextGenerator generator;
  final Duration timeout;

  /// Successful reports keyed by [MonthlySpendingStats.cacheKey]; unchanged data is never re-sent
  final Map<String, InsightReport> _cache = {};

  AiInsightService({
    required this.generator,
    this.timeout = const Duration(seconds: 25),
  });

  static const int maxTitleLength = 70;
  static const int maxBodyLength = 300;
  static const int maxSummaryLength = 450;

  /// Wording the product must never show (spec 1.3, 4.3, 7.8)
  static const List<String> bannedPhrases = [
    'tiết kiệm',
    'nên mua',
    'không nên',
    'chắc chắn',
    'lãng phí',
    'phung phí',
    'hoang phí',
    'bốc đồng',
    'bạn phải',
    'đừng mua',
  ];

  static const String systemInstruction = '''
Bạn viết lời cho màn "Góc nhìn" và "Chiêm nghiệm tháng" của app Why I Buy, app giúp người trẻ nhìn lại vì sao mình mua.
Quy tắc bắt buộc:
1. Chỉ diễn giải dữ liệu JSON được cung cấp. Không thêm con số nào khác. Viết số tiền đúng như các trường kết thúc bằng "Text". Không tự làm tròn, không đổi sang "triệu" hay "k".
2. Không phán xét, không chấm điểm, không khuyên mua hay không mua. Không dùng các từ: tiết kiệm, nên mua, không nên, chắc chắn, lãng phí, phung phí, bốc đồng, bạn phải, đừng mua.
3. Giọng trung tính, ấm áp, xưng "bạn". Có thể kết bằng một câu hỏi gợi suy ngẫm.
4. Mỗi thẻ: "title" tối đa 60 ký tự; "body" 1-2 câu, tối đa 250 ký tự.
5. "summary": 2-3 câu, tối đa 400 ký tự, tóm tắt cả tháng.
6. Viết tiếng Việt có dấu. Chỉ trả về JSON đúng schema.''';

  /// Template sentences used when AI is off, unavailable, fails, or writes something not allowed
  InsightReport buildTemplateReport(MonthlySpendingStats stats) => _templateFor(stats);

  Future<InsightReport> generate(MonthlySpendingStats stats) async {
    final cached = _cache[stats.cacheKey];
    if (cached != null) return cached;

    final kinds = stats.applicableKinds;
    final raw = await generator
        .generateJson(
          systemInstruction: systemInstruction,
          prompt: buildPrompt(stats),
          cardIds: [for (final k in kinds) k.key],
        )
        .timeout(timeout);

    final report = parseResponse(raw, stats);
    if (report.source == InsightSource.ai) {
      _cache[stats.cacheKey] = report;
    }
    return report;
  }

  static String buildPrompt(MonthlySpendingStats stats) {
    final ids = stats.applicableKinds.map((k) => k.key).join(', ');
    return 'Dữ liệu tháng (JSON):\n'
        '${jsonEncode(stats.toPromptData())}\n\n'
        'Viết "summary" và đúng một thẻ cho mỗi id sau: $ids.\n'
        'Ý nghĩa id: dominant_motive = động cơ được ghi nhiều nhất; '
        'late_night = các khoản mua trong khung 22:00-05:00; '
        'month_over_month = so tổng đã chi với tháng trước; '
        'largest_purchase = khoản mua lớn nhất; '
        'skipped_items = các món người dùng đã cân nhắc và quyết định không mua (gọi là "giá trị món đã quyết định không mua").';
  }

  /// Validates the model output card by card; anything unusable falls back to the template
  @visibleForTesting
  static InsightReport parseResponse(String raw, MonthlySpendingStats stats) {
    final template = _templateFor(stats);
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return template;
      json = decoded;
    } on FormatException {
      return template;
    }

    final allowed = stats.allowedNumbers;
    final aiCards = <String, Map<String, dynamic>>{};
    final rawCards = json['cards'];
    if (rawCards is List) {
      for (final c in rawCards) {
        if (c is Map<String, dynamic> && c['id'] is String) aiCards[c['id'] as String] = c;
      }
    }

    final cards = <InsightCard>[];
    for (final kind in stats.applicableKinds) {
      final c = aiCards[kind.key];
      final title = c?['title'];
      final body = c?['body'];
      if (title is String &&
          body is String &&
          isAcceptable(title, allowed, maxTitleLength) &&
          isAcceptable(body, allowed, maxBodyLength)) {
        cards.add(InsightCard(kind: kind, title: title.trim(), body: body.trim(), fromAi: true));
      } else {
        cards.add(templateCard(kind, stats));
      }
    }

    final summary = json['summary'];
    final summaryOk = summary is String && isAcceptable(summary, allowed, maxSummaryLength);

    return InsightReport(
      summary: summaryOk ? summary.trim() : template.summary,
      summaryFromAi: summaryOk,
      cards: cards,
    );
  }

  /// Non-empty, within length, no banned wording, and every number is one the code computed
  static bool isAcceptable(String text, Set<int> allowedNumbers, int maxLength) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) return false;
    final lower = trimmed.toLowerCase();
    if (bannedPhrases.any(lower.contains)) return false;
    return MonthlySpendingStats.extractNumbers(trimmed).every(allowedNumbers.contains);
  }

  static InsightReport _templateFor(MonthlySpendingStats stats) => InsightReport(
        summary: templateSummary(stats),
        summaryFromAi: false,
        cards: [for (final kind in stats.applicableKinds) templateCard(kind, stats)],
      );

  static String templateSummary(MonthlySpendingStats stats) {
    if (!stats.hasPurchases) {
      return 'Tháng ${stats.month}/${stats.year} bạn chưa ghi khoản mua nào.';
    }
    final buffer = StringBuffer(
      'Tháng ${stats.month}/${stats.year} bạn đã ghi ${stats.purchaseCount} khoản mua, '
      'tổng ${MonthlySpendingStats.formatVnd(stats.totalSpent)}.',
    );
    final top = stats.dominantMotive;
    if (top != null) {
      buffer.write(' Động cơ bạn ghi nhiều nhất là ${top.motive.label} (${stats.sharePercent(top)}%).');
    }
    if (stats.skippedCount > 0) {
      buffer.write(' Bạn cũng đã cân nhắc và không mua ${stats.skippedCount} món.');
    }
    return buffer.toString();
  }

  static InsightCard templateCard(InsightKind kind, MonthlySpendingStats stats) {
    final vnd = MonthlySpendingStats.formatVnd;
    switch (kind) {
      case InsightKind.dominantMotive:
        final top = stats.dominantMotive!;
        return InsightCard(
          kind: kind,
          title: 'Động cơ ghi nhiều nhất: ${top.motive.label}',
          body: '${top.count}/${stats.purchaseCount} khoản mua tháng này bạn ghi là ${top.motive.label} '
              '(${stats.sharePercent(top)}%), tổng ${vnd(top.amount)}.',
          fromAi: false,
        );
      case InsightKind.lateNight:
        return InsightCard(
          kind: kind,
          title: 'Mua trong khung 22:00 - 05:00',
          body: 'Có ${stats.lateNightCount} khoản mua trong khung giờ này, tổng ${vnd(stats.lateNightAmount)}. '
              'Bạn còn nhớ lúc đó mình mua vì sao không?',
          fromAi: false,
        );
      case InsightKind.monthOverMonth:
        final change = stats.changeVsPreviousPercent ?? 0;
        final prev = stats.previousMonth;
        final comparison = change == 0
            ? 'tương đương tháng ${prev.month}/${prev.year}'
            : '${change > 0 ? 'cao' : 'thấp'} hơn tháng ${prev.month}/${prev.year} khoảng ${change.abs()}%';
        return InsightCard(
          kind: kind,
          title: 'So với tháng trước',
          body: 'Tổng đã chi bạn ghi tháng này là ${vnd(stats.totalSpent)}, $comparison '
              '(${vnd(stats.previousMonthTotal ?? 0)}).',
          fromAi: false,
        );
      case InsightKind.largestPurchase:
        final p = stats.largestPurchase!;
        final time = '${p.dateTime.hour.toString().padLeft(2, '0')}:${p.dateTime.minute.toString().padLeft(2, '0')}';
        return InsightCard(
          kind: kind,
          title: 'Khoản lớn nhất tháng',
          body: '${p.title}: ${vnd(p.amount.round())}, bạn ghi động cơ ${p.motive.label}, lúc $time.',
          fromAi: false,
        );
      case InsightKind.skippedItems:
        return InsightCard(
          kind: kind,
          title: 'Món đã quyết định không mua',
          body: 'Tháng này bạn đã cân nhắc và không mua ${stats.skippedCount} món, '
              'tổng giá đã ghi ${vnd(stats.skippedValue)}.',
          fromAi: false,
        );
    }
  }
}
