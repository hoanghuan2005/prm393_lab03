import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shopee_voucher.dart';

abstract class ShopeeVoucherService {
  /// Vouchers scraped with the extension, most recently seen first.
  /// Staff and admins may read and delete them (firestore.rules).
  Stream<List<ShopeeVoucher>> watchVouchers();

  Future<void> delete(String id);
}

class FirestoreShopeeVoucherService implements ShopeeVoucherService {
  static const int maxShown = 500;

  final FirebaseFirestore _db;

  FirestoreShopeeVoucherService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vouchers =>
      _db.collection('shopeeVouchers');

  @override
  Stream<List<ShopeeVoucher>> watchVouchers() => _vouchers
      .orderBy('lastSeenAt', descending: true)
      .limit(maxShown)
      .snapshots()
      .map((s) => s.docs.map(ShopeeVoucher.fromFirestore).toList());

  @override
  Future<void> delete(String id) => _vouchers.doc(id).delete();
}
