import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/formatters/money_format.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/spending_insight.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/services/ai_insight_service.dart';

PurchaseItem _purchase(String title, int amount, BuyingMotive motive, DateTime at) => PurchaseItem(
      id: title,
      title: title,
      amountVnd: amount,
      motive: motive,
      occurredAt: at,
    );

class _FakeGenerator implements InsightTextGenerator {
  String response;
  Object? error;
  int calls = 0;

  _FakeGenerator(this.response);

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  final october = DateTime(2026, 10, 1);
  final purchases = [
    _purchase('Tai nghe Bluetooth', 389000, BuyingMotive.sale, DateTime(2026, 10, 10, 23, 40)),
    _purchase('Áo khoác', 200000, BuyingMotive.sale, DateTime(2026, 10, 8, 19, 45)),
    _purchase('Trà sữa', 45000, BuyingMotive.emotion, DateTime(2026, 10, 10, 15, 30)),
    _purchase('Cơm tấm', 40000, BuyingMotive.convenience, DateTime(2026, 10, 11, 12, 15)),
    _purchase('Bàn phím', 450000, BuyingMotive.want, DateTime(2026, 9, 15, 10, 0)),
  ];
  final wishlist = [
    WishlistItem(
      id: 'w1',
      title: 'Đồng hồ',
      latestPriceVnd: 600000,
      motive: BuyingMotive.social,
      status: WishlistStatus.skipped,
      createdAt: DateTime(2026, 10, 1),
      decidedAt: DateTime(2026, 10, 5),
    ),
  ];

  MonthlySpendingStats octoberStats() =>
      MonthlySpendingStats.compute(month: october, purchases: purchases, wishlistItems: wishlist);

  group('MonthlySpendingStats (code computes every number)', () {
    test('aggregates the selected month only', () {
      final stats = octoberStats();
      expect(stats.purchaseCount, 4);
      expect(stats.totalSpent, 674000);
      expect(stats.dominantMotive!.motive, BuyingMotive.sale);
      expect(stats.dominantMotive!.count, 2);
      expect(stats.sharePercent(stats.dominantMotive!), 50);
      expect(stats.largestPurchase!.title, 'Tai nghe Bluetooth');
    });

    test('counts late-night purchases in 22:00-05:00', () {
      final stats = octoberStats();
      expect(stats.lateNightCount, 1);
      expect(stats.lateNightAmount, 389000);
    });

    test('compares with previous month', () {
      final stats = octoberStats();
      expect(stats.previousMonthTotal, 450000);
      expect(stats.changeVsPreviousPercent, 50);
    });

    test('skipped wishlist value is counted by decision month, not as savings', () {
      final stats = octoberStats();
      expect(stats.skippedCount, 1);
      expect(stats.skippedValue, 600000);
    });

    test('empty month has no observations and is not sent to AI', () {
      final stats = MonthlySpendingStats.compute(
        month: DateTime(2026, 12, 1),
        purchases: purchases,
        wishlistItems: const [],
      );
      expect(stats.hasPurchases, isFalse);
      expect(stats.hasEnoughDataForAi, isFalse);
      expect(stats.applicableKinds, isEmpty);
    });

    test('formats VND with dot separators', () {
      expect(formatVnd(1250000), '1.250.000 ₫');
      expect(MonthlySpendingStats.extractNumbers('1.250.000 ₫ lúc 23:40'), [1250000, 23, 40]);
    });
  });

  group('Template sentences', () {
    test('every template passes the same checks applied to AI output', () {
      final stats = octoberStats();
      final report = AiInsightService(generator: _FakeGenerator('{}')).buildTemplateReport(stats);
      expect(report.cards.map((c) => c.kind), stats.applicableKinds);
      for (final card in report.cards) {
        expect(AiInsightService.isAcceptable(card.title, stats.allowedNumbers, AiInsightService.maxTitleLength), isTrue,
            reason: card.title);
        expect(AiInsightService.isAcceptable(card.body, stats.allowedNumbers, AiInsightService.maxBodyLength), isTrue,
            reason: card.body);
      }
      expect(AiInsightService.isAcceptable(report.summary, stats.allowedNumbers, AiInsightService.maxSummaryLength),
          isTrue);
    });
  });

  group('AI output validation', () {
    String aiJson(Map<String, String> bodies, {String summary = 'Tháng 10/2026 bạn đã ghi 4 khoản mua.'}) =>
        jsonEncode({
          'summary': summary,
          'cards': [
            for (final e in bodies.entries) {'id': e.key, 'title': 'Tiêu đề', 'body': e.value},
          ],
        });

    test('accepts wording that only reuses computed numbers', () {
      final stats = octoberStats();
      final report = AiInsightService.parseResponse(
        aiJson({'dominant_motive': 'Một nửa số khoản mua (2/4, 50%) bạn ghi là Khuyến mãi, tổng 589.000 ₫.'}),
        stats,
      );
      final card = report.cards.firstWhere((c) => c.kind == InsightKind.dominantMotive);
      expect(card.fromAi, isTrue);
      expect(report.summaryFromAi, isTrue);
      expect(report.source, InsightSource.ai);
    });

    test('replaces a card that invents a number', () {
      final stats = octoberStats();
      final report = AiInsightService.parseResponse(
        aiJson({'dominant_motive': 'Giá món này sẽ giảm 30% vào thứ Hai.'}),
        stats,
      );
      final card = report.cards.firstWhere((c) => c.kind == InsightKind.dominantMotive);
      expect(card.fromAi, isFalse);
    });

    test('replaces judgmental wording', () {
      final stats = octoberStats();
      final report = AiInsightService.parseResponse(
        aiJson({'skipped_items': 'Bạn đã tiết kiệm được 600.000 ₫.'}),
        stats,
      );
      final card = report.cards.firstWhere((c) => c.kind == InsightKind.skippedItems);
      expect(card.fromAi, isFalse);
      expect(card.body, isNot(contains('tiết kiệm')));
    });

    test('missing cards fall back to templates, extra ids are ignored', () {
      final stats = octoberStats();
      final report = AiInsightService.parseResponse(aiJson({'unknown_card': 'x'}), stats);
      expect(report.cards.length, stats.applicableKinds.length);
      expect(report.cards.every((c) => !c.fromAi), isTrue);
    });

    test('malformed JSON gives the full template report', () {
      final stats = octoberStats();
      final report = AiInsightService.parseResponse('not json', stats);
      expect(report.source, InsightSource.template);
    });
  });

  group('AiInsightService.generate', () {
    test('unchanged data is served from cache without calling AI again', () async {
      final stats = octoberStats();
      final generator = _FakeGenerator(jsonEncode({
        'summary': 'Tháng 10/2026 bạn đã ghi 4 khoản mua.',
        'cards': <Object>[],
      }));
      final service = AiInsightService(generator: generator);

      await service.generate(stats);
      await service.generate(octoberStats());
      expect(generator.calls, 1);
    });

    test('AI errors propagate so the caller can fall back to templates (TC-21)', () async {
      final generator = _FakeGenerator('{}')..error = Exception('quota');
      final service = AiInsightService(generator: generator);
      expect(() => service.generate(octoberStats()), throwsException);
    });

    test('a fully rejected answer is not cached', () async {
      final generator = _FakeGenerator('not json');
      final service = AiInsightService(generator: generator);
      await service.generate(octoberStats());
      await service.generate(octoberStats());
      expect(generator.calls, 2);
    });
  });
}
