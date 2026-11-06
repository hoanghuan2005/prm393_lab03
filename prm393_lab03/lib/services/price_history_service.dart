import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_fields.dart';
import '../models/price_history.dart';
import '../models/sale_event.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// "Biểu đồ giá tham khảo": read-only access to priceHistory, productGroups and the
/// published sale calendar. Every signed-in user may read them (firestore.rules).
abstract interface class PriceHistoryService {
  /// Emits null while the product does not exist
  Stream<PriceHistoryProduct?> watchProduct(String productKey);

  /// Reports observed at or after [from], oldest first
  Future<List<PriceHistoryReport>> fetchReports(
    String productKey,
    DateTime from,
  );

  /// The group with its productKeys; null when it does not exist
  Future<ProductGroup?> fetchGroup(String groupId);

  /// Published sale days between [from] and [to], both included
  Future<List<SaleEvent>> fetchSaleEvents(DateTime from, DateTime to);
}

class FirestorePriceHistoryService implements PriceHistoryService {
  final FirestorePaths _paths;

  FirestorePriceHistoryService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  /// 90 days × up to 6 reports a day, with room to spare
  static const int maxReports = 1000;

  @override
  Stream<PriceHistoryProduct?> watchProduct(String productKey) => guardStream(
    _paths
        .priceHistoryProduct(productKey)
        .snapshots()
        .map(
          (doc) => doc.exists ? PriceHistoryProduct.fromFirestore(doc) : null,
        ),
  );

  @override
  Future<List<PriceHistoryReport>> fetchReports(
    String productKey,
    DateTime from,
  ) => guard(() async {
    // One range on one field: works with the automatic index
    final snapshot = await _paths
        .priceHistoryReports(productKey)
        .where('observedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('observedAt')
        .limit(maxReports)
        .get();
    return snapshot.docs.map(PriceHistoryReport.fromFirestore).toList();
  });

  @override
  Future<ProductGroup?> fetchGroup(String groupId) => guard(() async {
    final doc = await _paths.productGroup(groupId).get();
    return doc.exists ? ProductGroup.fromFirestore(doc) : null;
  });

  @override
  Future<List<SaleEvent>> fetchSaleEvents(DateTime from, DateTime to) => guard(
    () async {
      // The rules only allow listing published events. Filtering the dates here
      // avoids a composite index (status + date).
      final snapshot = await _paths
          .saleEvents()
          .where('status', isEqualTo: 'published')
          .get();
      final events = [
        for (final doc in snapshot.docs)
          if (readDate(doc.data()['date']) case final date?
              when !date.isBefore(from) && !date.isAfter(to))
            SaleEvent(
              id: doc.id,
              name: readText(doc.data()['name']) ?? 'Đợt sale',
              date: date,
              type: SaleType.fromKey(doc.data()['type']),
              confirmed: doc.data()['confirmed'] == true,
            ),
      ]..sort((a, b) => a.date.compareTo(b.date));
      return events;
    },
  );
}
