import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import 'buying_motive.dart';
import 'spending_insight.dart';

/// Flow 9 "Trước khi mua", screen 15 question 1: "Vì sao bạn muốn món này?"
enum WhyAnswer {
  need('Nhu cầu', Icons.shield_outlined, BuyingMotive.need),
  want('Mong muốn', Icons.auto_awesome_outlined, BuyingMotive.want),
  emotion('Cảm xúc', Icons.favorite_border, BuyingMotive.emotion),
  other('Khác', Icons.more_horiz, BuyingMotive.other);

  final String label;
  final IconData icon;
  final BuyingMotive motive;

  const WhyAnswer(this.label, this.icon, this.motive);
}

/// Screen 15 question 2: "Điều gì tác động đến lần mua này?"
enum InfluenceAnswer {
  sale('Khuyến mãi', Icons.local_offer_outlined, BuyingMotive.sale),
  social('Ảnh hưởng MXH', Icons.people_outline, BuyingMotive.social),
  ads('Quảng cáo', Icons.campaign_outlined, BuyingMotive.ads),
  none('Không có', Icons.more_horiz, null);

  final String label;
  final IconData icon;
  final BuyingMotive? motive;

  const InfluenceAnswer(this.label, this.icon, this.motive);
}

/// Screen 16 (only after "Khuyến mãi"): "Không có khuyến mãi, bạn vẫn muốn món này chứ?"
enum WithoutSaleAnswer {
  yes('Có, vẫn muốn', Icons.check_circle_outline),
  unsure('Chưa chắc', Icons.more_horiz),
  no('Không', Icons.local_offer_outlined);

  final String label;
  final IconData icon;

  const WithoutSaleAnswer(this.label, this.icon);
}

/// Added after testing: "Bạn sẽ dùng món này thường xuyên thế nào?"
enum UsageAnswer {
  daily('Hằng ngày', Icons.today_outlined),
  weekly('Vài lần mỗi tuần', Icons.date_range_outlined),
  sometimes('Thỉnh thoảng', Icons.event_outlined),
  unsure('Chưa rõ', Icons.help_outline);

  final String label;
  final IconData icon;

  const UsageAnswer(this.label, this.icon);
}

/// Added after testing: "Bạn đã có món nào làm được việc tương tự chưa?"
enum SimilarOwnedAnswer {
  none('Chưa có', Icons.add_circle_outline),
  worn('Có, nhưng đã cũ/hỏng', Icons.build_outlined),
  working('Có, vẫn dùng tốt', Icons.inventory_2_outlined);

  final String label;
  final IconData icon;

  const SimilarOwnedAnswer(this.label, this.icon);
}

/// Added after testing, only after "Cảm xúc": "Lúc này bạn đang cảm thấy thế nào?"
enum MoodAnswer {
  happy('Vui', Icons.sentiment_satisfied_alt_outlined),
  down('Buồn/chán', Icons.sentiment_dissatisfied_outlined),
  stressed('Căng thẳng', Icons.bolt_outlined),
  calm('Bình thường', Icons.sentiment_neutral_outlined);

  final String label;
  final IconData icon;

  const MoodAnswer(this.label, this.icon);
}

/// Everything the user typed and chose in "Trước khi mua". Nothing is stored:
/// the flow only shows an observation; "Vẫn mua" opens "Ghi khoản mua".
class PrePurchaseAnswers {
  final String title;
  final int? priceVnd;
  final WhyAnswer why;
  final InfluenceAnswer influence;

  /// Only when [influence] is [InfluenceAnswer.sale]
  final WithoutSaleAnswer? withoutSale;
  final UsageAnswer usage;
  final SimilarOwnedAnswer similar;

  /// Only when [why] is [WhyAnswer.emotion]
  final MoodAnswer? mood;

  PrePurchaseAnswers({
    required String title,
    this.priceVnd,
    required this.why,
    required this.influence,
    WithoutSaleAnswer? withoutSale,
    required this.usage,
    required this.similar,
    MoodAnswer? mood,
  }) : title = title.trim(),
       withoutSale = asksAboutSale(influence) ? withoutSale : null,
       mood = asksMood(why) ? mood : null;

  /// The "without the sale" step is shown only after "Khuyến mãi"
  static bool asksAboutSale(InfluenceAnswer? influence) =>
      influence == InfluenceAnswer.sale;

  /// The mood question is shown only after "Cảm xúc"
  static bool asksMood(WhyAnswer? why) => why == WhyAnswer.emotion;

  /// "389.000 ₫" or null
  String? get priceText => priceVnd == null ? null : formatVnd(priceVnd!);

  /// Motive pre-filled in "Ghi khoản mua" after "Vẫn mua"; the user can change it.
  /// The "why" answer, except: wanting it only because of the sale → Khuyến mãi;
  /// "Khác" with an outside influence → that influence.
  BuyingMotive get suggestedMotive {
    if (withoutSale == WithoutSaleAnswer.no) return BuyingMotive.sale;
    final outside = influence.motive;
    if (why == WhyAnswer.other && outside != null) return outside;
    return why.motive;
  }

  /// Motive looked up in the user's history: the outside influence when there is
  /// one (it is what the user is weighing), otherwise the reason they gave
  BuyingMotive get historyMotive => influence.motive ?? why.motive;

  /// Numbers an AI sentence may contain: those in the title and the price
  Set<int> get allowedNumbers => {
    ...MonthlySpendingStats.extractNumbers(title),
    if (priceText != null) ...MonthlySpendingStats.extractNumbers(priceText!),
  };

  Map<String, Object?> toPromptData() => {
    'tenMon': title,
    if (priceText != null) 'giaDuKienText': priceText,
    'viSaoMuon': why.label,
    'tacDong': influence.label,
    if (withoutSale != null) 'khongKhuyenMaiVanMuon': withoutSale!.label,
    'tanSuatDung': usage.label,
    'daCoMonTuongTu': similar.label,
    if (mood != null) 'tamTrang': mood!.label,
  };

  String get cacheKey => [
    title,
    priceVnd,
    why.name,
    influence.name,
    withoutSale?.name,
    usage.name,
    similar.name,
    mood?.name,
  ].join('|');
}

/// One card on screen 18: what the user's own answer suggests
class PrePurchaseObservation {
  final IconData icon;
  final String text;

  /// Chip under the text, e.g. "Mong muốn"
  final String chip;

  const PrePurchaseObservation({
    required this.icon,
    required this.text,
    required this.chip,
  });
}

/// One line of "Từ dữ liệu của bạn": a fact the code read from the user's own data
class PrePurchaseFact {
  final IconData icon;
  final String text;

  const PrePurchaseFact({required this.icon, required this.text});
}

/// Screen 18 "Nhận định trước khi mua"
class PrePurchaseInsight {
  final List<PrePurchaseObservation> observations;
  final List<PrePurchaseFact> facts;
  final String summary;
  final String question;

  /// False when the sentence is the template (AI off, failed or rejected)
  final bool summaryFromAi;
  final bool questionFromAi;

  const PrePurchaseInsight({
    required this.observations,
    this.facts = const [],
    required this.summary,
    required this.question,
    this.summaryFromAi = false,
    this.questionFromAi = false,
  });

  bool get usesAi => summaryFromAi || questionFromAi;

  PrePurchaseInsight withAi({String? summary, String? question}) =>
      PrePurchaseInsight(
        observations: observations,
        facts: facts,
        summary: summary ?? this.summary,
        question: question ?? this.question,
        summaryFromAi: summary != null,
        questionFromAi: question != null,
      );
}

/// Picks the cards and template sentences from the answers alone, so the result is
/// the same every time and never needs AI. Neutral wording only (spec 4.3): no advice
/// to buy or not to buy.
class PrePurchaseRules {
  PrePurchaseRules._();

  static PrePurchaseInsight templateInsight(
    PrePurchaseAnswers a, {
    List<PrePurchaseFact> facts = const [],
  }) => PrePurchaseInsight(
    observations: observationsFor(a),
    facts: facts,
    summary: templateSummary(a),
    question: templateQuestion(a),
  );

  static List<PrePurchaseObservation> observationsFor(PrePurchaseAnswers a) => [
    PrePurchaseObservation(
      icon: a.why.icon,
      chip: a.why.label,
      text: switch (a.why) {
        WhyAnswer.need =>
          'Bạn chọn Nhu cầu: món này đáp ứng một việc bạn cần, không chỉ là '
              'điều bạn thích.',
        WhyAnswer.want =>
          'Bạn chọn Mong muốn: món này hấp dẫn bạn, hơn là một nhu cầu bạn đã '
              'xác định.',
        WhyAnswer.emotion =>
          'Bạn chọn Cảm xúc: món này gắn với cảm giác của bạn lúc này.',
        WhyAnswer.other =>
          'Bạn chọn Khác: lý do của bạn chưa nằm trong các lựa chọn có sẵn.',
      },
    ),
    if (a.mood case final mood?)
      PrePurchaseObservation(
        icon: mood.icon,
        chip: 'Tâm trạng: ${mood.label}',
        text: switch (mood) {
          MoodAnswer.happy =>
            'Bạn đang vui. Niềm vui đôi khi khiến một món đồ trông hấp dẫn hơn '
                'bình thường.',
          MoodAnswer.down =>
            'Bạn đang buồn hoặc chán. Mua sắm lúc này có thể là một cách tìm '
                'lại cảm giác dễ chịu.',
          MoodAnswer.stressed => 'Bạn đang căng thẳng. Món đồ có thể đang hứa hẹn một chút nhẹ nhõm.',
          MoodAnswer.calm =>
            'Bạn đang bình thường, nên mong muốn này ít bị cảm xúc nhất thời '
                'chi phối.',
        },
      ),
    PrePurchaseObservation(
      icon: a.influence.icon,
      chip: a.influence == InfluenceAnswer.none
          ? 'Không có tác động'
          : a.influence.label,
      text: switch ((a.influence, a.withoutSale)) {
        (InfluenceAnswer.sale, WithoutSaleAnswer.yes) =>
          'Bạn chọn Khuyến mãi nhưng vẫn muốn món này khi không có ưu đãi. Ưu '
              'đãi là phần thêm, không phải lý do chính.',
        (InfluenceAnswer.sale, WithoutSaleAnswer.no) =>
          'Bạn chọn Khuyến mãi và sẽ không muốn món này nếu không có ưu đãi. Ưu '
              'đãi đang là lý do chính.',
        (InfluenceAnswer.sale, _) =>
          'Bạn chọn Khuyến mãi và chưa chắc sẽ muốn nó khi đủ giá. Ưu đãi là '
              'một phần sức hút.',
        (InfluenceAnswer.social, _) =>
          'Bạn chọn Ảnh hưởng MXH: món này đến với bạn qua người khác hoặc mạng '
              'xã hội.',
        (InfluenceAnswer.ads, _) =>
          'Bạn chọn Quảng cáo: món này đến với bạn qua một quảng cáo.',
        (InfluenceAnswer.none, _) =>
          'Bạn không thấy tác động nào từ bên ngoài: mong muốn này đến từ chính '
              'bạn.',
      },
    ),
    PrePurchaseObservation(
      icon: a.usage.icon,
      chip: 'Dùng: ${a.usage.label}',
      text: switch (a.usage) {
        UsageAnswer.daily =>
          'Bạn nghĩ mình sẽ dùng món này hằng ngày, nó sẽ là một phần thói quen '
              'của bạn.',
        UsageAnswer.weekly => 'Bạn nghĩ mình sẽ dùng món này vài lần mỗi tuần.',
        UsageAnswer.sometimes => 'Bạn nghĩ mình chỉ dùng món này thỉnh thoảng.',
        UsageAnswer.unsure =>
          'Bạn chưa hình dung rõ mình sẽ dùng món này lúc nào.',
      },
    ),
    PrePurchaseObservation(
      icon: a.similar.icon,
      chip: 'Đồ tương tự: ${a.similar.label}',
      text: switch (a.similar) {
        SimilarOwnedAnswer.none =>
          'Bạn chưa có món nào làm được việc này, nên đây sẽ là món đầu tiên.',
        SimilarOwnedAnswer.worn =>
          'Bạn đã có một món tương tự nhưng nó đã cũ hoặc hỏng, nên món mới sẽ '
              'là món thay thế.',
        SimilarOwnedAnswer.working =>
          'Bạn đang có một món làm được việc tương tự và vẫn dùng tốt, nên món '
              'mới sẽ là món thêm vào.',
      },
    ),
  ];

  static String templateSummary(PrePurchaseAnswers a) {
    final main = switch ((a.influence, a.withoutSale, a.why)) {
      (InfluenceAnswer.sale, WithoutSaleAnswer.yes, _) =>
        'Câu trả lời cho thấy món đồ quan trọng với bạn hơn ưu đãi.',
      (InfluenceAnswer.sale, WithoutSaleAnswer.no, _) =>
        'Câu trả lời cho thấy ưu đãi đang quan trọng với bạn hơn món đồ.',
      (InfluenceAnswer.sale, _, _) =>
        'Câu trả lời cho thấy cả món đồ lẫn ưu đãi đều quan trọng với bạn.',
      (InfluenceAnswer.social || InfluenceAnswer.ads, _, _) =>
        'Câu trả lời cho thấy một phần sức hút của món này đến từ bên ngoài.',
      (_, _, WhyAnswer.need) =>
        'Câu trả lời cho thấy món này gắn với một nhu cầu bạn đã xác định.',
      (_, _, WhyAnswer.want) =>
        'Câu trả lời cho thấy món này đến từ mong muốn của chính bạn.',
      (_, _, WhyAnswer.emotion) =>
        'Câu trả lời cho thấy cảm xúc lúc này có vai trò lớn trong lựa chọn.',
      (_, _, WhyAnswer.other) =>
        'Câu trả lời cho thấy bạn có lý do riêng cho món này.',
    };
    final detail = switch ((a.similar, a.usage)) {
      (SimilarOwnedAnswer.working, _) =>
        ' Bạn cũng đang có một món tương tự vẫn dùng tốt.',
      (_, UsageAnswer.unsure) =>
        ' Bạn chưa hình dung rõ mình sẽ dùng nó thế nào.',
      (_, UsageAnswer.sometimes) =>
        ' Bạn nghĩ mình sẽ chỉ dùng nó thỉnh thoảng.',
      (SimilarOwnedAnswer.worn, _) =>
        ' Món mới sẽ thay cho một món đã cũ hoặc hỏng.',
      _ => '',
    };
    return main + detail;
  }

  /// The answer that most deserves a second look picks the question
  static String templateQuestion(PrePurchaseAnswers a) {
    if (a.similar == SimilarOwnedAnswer.working) {
      return 'Món mới sẽ làm được điều gì mà món bạn đang có chưa làm được?';
    }
    if (a.mood == MoodAnswer.down || a.mood == MoodAnswer.stressed) {
      return 'Nếu tâm trạng khác đi, bạn có còn muốn món này không?';
    }
    if (a.usage == UsageAnswer.unsure) {
      return 'Bạn hình dung mình sẽ dùng món này vào lúc nào?';
    }
    return switch ((a.influence, a.why)) {
      (InfluenceAnswer.sale, _) =>
        'Không có khuyến mãi, điều gì khiến món này đáng mua với bạn?',
      (InfluenceAnswer.social, _) =>
        'Nếu không ai nhắc tới, bạn có còn nghĩ đến món này không?',
      (InfluenceAnswer.ads, _) =>
        'Trước khi thấy quảng cáo, bạn đã cần món này chưa?',
      (_, WhyAnswer.need) => 'Bạn sẽ dùng món này vào việc gì trong tuần tới?',
      (_, WhyAnswer.want) =>
        'Một tuần nữa, bạn nghĩ mình còn muốn món này không?',
      (_, WhyAnswer.emotion) => 'Cảm giác bạn mong có được từ món này là gì?',
      (_, WhyAnswer.other) => 'Điều gì khiến món này đáng với bạn lúc này?',
    };
  }
}
