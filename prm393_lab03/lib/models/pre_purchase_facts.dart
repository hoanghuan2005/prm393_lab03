import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import 'available_budget.dart';
import 'item_suggestion.dart';
import 'owned_item.dart';
import 'pre_purchase_check.dart';
import 'purchase_item.dart';
import 'wishlist_item.dart';
import 'wishlist_status.dart';

/// "Từ dữ liệu của bạn" on screen 18: facts the code reads from the user's own
/// records, so the observation is about them and not generic. Every number here is
/// computed by code; AI may only repeat them. A fact without data is left out.
class PrePurchaseFacts {
  PrePurchaseFacts._();

  static const int maxFacts = 3;
  static const int similarPurchaseDays = 90;
  static const int motiveWindowDays = 30;

  /// Most telling first: something owned, a recent similar purchase or wishlist item,
  /// the budget, then the user's history with the same motive
  static List<PrePurchaseFact> build({
    required PrePurchaseAnswers answers,
    required DateTime now,
    List<PurchaseItem> purchases = const [],
    List<WishlistItem> wishlist = const [],
    List<OwnedItem> owned = const [],
    String? groupName,
    AvailableBudget? available,
  }) {
    final tokens = titleTokens(answers.title);
    bool similar(String other) =>
        compareTitles(tokens, titleTokens(other)) == TitleSimilarity.likely;

    final facts = <PrePurchaseFact>[];

    // Shopping profile (spec 7.2): owned item named or tagged like this one
    final ownedMatch = owned
        .where((o) => o.matches(title: answers.title))
        .firstOrNull;
    if (ownedMatch != null) {
      final note = ownedMatch.note?.trim();
      facts.add(
        PrePurchaseFact(
          icon: Icons.inventory_2_outlined,
          text:
              'Hồ sơ mua sắm ghi bạn đang có "${ownedMatch.name}"'
              '${note == null || note.isEmpty ? '' : ' ($note)'}.',
        ),
      );
    }

    // A recent purchase of the same kind of item
    final recent = [
      for (final p in purchases)
        if (now.difference(p.occurredAt).inDays <= similarPurchaseDays &&
            similar(p.title))
          p,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (recent.isNotEmpty) {
      final p = recent.first;
      final days = now.difference(p.occurredAt).inDays;
      final when = days == 0 ? 'Hôm nay' : '$days ngày trước';
      facts.add(
        PrePurchaseFact(
          icon: Icons.history,
          text: '$when bạn đã mua "${p.title}" (${formatVnd(p.amountVnd)}).',
        ),
      );
    }

    // Similar items already being weighed
    final waiting = [
      for (final w in wishlist)
        if (w.status == WishlistStatus.considering && similar(w.title)) w,
    ];
    if (waiting.isNotEmpty) {
      facts.add(
        PrePurchaseFact(
          icon: Icons.bookmark_border,
          text: waiting.length == 1
              ? 'Bạn đang cân nhắc "${waiting.first.title}" trong danh sách mong '
                    'muốn.'
              : 'Bạn đang cân nhắc ${waiting.length} món tương tự trong danh sách '
                    'mong muốn, như "${waiting.first.title}".',
        ),
      );
    }

    // Budget of the guessed group (spec 7.1 "phần khả dụng")
    final price = answers.priceVnd;
    if (price != null && groupName != null && available != null) {
      final left = available.available;
      facts.add(
        PrePurchaseFact(
          icon: Icons.account_balance_wallet_outlined,
          text: left > 0
              ? 'Món này bằng khoảng ${(price * 100 / left).round()}% phần khả dụng '
                    'của nhóm $groupName tháng này (${formatVnd(left)}).'
              : 'Nhóm $groupName tháng này không còn phần khả dụng cho món mới.',
        ),
      );
    }

    // How purchases with the same motive turned out (spec A-16)
    final motive = answers.historyMotive;
    final rated = [
      for (final p in purchases)
        if (p.motive == motive && p.satisfaction != null) p.satisfaction!,
    ];
    if (rated.length >= 2) {
      final average = rated.reduce((a, b) => a + b) / rated.length;
      facts.add(
        PrePurchaseFact(
          icon: Icons.star_border,
          text:
              'Các món bạn mua vì ${motive.label} được bạn chấm trung bình '
              '${formatAverage(average)}/5 (${rated.length} món).',
        ),
      );
    }

    // How often the same motive came up lately
    final sameMotive = purchases
        .where(
          (p) =>
              p.motive == motive &&
              now.difference(p.occurredAt).inDays <= motiveWindowDays,
        )
        .length;
    if (sameMotive >= 2) {
      facts.add(
        PrePurchaseFact(
          icon: Icons.receipt_long_outlined,
          text:
              '$motiveWindowDays ngày qua bạn đã ghi $sameMotive khoản mua vì '
              '${motive.label}.',
        ),
      );
    }

    return facts.take(maxFacts).toList();
  }

  /// 3.0 → "3", 3.5 → "3,5"
  static String formatAverage(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1).replaceAll('.', ',');
  }
}
