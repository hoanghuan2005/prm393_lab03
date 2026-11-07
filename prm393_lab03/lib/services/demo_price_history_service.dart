import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/price_history_ids.dart';
import '../core/utils/product_code.dart';
import '../models/price_history.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// (done, total) documents of the current step
typedef DemoProgress = void Function(int done, int total);

/// Sample data of "Biểu đồ giá tham khảo" (admins only, from the Firebase Demo Area).
/// Every document is marked isDemo / source 'demo' and shown as "Dữ liệu mẫu".
abstract interface class DemoPriceHistoryService {
  /// Clears the old sample data, then writes a new set; returns documents written
  Future<int> seed({DemoProgress? onProgress});

  /// Deletes only sample documents (priceHistory isDemo, their 'demo' reports,
  /// productGroups isDemo); returns documents deleted
  Future<int> clearDemo({DemoProgress? onProgress});

  /// Sample groups (productGroups isDemo), in seed order
  Future<List<ProductGroup>> demoGroups();
}

class FirestoreDemoPriceHistoryService implements DemoPriceHistoryService {
  static const int maxBatchOps = 450;

  final FirestorePaths _paths;
  final DateTime Function() _now;

  FirestoreDemoPriceHistoryService([
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  ]) : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance),
       _now = now ?? DateTime.now;

  @override
  Future<int> seed({DemoProgress? onProgress}) => guard(() async {
    await clearDemo(onProgress: onProgress);
    final docs = DemoPriceHistoryData.generate(
      now: _now(),
      saleDays: await _publishedSaleDays(),
    );
    final db = _paths.db;
    return _commit([
      for (final d in docs) (WriteBatch b) => b.set(db.doc(d.path), d.data),
    ], onProgress);
  });

  @override
  Future<int> clearDemo({DemoProgress? onProgress}) => guard(() async {
    final refs = <DocumentReference<JsonMap>>[];
    final products = await _paths
        .priceHistory()
        .where('isDemo', isEqualTo: true)
        .get();
    for (final product in products.docs) {
      // Only sample reports: rules refuse to delete anyone else's
      final reports = await _paths
          .priceHistoryReports(product.id)
          .where('source', isEqualTo: HistoryReportSource.demo.key)
          .get();
      refs.addAll(reports.docs.map((d) => d.reference));
      refs.add(product.reference);
    }
    final groups = await _paths
        .productGroups()
        .where('isDemo', isEqualTo: true)
        .get();
    refs.addAll(groups.docs.map((d) => d.reference));
    return _commit([
      for (final ref in refs) (WriteBatch b) => b.delete(ref),
    ], onProgress);
  });

  @override
  Future<List<ProductGroup>> demoGroups() => guard(() async {
    final snapshot = await _paths
        .productGroups()
        .where('isDemo', isEqualTo: true)
        .get();
    int order(ProductGroup g) =>
        int.tryParse(g.id.replaceFirst('demo-group-', '')) ?? 1 << 20;
    return snapshot.docs.map(ProductGroup.fromFirestore).toList()
      ..sort((a, b) => order(a).compareTo(order(b)));
  });

  /// Published sale days of the web calendar; none when they cannot be read
  Future<Set<String>> _publishedSaleDays() async {
    try {
      final events = await _paths
          .saleEvents()
          .where('status', isEqualTo: 'published')
          .get();
      return {
        for (final e in events.docs)
          if (e.data()['date'] is Timestamp)
            PriceHistoryIds.dayKey((e.data()['date'] as Timestamp).toDate()),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Runs [ops] in batches of at most [maxBatchOps]
  Future<int> _commit(
    List<void Function(WriteBatch)> ops,
    DemoProgress? onProgress,
  ) async {
    onProgress?.call(0, ops.length);
    for (var start = 0; start < ops.length; start += maxBatchOps) {
      final batch = _paths.db.batch();
      final end = min(start + maxBatchOps, ops.length);
      for (var i = start; i < end; i++) {
        ops[i](batch);
      }
      await batch.commit();
      onProgress?.call(end, ops.length);
    }
    return ops.length;
  }
}

/// One document to write: full path and data
typedef DemoDoc = ({String path, Map<String, dynamic> data});

/// Generates the sample set. Pure and seeded: the same day gives the same data.
/// All names (products, brands, shops) are made up. A shop's list price holds for
/// 3–10 days and only changes for a sale or an adjustment; reports of the same day
/// and shop differ by under 1%, apart from ~5% far-off ones for the 30% filter.
///
/// G8: every product of a group shares a productCode (source 'demo', set here, no AI),
/// under titles written differently by each shop; each product sells 1–2 variants of
/// the group's two (one modelKey each). Outside the groups: a "trap" (same brand,
/// model with "Pro": another productCode) and 2 products whose title is too vague for a
/// code (productCode null). These 3 only have the last [extraDays] days of reports.
abstract final class DemoPriceHistoryData {
  static const int randomSeed = 20261106;
  static const int days = 90;
  static const int extraDays = 30;

  /// Reports of a product without variants
  static const String modelKey = 'none';

  /// One report count is drawn from here on a day with reports (mean 3, max 6)
  static const List<int> _reportsPerDay = [1, 1, 2, 2, 3, 3, 4, 5, 6];

  static List<DemoDoc> generate({
    required DateTime now,
    Set<String> saleDays = const {},
    int seed = randomSeed,
  }) {
    final rng = Random(seed);
    double round1(double v) => (v * 10).round() / 10;
    int vnd(double v) => max(1000, (v / 1000).round() * 1000);

    // Calendar days in Vietnam: day 0 is 89 days ago, day 89 is today. A date is a
    // UTC DateTime whose fields are the Vietnamese date; its midnight is 7 h earlier.
    final vnNow = now.toUtc().add(PriceHistoryIds.vietnamOffset);
    final today = DateTime.utc(vnNow.year, vnNow.month, vnNow.day);
    final dates = [
      for (var i = days - 1; i >= -6; i--) today.subtract(Duration(days: i)),
    ];
    bool isSale(DateTime d) =>
        d.month == d.day ||
        d.day == 15 ||
        d.day == 25 ||
        saleDays.contains(PriceHistoryIds.dayKey(_vnNoon(d)));
    final sale = [for (final d in dates) isSale(d)];
    final start = today.subtract(const Duration(days: days - 1));

    final docs = <DemoDoc>[];
    final ids = <int>{};
    int newId() {
      int id;
      do {
        id = 9000000000 + rng.nextInt(1000000);
      } while (!ids.add(id));
      return id;
    }

    final shopIds = <String, int>{};
    final shopRatings = <String, double>{};
    final modelIds = <int>{};
    String newModelKey() {
      int id;
      do {
        id = 100000000 + rng.nextInt(900000000);
      } while (!modelIds.add(id));
      return '$id';
    }

    /// One product and its reports from [firstDay] on; returns its productKey
    String addProduct({
      required String title,
      required String shopName,
      required double basePriceVnd,
      required double productRating,
      bool fake = false,
      String? groupId,
      String? productCode,
      List<String> variants = const [],
      int firstDay = 0,
    }) {
      final shopId = shopIds.putIfAbsent(shopName, newId);
      final shopRating = shopRatings.putIfAbsent(
        shopName,
        () => round1(4.0 + rng.nextDouble()),
      );
      final itemId = newId();
      final productKey = 'shopee:$shopId:$itemId';
      final modelKeys = [for (final _ in variants) newModelKey()];
      docs.add((
        path: 'priceHistory/$productKey',
        data: PriceHistoryProduct(
          productKey: productKey,
          title: title,
          shopId: '$shopId',
          itemId: '$itemId',
          shopName: shopName,
          groupId: groupId,
          isDemo: true,
          createdAt: start.subtract(PriceHistoryIds.vietnamOffset),
          productCode: productCode,
          productCodeSource: productCode == null
              ? null
              : ProductCodeSource.demo,
          variantCodes: {
            for (var v = 0; v < variants.length; v++)
              modelKeys[v]: buildVariantCode(variants[v])!,
          },
        ).toMap(),
      ));

      final base = vnd(basePriceVnd);
      final fakeRaise = 1.2 + rng.nextDouble() * 0.1;
      var ratingCount = 20 + rng.nextInt(800);
      // The shop's list price holds for 3–10 days, then it adjusts it (±4%)
      var shopPrice = base;
      var holdDays = 0;

      for (var i = firstDay; i < days; i++) {
        ratingCount += rng.nextInt(6);
        final date = dates[i];
        if (holdDays-- <= 0) {
          shopPrice = vnd(base * (0.96 + rng.nextDouble() * 0.08));
          holdDays = 2 + rng.nextInt(8);
        }
        var listPrice = shopPrice.toDouble();
        // "Giảm giá ảo": the price goes up in the 5 days before a sale
        final soonSale = [for (var k = 1; k <= 5; k++) sale[i + k]]
            .contains(true);
        if (fake && (soonSale || sale[i])) listPrice *= fakeRaise;
        final discount = 0.10 + rng.nextDouble() * 0.20;
        final dayPrice = vnd(sale[i] ? listPrice * (1 - discount) : listPrice);
        // Same-day reports differ by under 1%: ±0.4% in steps of 1.000 đ
        final jitter = dayPrice * 4 ~/ 1000 ~/ 1000;

        if (rng.nextDouble() < 0.4) continue;
        final count = _reportsPerDay[rng.nextInt(_reportsPerDay.length)];
        final dayStart = date.subtract(PriceHistoryIds.vietnamOffset);
        for (var n = 1; n <= count; n++) {
          var type = sale[i]
              ? (rng.nextDouble() < 0.3
                    ? HistoryPriceType.flash
                    : HistoryPriceType.sale)
              : HistoryPriceType.single;
          // Most reports see the very same price
          var amount =
              (dayPrice +
                      (jitter > 0 && rng.nextDouble() < 0.3
                          ? (rng.nextInt(2 * jitter + 1) - jitter) * 1000
                          : 0))
                  .toDouble();
          final roll = rng.nextDouble();
          if (roll < 0.05) {
            // After a voucher: 5–15% under the day's price
            type = HistoryPriceType.afterVoucher;
            amount = dayPrice * (0.85 + rng.nextDouble() * 0.10);
          } else if (roll < 0.08) {
            // A price range: its lowest price, the listed one
            type = HistoryPriceType.range;
          } else if (roll < 0.13) {
            // Outlier: more than 30% away from the median
            type = HistoryPriceType.single;
            amount =
                dayPrice *
                (rng.nextBool()
                    ? 0.55 + rng.nextDouble() * 0.1
                    : 1.4 + rng.nextDouble() * 0.15);
          }

          // Between 08:00 and 22:00, and never later than now
          var observedAt = dayStart.add(
            Duration(minutes: 8 * 60 + rng.nextInt(14 * 60)),
          );
          if (observedAt.isAfter(now)) {
            final sinceMidnight = now.difference(dayStart).inMinutes;
            observedAt = dayStart.add(
              Duration(minutes: rng.nextInt(max(1, sinceMidnight))),
            );
          }

          // Each report is for one of the variants the shop sells
          final model = modelKeys.isEmpty
              ? modelKey
              : modelKeys[rng.nextInt(modelKeys.length)];
          final rated = rng.nextDouble() >= 0.15;
          final id = PriceHistoryIds.demoReportId(n, model, _vnNoon(date));
          docs.add((
            path: 'priceHistory/$productKey/reports/$id',
            data: PriceHistoryReport(
              id: id,
              amountVnd: vnd(amount),
              priceType: type,
              modelKey: model,
              observedAt: observedAt,
              source: HistoryReportSource.demo,
              shopName: shopName,
              productRating: rated
                  ? round1(
                      (productRating + rng.nextDouble() * 0.2 - 0.1).clamp(
                        1.0,
                        5.0,
                      ),
                    )
                  : null,
              productRatingCount: rated ? ratingCount + n : null,
              shopRating: rated ? shopRating : null,
            ).toMap(),
          ));
        }
      }
      return productKey;
    }

    for (var g = 0; g < _groups.length; g++) {
      final group = _groups[g];
      final groupId = 'demo-group-${g + 1}';
      final factors = [
        for (final _ in group.listings) 0.88 + rng.nextDouble() * 0.24,
      ];
      final ratings = [
        for (final _ in group.listings) round1(3.6 + rng.nextDouble() * 1.4),
      ];
      // Every other group: the cheapest shop gets the lowest product rating, so the
      // cheapest listing is not always the best rated
      if (g.isEven) {
        final byPrice = List.generate(factors.length, (i) => i)
          ..sort((a, b) => factors[a].compareTo(factors[b]));
        final sorted = [...ratings]..sort();
        for (var r = 0; r < byPrice.length; r++) {
          ratings[byPrice[r]] = sorted[r];
        }
      }

      final code = buildProductCode(group.brand, group.model, group.spec);
      final keys = <String>[];
      for (var p = 0; p < group.listings.length; p++) {
        final (title, shopName) = group.listings[p];
        keys.add(
          addProduct(
            title: title,
            shopName: shopName,
            basePriceVnd: group.basePriceVnd * factors[p],
            productRating: ratings[p],
            fake: _fakeDiscounts.contains((g, p)),
            groupId: groupId,
            productCode: code,
            variants: _variantsOf(group.variants, p),
          ),
        );
      }
      docs.add((
        path: 'productGroups/$groupId',
        data: ProductGroup(
          id: groupId,
          name: group.name,
          productKeys: keys,
          isDemo: true,
        ).toMap(),
      ));
    }

    for (final extra in _extras) {
      addProduct(
        title: extra.title,
        shopName: extra.shopName,
        basePriceVnd: extra.basePriceVnd.toDouble(),
        productRating: round1(3.6 + rng.nextDouble() * 1.4),
        productCode: extra.brand == null
            ? null
            : buildProductCode(extra.brand, extra.model),
        variants: extra.variants,
        firstDay: days - extraDays,
      );
    }
    return docs;
  }

  /// Listing [p] of a group sells both variants, only the first or only the second,
  /// so each variant is sold by at least 2 shops
  static List<String> _variantsOf(List<String> variants, int p) =>
      switch (p % 4) {
        1 => [variants.first],
        3 => [variants.last],
        _ => variants,
      };

  /// Noon of a Vietnamese date, as an instant (safe for [PriceHistoryIds.dayKey])
  static DateTime _vnNoon(DateTime vnDate) => vnDate
      .add(const Duration(hours: 12))
      .subtract(PriceHistoryIds.vietnamOffset);

  /// (group, listing) of the 3 listings with a "giảm giá ảo"
  static const _fakeDiscounts = {(1, 2), (3, 0), (5, 1)};

  /// Outside the groups (G8): the trap and the 2 products without a code
  static const _extras = <_DemoExtra>[
    _DemoExtra(
      'Tai nghe Sonora Air 2 Pro chống ồn chủ động ANC',
      'Góc Âm Thanh 79',
      1150000,
      brand: 'Sonora',
      model: 'Air 2 Pro',
      variants: ['Đen', 'Trắng'],
    ),
    _DemoExtra(
      'Tai nghe bluetooth giá rẻ bass mạnh 🔥',
      'Tiệm Số Hai Lúa',
      120000,
    ),
    _DemoExtra(
      'Áo thun nam nữ form rộng hot trend',
      'Shop Mặc Đẹp Mỗi Ngày',
      99000,
    ),
  ];

  static const _groups = <_DemoGroup>[
    _DemoGroup(
      'Tai nghe không dây Sonora Air 2',
      'Công nghệ',
      650000,
      brand: 'Sonora',
      model: 'Air 2',
      variants: ['Đen', 'Trắng'],
      listings: [
        ('Tai nghe bluetooth Sonora Air 2 chống ồn', 'Nhà Tai Nghe Mây'),
        (
          'Sonora Air2 tai nghe không dây pin 30 giờ 🔥 Freeship',
          'Góc Âm Thanh 79',
        ),
        ('[Hàng chuẩn] Tai nghe Sonora Air 2 Bluetooth 5.3', 'Phụ Kiện Cầu Gỗ'),
        (
          'Tai nghe Sonora Air 2 kèm hộp sạc, bảo hành 12 tháng',
          'Tiệm Số Hai Lúa',
        ),
      ],
    ),
    _DemoGroup(
      'Đồng hồ thông minh Kairo Fit S',
      'Công nghệ',
      2400000,
      brand: 'Kairo',
      model: 'Fit S',
      variants: ['Đen', 'Hồng'],
      listings: [
        ('Đồng hồ thông minh Kairo Fit S đo nhịp tim', 'Góc Âm Thanh 79'),
        ('Kairo FitS smartwatch màn AMOLED 1.4 inch', 'Đồ Điện Tử Bến Mây'),
        ('Đồng hồ Kairo Fit S - chống nước, pin 10 ngày', 'Phụ Kiện Cầu Gỗ'),
        (
          '[Bản mới] Kairo Fit S đồng hồ sức khoẻ chính hãng BH 12T',
          'Kho Công Nghệ Lá Me',
        ),
      ],
    ),
    _DemoGroup(
      'Áo thun cotton Mộc Lam basic',
      'Thời trang',
      159000,
      brand: 'Mộc Lam',
      model: 'Basic',
      variants: ['Trắng', 'Xanh rêu'],
      listings: [
        ('Áo thun cotton Mộc Lam basic form rộng', 'Tủ Đồ Nhà Mơ'),
        ('Áo phông Mộc Lam trơn 100% cotton', 'Xưởng Áo Phố Gió'),
        ('Mộc Lam áo thun basic unisex nhiều màu', 'Shop Mặc Đẹp Mỗi Ngày'),
      ],
    ),
    _DemoGroup(
      'Giày chạy bộ Bước Nhẹ Runner 3',
      'Thời trang',
      890000,
      brand: 'Bước Nhẹ',
      model: 'Runner 3',
      variants: ['Xám', 'Đen'],
      listings: [
        ('Giày chạy bộ Bước Nhẹ Runner 3 đế êm', 'Kệ Giày Sông Xanh'),
        ('Bước Nhẹ Runner3 giày thể thao nam nữ', 'Xưởng Áo Phố Gió'),
        (
          'Giày Bước Nhẹ Runner 3 thoáng khí, nhẹ 230g',
          'Góc Thể Thao Đồi Thông',
        ),
        ('[Chính hãng Bước Nhẹ] Runner 3 giày chạy', 'Nhà Giày Hẻm Nhỏ'),
      ],
    ),
    _DemoGroup(
      'Kem chống nắng Hạ Vy SPF50+ 50ml',
      'Làm đẹp',
      285000,
      brand: 'Hạ Vy',
      model: 'SPF50+',
      spec: '50ml',
      variants: ['Nâng tông', 'Không màu'],
      listings: [
        ('Kem chống nắng Hạ Vy SPF50+ PA++++ 50ml', 'Tiệm Xinh Cô Út'),
        ('Hạ Vy chống nắng nâng tông 50ml SALE ✨', 'Góc Làm Đẹp Hoa Sứ'),
        ('Kem chống nắng Hạ Vy cho da dầu SPF 50+', 'Kệ Mỹ Phẩm Trăng Non'),
      ],
    ),
    _DemoGroup(
      'Son dưỡng có màu Mềm Môi',
      'Làm đẹp',
      129000,
      brand: 'Mềm Môi',
      model: 'Son dưỡng có màu',
      variants: ['Hồng đất', 'Cam cháy'],
      listings: [
        ('Son dưỡng có màu Mềm Môi 3.5g', 'Góc Làm Đẹp Hoa Sứ'),
        ('Mềm Môi son dưỡng ẩm màu hồng đất', 'Tiệm Xinh Cô Út'),
        ('Son dưỡng Mềm Môi không chì, lâu trôi', 'Kệ Mỹ Phẩm Trăng Non'),
        ('[Combo 1] Son dưỡng Mềm Môi tông cam', 'Nhà Son Phố Lụa'),
      ],
    ),
    _DemoGroup(
      'Hạt điều rang muối Vườn Nắng 500g',
      'Ăn uống',
      189000,
      brand: 'Vườn Nắng',
      model: 'Hạt điều rang muối',
      spec: '500g',
      variants: ['Còn vỏ lụa', 'Bóc vỏ'],
      listings: [
        ('Hạt điều rang muối Vườn Nắng hũ 500g', 'Bếp Quê Nhà Ngoại'),
        ('Điều rang muối Vườn Nắng loại 1, 500g', 'Kho Hạt Đồng Nội'),
        ('Hạt điều Vườn Nắng còn vỏ lụa 500 gram', 'Gian Hàng Ăn Vặt Ba Lá'),
      ],
    ),
    _DemoGroup(
      'Bút gel Ngòi Êm 0.5mm hộp 12 cây',
      'Học tập',
      65000,
      brand: 'Ngòi Êm',
      model: 'Bút gel',
      spec: 'hộp 12',
      variants: ['Mực xanh', 'Mực đen'],
      listings: [
        ('Bút gel Ngòi Êm 0.5mm hộp 12 cây mực xanh', 'Nhà Sách Giấy Thơm'),
        ('Hộp 12 bút gel Ngòi Êm nét 0.5', 'Văn Phòng Phẩm Cây Bút Chì'),
        ('Bút Ngòi Êm gel 0.5mm viết trơn, 12 cây', 'Góc Học Tập Bé Na'),
      ],
    ),
  ];
}

class _DemoGroup {
  final String name;

  /// Công nghệ, Thời trang, Làm đẹp, Ăn uống or Học tập (not stored)
  final String category;
  final int basePriceVnd;

  /// productCode of every listing: buildProductCode(brand, model, spec)
  final String brand;
  final String model;
  final String? spec;

  /// The two variants (colors…) of the item; each listing sells one or both
  final List<String> variants;

  /// (title, shop name) per shop: the same item named a little differently
  final List<(String, String)> listings;

  const _DemoGroup(
    this.name,
    this.category,
    this.basePriceVnd, {
    required this.brand,
    required this.model,
    this.spec,
    required this.variants,
    required this.listings,
  });
}

/// A product outside the groups; no brand means no productCode
class _DemoExtra {
  final String title;
  final String shopName;
  final int basePriceVnd;
  final String? brand;
  final String? model;
  final List<String> variants;

  const _DemoExtra(
    this.title,
    this.shopName,
    this.basePriceVnd, {
    this.brand,
    this.model,
    this.variants = const [],
  });
}
