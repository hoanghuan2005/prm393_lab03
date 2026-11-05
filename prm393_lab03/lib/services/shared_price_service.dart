import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/price_snapshot.dart';
import '../models/shared_price.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// sharedPrices/{productKey}/reports/{reportId}: one anonymous price per person, product
/// and variant (spec 8.3). Documents carry no uid; the id is a hash checked by the rules.
abstract interface class SharedPriceService {
  /// Reports for one variant (`modelKey`), keyed by document id
  Future<Map<String, SharedPriceReport>> reportsFor(
    String productKey,
    String modelKey,
  );

  /// Creates or replaces this person's report for the variant
  Future<void> contribute({
    required String uid,
    required String productKey,
    required String modelKey,
    required PriceSnapshot snapshot,
  });

  /// Removes this person's report for the variant
  Future<void> withdraw({
    required String uid,
    required String productKey,
    required String modelKey,
  });
}

class FirestoreSharedPriceService implements SharedPriceService {
  final FirestorePaths _paths;

  FirestoreSharedPriceService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  /// One report per person per variant, so this is already a large crowd
  static const int maxReports = 200;

  @override
  Future<Map<String, SharedPriceReport>> reportsFor(
    String productKey,
    String modelKey,
  ) => guard(() async {
    // Equality only: works with the automatic index; dates are filtered on the device
    final snapshot = await _paths
        .sharedPriceReports(productKey)
        .where('modelKey', isEqualTo: modelKey)
        .limit(maxReports)
        .get();
    return {for (final doc in snapshot.docs) doc.id: ?_read(doc.data())};
  });

  static SharedPriceReport? _read(JsonMap data) {
    final amount = data['amountVnd'];
    final at = data['observedAt'];
    if (amount is! int || at is! Timestamp) return null;
    return SharedPriceReport(
      amountVnd: amount,
      priceType: PriceType.fromKey(data['priceType'] as String?),
      observedAt: at.toDate(),
    );
  }

  @override
  Future<void> contribute({
    required String uid,
    required String productKey,
    required String modelKey,
    required PriceSnapshot snapshot,
  }) => guard(
    () => _paths
        .sharedPriceReports(productKey)
        .doc(SharedPriceSummary.reportId(uid, productKey, modelKey))
        .set({
          'modelKey': modelKey,
          'priceType': snapshot.priceType.key,
          'amountVnd': snapshot.amountVnd,
          'observedAt': Timestamp.fromDate(snapshot.observedAt),
          'source': snapshot.source.key,
        }),
  );

  @override
  Future<void> withdraw({
    required String uid,
    required String productKey,
    required String modelKey,
  }) => guard(
    () => _paths
        .sharedPriceReports(productKey)
        .doc(SharedPriceSummary.reportId(uid, productKey, modelKey))
        .delete(),
  );
}
