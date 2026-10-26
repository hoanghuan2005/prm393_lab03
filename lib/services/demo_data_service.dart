import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/month_key.dart';
import '../models/budget_group.dart';
import '../models/buying_motive.dart';
import '../models/decision.dart';
import '../models/monthly_budget.dart';
import '../models/price_snapshot.dart';
import '../models/purchase_item.dart';
import '../models/reflection.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// Demo data for the Firebase Demo Area. Never runs on its own; only from explicit buttons.
abstract interface class DemoDataService {
  /// Replaces the user's data with one demo set (clears first, so repeated calls never
  /// duplicate): ~20 purchases (this month + last month), 6 wishlist items with prices
  /// and decisions, this month's budget and last month's reflection
  Future<void> seed(String uid);

  /// Deletes every subcollection of users/{uid} (incl. priceSnapshots);
  /// keeps the users/{uid} document and the budget groups
  Future<void> clearAll(String uid);
}

class FirestoreDemoDataService implements DemoDataService {
  final FirestorePaths _paths;

  FirestoreDemoDataService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<void> seed(String uid) => guard(() async {
    await clearAll(uid);
    final now = DateTime.now();
    final writer = _BatchWriter(_paths.db);

    for (final group in defaultBudgetGroups) {
      writer.set(
        _paths.budgetGroup(uid, group.id),
        group.toMap(),
        SetOptions(merge: true),
      );
    }

    // Purchases: 10 this month (up to today) + 10 last month
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final purchaseIds = <String>[];
    for (var i = 0; i < _purchases.length; i++) {
      final t = _purchases[i];
      final isThisMonth = i < 10;
      final occurredAt = isThisMonth
          ? _spreadInMonth(thisMonth, i, 10, lastDay: now.day, t: t)
          : _spreadInMonth(
              lastMonth,
              i - 10,
              10,
              lastDay: DateTime(now.year, now.month, 0).day,
              t: t,
            );
      final ref = _paths.purchases(uid).doc();
      purchaseIds.add(ref.id);
      writer.set(
        ref,
        PurchaseItem(
          id: ref.id,
          title: t.title,
          amountVnd: t.amount,
          motive: t.motive,
          occurredAt: occurredAt,
          budgetGroupId: t.groupId,
          usedDiscountCode: t.motive == BuyingMotive.sale,
          createdAt: occurredAt,
          updatedAt: occurredAt,
        ).toMap(),
      );
    }

    // Wishlist: one item per state
    const day = Duration(days: 1);
    final boughtPurchaseRef = _paths.purchases(uid).doc();
    final items = <(WishlistItem, List<int>, DecisionChoice?)>[
      (
        WishlistItem(
          id: '',
          title: 'Máy ảnh film mini',
          motive: BuyingMotive.emotion,
          priority: 3,
          cooldownUntil: now.add(day * 2),
          budgetGroupId: 'tech',
          latestPriceVnd: 450000,
          latestPriceAt: now.subtract(day),
          createdAt: now.subtract(day),
        ),
        [450000],
        null,
      ),
      (
        WishlistItem(
          id: '',
          title: 'Áo khoác len oversize',
          motive: BuyingMotive.want,
          priority: 4,
          cooldownUntil: now.subtract(day * 7),
          budgetGroupId: 'fashion',
          latestPriceVnd: 1290000,
          latestPriceAt: now.subtract(day * 2),
          createdAt: now.subtract(day * 10),
        ),
        [1390000, 1350000, 1290000],
        null,
      ),
      (
        WishlistItem(
          id: '',
          title: 'Bộ son dưỡng 3 màu',
          motive: BuyingMotive.sale,
          priority: 2,
          cooldownUntil: now.subtract(day * 2),
          reviewAt: now.add(day * 3),
          budgetGroupId: 'beauty',
          latestPriceVnd: 299000,
          latestPriceAt: now.subtract(day),
          createdAt: now.subtract(day * 5),
        ),
        [329000, 299000],
        DecisionChoice.wait,
      ),
      (
        WishlistItem(
          id: '',
          title: 'Khoá học tiếng Anh online',
          motive: BuyingMotive.social,
          priority: 3,
          cooldownUntil: now.add(day),
          budgetGroupId: 'study',
          createdAt: now.subtract(day * 2),
        ),
        [],
        null,
      ),
      (
        WishlistItem(
          id: '',
          title: 'Bình giữ nhiệt 500ml',
          motive: BuyingMotive.need,
          priority: 5,
          status: WishlistStatus.purchased,
          budgetGroupId: 'other',
          latestPriceVnd: 185000,
          latestPriceAt: now.subtract(day * 3),
          purchaseId: boughtPurchaseRef.id,
          createdAt: now.subtract(day * 6),
          decidedAt: now.subtract(day * 3),
        ),
        [185000],
        DecisionChoice.buy,
      ),
      (
        WishlistItem(
          id: '',
          title: 'Loa bluetooth mini',
          motive: BuyingMotive.ads,
          priority: 1,
          status: WishlistStatus.skipped,
          cooldownUntil: now.subtract(day * 4),
          budgetGroupId: 'tech',
          latestPriceVnd: 799000,
          latestPriceAt: now.subtract(day * 4),
          createdAt: now.subtract(day * 8),
          decidedAt: now.subtract(day * 2),
        ),
        [890000, 799000],
        DecisionChoice.skip,
      ),
    ];

    for (final (template, prices, choice) in items) {
      final ref = _paths.wishlistItems(uid).doc();
      final item = template.copyWith(id: ref.id, updatedAt: now);
      writer.set(ref, item.toMap());

      for (var i = 0; i < prices.length; i++) {
        final observedAt = item.createdAt.add(Duration(hours: 1 + i * 24 * 2));
        writer.set(
          _paths.priceSnapshots(uid, ref.id).doc(),
          PriceSnapshot(
            id: '',
            amountVnd: prices[i],
            source: PriceSource.demo,
            observedAt: observedAt.isAfter(now) ? now : observedAt,
          ).toMap(),
        );
      }

      if (choice != null) {
        writer.set(
          _paths.decisions(uid).doc(),
          Decision(
            id: '',
            itemId: ref.id,
            choice: choice,
            at: item.decidedAt ?? now.subtract(day),
            reviewAt: choice == DecisionChoice.wait ? item.reviewAt : null,
          ).toMap(),
        );
      }

      if (choice == DecisionChoice.buy) {
        final boughtAt = item.decidedAt!;
        writer.set(
          boughtPurchaseRef,
          PurchaseItem(
            id: boughtPurchaseRef.id,
            title: item.title,
            amountVnd: item.latestPriceVnd!,
            motive: item.displayMotive,
            occurredAt: boughtAt,
            budgetGroupId: item.budgetGroupId ?? BudgetGroup.otherId,
            wishlistItemId: ref.id,
            createdAt: boughtAt,
            updatedAt: boughtAt,
          ).toMap(),
        );
      }
    }

    writer.set(
      _paths.budget(uid, monthKey(thisMonth)),
      MonthlyBudget(
        month: monthKey(thisMonth),
        limits: const {'tech': 1000000, 'fashion': 600000, 'food': 1500000},
        updatedAt: now,
      ).toMap(),
    );

    writer.set(
      _paths.reflection(uid, monthKey(lastMonth)),
      Reflection(
        month: monthKey(lastMonth),
        rating: 4,
        goal: 'Để ý những lần mua sau 22h và chờ một ngày trước khi đặt.',
        updatedAt: now,
      ).toMap(),
    );

    await writer.commit();
  });

  @override
  Future<void> clearAll(String uid) => guard(() async {
    final writer = _BatchWriter(_paths.db);

    final items = await _paths.wishlistItems(uid).get();
    for (final item in items.docs) {
      final snapshots = await _paths.priceSnapshots(uid, item.id).get();
      for (final s in snapshots.docs) {
        writer.delete(s.reference);
      }
      writer.delete(item.reference);
    }

    for (final collection in [
      _paths.purchases(uid),
      _paths.decisions(uid),
      _paths.budgets(uid),
      _paths.reflections(uid),
    ]) {
      final docs = await collection.get();
      for (final doc in docs.docs) {
        writer.delete(doc.reference);
      }
    }

    await writer.commit();
  });

  /// Spreads purchase [index] of [count] over days 1..[lastDay] of [month] at the template's time
  static DateTime _spreadInMonth(
    DateTime month,
    int index,
    int count, {
    required int lastDay,
    required _PurchaseTemplate t,
  }) {
    final day = lastDay <= 1 ? 1 : 1 + (index * (lastDay - 1)) ~/ (count - 1);
    final at = DateTime(month.year, month.month, day, t.hour, t.minute);
    final now = DateTime.now();
    // Today's purchases must not be in the future
    return at.isAfter(now) ? now.subtract(Duration(minutes: index + 1)) : at;
  }

  /// 20 purchases: all 8 motives, all 6 groups, morning to late night (some after 22:00)
  static const List<_PurchaseTemplate> _purchases = [
    // This month
    _PurchaseTemplate(
      'Cơm tấm',
      40000,
      BuyingMotive.convenience,
      'food',
      12,
      15,
    ),
    _PurchaseTemplate(
      'Tai nghe Bluetooth',
      389000,
      BuyingMotive.sale,
      'tech',
      23,
      40,
    ),
    _PurchaseTemplate(
      'Trà sữa nướng',
      45000,
      BuyingMotive.emotion,
      'food',
      22,
      30,
    ),
    _PurchaseTemplate(
      'Sách Tâm lý học về tiền',
      143000,
      BuyingMotive.want,
      'study',
      9,
      20,
    ),
    _PurchaseTemplate(
      'Áo khoác gió',
      200000,
      BuyingMotive.sale,
      'fashion',
      19,
      45,
    ),
    _PurchaseTemplate(
      'Kem chống nắng',
      265000,
      BuyingMotive.ads,
      'beauty',
      21,
      10,
    ),
    _PurchaseTemplate(
      'Vé xem phim cùng bạn',
      120000,
      BuyingMotive.social,
      'other',
      18,
      5,
    ),
    _PurchaseTemplate('Cà phê sáng', 35000, BuyingMotive.need, 'food', 7, 50),
    _PurchaseTemplate(
      'Ốp lưng điện thoại',
      99000,
      BuyingMotive.other,
      'tech',
      14,
      25,
    ),
    _PurchaseTemplate(
      'Bút và sổ tay',
      68000,
      BuyingMotive.need,
      'study',
      10,
      40,
    ),
    // Last month
    _PurchaseTemplate(
      'Giày chạy bộ',
      1250000,
      BuyingMotive.need,
      'fashion',
      16,
      20,
    ),
    _PurchaseTemplate('Bàn phím cơ', 450000, BuyingMotive.want, 'tech', 23, 5),
    _PurchaseTemplate(
      'Cà phê & bánh ngọt',
      85000,
      BuyingMotive.emotion,
      'food',
      14,
      30,
    ),
    _PurchaseTemplate('Son dưỡng', 159000, BuyingMotive.ads, 'beauty', 22, 45),
    _PurchaseTemplate(
      'Áo thun basic',
      179000,
      BuyingMotive.sale,
      'fashion',
      20,
      0,
    ),
    _PurchaseTemplate(
      'Lẩu cùng nhóm bạn',
      230000,
      BuyingMotive.social,
      'food',
      19,
      30,
    ),
    _PurchaseTemplate(
      'Khoá học online',
      399000,
      BuyingMotive.want,
      'study',
      8,
      15,
    ),
    _PurchaseTemplate(
      'Gửi xe tháng',
      100000,
      BuyingMotive.convenience,
      'other',
      7,
      30,
    ),
    _PurchaseTemplate(
      'Cáp sạc nhanh',
      129000,
      BuyingMotive.convenience,
      'tech',
      11,
      45,
    ),
    _PurchaseTemplate(
      'Quà sinh nhật',
      300000,
      BuyingMotive.other,
      'other',
      17,
      10,
    ),
  ];
}

class _PurchaseTemplate {
  final String title;
  final int amount;
  final BuyingMotive motive;
  final String groupId;
  final int hour;
  final int minute;

  const _PurchaseTemplate(
    this.title,
    this.amount,
    this.motive,
    this.groupId,
    this.hour,
    this.minute,
  );
}

/// Splits writes into batches under Firestore's 500-operation limit
class _BatchWriter {
  static const int maxOps = 450;

  final FirebaseFirestore _db;
  final List<WriteBatch> _batches = [];
  int _ops = maxOps;

  _BatchWriter(this._db);

  WriteBatch get _current {
    if (_ops >= maxOps) {
      _batches.add(_db.batch());
      _ops = 0;
    }
    _ops++;
    return _batches.last;
  }

  void set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]) => _current.set(ref, data, options);

  void delete(DocumentReference<Map<String, dynamic>> ref) =>
      _current.delete(ref);

  Future<void> commit() async {
    for (final batch in _batches) {
      await batch.commit();
    }
  }
}
