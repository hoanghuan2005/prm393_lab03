import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/available_budget.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';

PurchaseItem _p(
  int amount,
  DateTime at, {
  String? wishlistItemId,
  String group = 'fashion',
}) => PurchaseItem(
  id: '$amount-${at.toIso8601String()}',
  title: 'Khoản mua',
  amountVnd: amount,
  motive: BuyingMotive.want,
  occurredAt: at,
  budgetGroupId: group,
  wishlistItemId: wishlistItemId,
);

void main() {
  // 17/10/2026: 14 days left in October, as in the spec 7.1 example
  final now = DateTime(2026, 10, 17, 12);
  final october = DateTime(2026, 10);

  group('Spec 7.1 "phần khả dụng cho Wishlist"', () {
    test('worked example: 1.500.000 − 400.000 − 10.000 × 14 → × 0,9 = 864.000', () {
      final purchases = [
        _p(100000, now.subtract(const Duration(days: 89))),
        _p(400000, now.subtract(const Duration(days: 60))),
        _p(400000, DateTime(2026, 10, 5)), // this month
        // Bought from the wishlist: counts as spent in its month, never in the routine buffer
        _p(300000, now.subtract(const Duration(days: 30)), wishlistItemId: 'w1'),
      ];
      final b = AvailableBudget.compute(
        limit: 1500000,
        month: october,
        groupPurchases: purchases,
        firstPurchaseAt: now.subtract(const Duration(days: 120)),
        now: now,
      );
      expect(b.spent, 400000);
      expect(b.remaining, 1100000);
      expect(b.windowDays, 90);
      expect(b.dailyAverage, 10000);
      expect(b.daysLeft, 14);
      expect(b.buffer, 140000);
      expect(b.available, 864000);
    });

    test('new user (< 30 days of history): buffer is 0 and the note is shown', () {
      final b = AvailableBudget.compute(
        limit: 1500000,
        month: october,
        groupPurchases: [_p(400000, DateTime(2026, 10, 5))],
        firstPurchaseAt: DateTime(2026, 10, 5),
        now: now,
      );
      expect(b.hasEnoughHistory, isFalse);
      expect(b.buffer, 0);
      expect(b.available, 990000); // 1.100.000 × 0,9
    });

    test('45 days of history is averaged over 45 days, not diluted over 90', () {
      final b = AvailableBudget.compute(
        limit: 2000000,
        month: october,
        groupPurchases: [_p(450000, now.subtract(const Duration(days: 40)))],
        firstPurchaseAt: now.subtract(const Duration(days: 45)),
        now: now,
      );
      expect(b.windowDays, 45);
      expect(b.dailyAverage, 10000);
    });

    test('never negative when the limit is already exceeded', () {
      final b = AvailableBudget.compute(
        limit: 300000,
        month: october,
        groupPurchases: [_p(400000, DateTime(2026, 10, 5))],
        firstPurchaseAt: null,
        now: now,
      );
      expect(b.remaining, -100000);
      expect(b.available, 0);
    });

    test('days left: whole month in the future, 0 in the past', () {
      expect(AvailableBudget.daysLeftIn(DateTime(2026, 11), now), 30);
      expect(AvailableBudget.daysLeftIn(DateTime(2026, 9), now), 0);
    });
  });
}
