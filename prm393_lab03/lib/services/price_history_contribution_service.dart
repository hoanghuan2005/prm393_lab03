import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/price_history_ids.dart';
import '../models/price_history.dart';
import '../models/shopee_link.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// G7: the user's own price, sent anonymously to "Giá tham khảo". The report holds no
/// uid, name or link; its id is sha256("uid|productKey|modelKey|yyyyMMdd"), checked by
/// firestore.rules, so each person has one report per variant and day.
abstract interface class PriceHistoryContributionService {
  /// Creates priceHistory/{productKey} when it is missing (or fills its empty shop
  /// name), then creates or replaces this person's report of that day. Nothing is
  /// written into sample data (isDemo).
  Future<void> contribute({
    required String uid,
    required String productKey,
    required String title,
    String? shopName,
    required PriceHistoryReport report,
  });
}

class FirestorePriceHistoryContributionService
    implements PriceHistoryContributionService {
  final FirestorePaths _paths;

  FirestorePriceHistoryContributionService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<void> contribute({
    required String uid,
    required String productKey,
    required String title,
    String? shopName,
    required PriceHistoryReport report,
  }) => guard(() async {
    final link = ShopeeLink.fromProductKey(productKey);
    if (link == null) return;
    final productRef = _paths.priceHistoryProduct(productKey);
    final product = await productRef.get();
    if (product.data()?['isDemo'] == true) return;

    final batch = _paths.db.batch();
    // firestore.rules need the product (in this batch or before) for every report. The
    // first person to report creates it; later reports only fill a shop name still empty.
    if (!product.exists) {
      batch.set(productRef, {
        'title': title,
        'shopId': link.shopId,
        'itemId': link.itemId,
        'shopName': ?shopName,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (shopName != null && product.data()?['shopName'] == null) {
      batch.update(productRef, {'shopName': shopName});
    }
    batch.set(
      _paths
          .priceHistoryReports(productKey)
          .doc(
            PriceHistoryIds.userReportId(
              uid,
              productKey,
              report.modelKey,
              report.observedAt,
            ),
          ),
      report.toMap(),
    );
    await awaitWrite(batch.commit());
  });
}
