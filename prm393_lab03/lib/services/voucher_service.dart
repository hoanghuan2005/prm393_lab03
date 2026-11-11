import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/voucher.dart';
import '../models/voucher_matcher.dart';
import '../models/wishlist_item.dart';

/// Vouchers the team entered on the web admin (`vouchers`, decision D-3: real
/// data only). There is no built-in sample list: until Firestore answers, and
/// when the collection is empty, the app suggests no voucher.
class VoucherService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  List<Voucher> _vouchers = const [];
  bool _loaded = false;
  bool _isStale = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  VoucherService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _initFirestoreListener();
  }

  /// Active vouchers from Firestore (archived ones are left out)
  List<Voucher> get allVouchers => List.unmodifiable(_vouchers);

  static const String sourceLoading = 'đang tải';
  static const String sourceFirestore = 'firestore';

  /// For testers (dev screen): [sourceLoading] until the first answer, then
  /// [sourceFirestore]
  String get source => _loaded ? sourceFirestore : sourceLoading;

  /// The listener failed after data arrived: [allVouchers] is the last list
  /// received (kept so the app still works offline), not live
  bool get isStale => _isStale;

  /// Number of vouchers in use
  int get count => _vouchers.length;

  void _initFirestoreListener() {
    try {
      _subscription = _firestore
          .collection('vouchers')
          .snapshots()
          .listen(
            (snapshot) {
              // An empty collection empties the list: archived or deleted
              // vouchers must disappear from the app
              _vouchers = snapshot.docs
                  .map((doc) => Voucher.fromFirestore(doc.data(), doc.id))
                  .where((v) => v.isActive)
                  .toList();
              _loaded = true;
              _isStale = false;
              notifyListeners();
            },
            onError: (Object e) {
              debugPrint('VoucherService listener error: $e');
              _isStale = true;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('VoucherService init error: $e');
    }
  }

  /// Best discount voucher for this item and list price (shop vouchers first,
  /// then the biggest discount)
  Voucher? findBestVoucher({
    required WishlistItem item,
    required int priceVnd,
    required DateTime now,
  }) => VoucherMatcher.best(_vouchers, item, priceVnd, now);

  /// Every discount voucher that applies to this item and list price
  List<Voucher> getApplicableVouchers({
    required WishlistItem item,
    required int priceVnd,
    required DateTime now,
  }) => VoucherMatcher.applicable(_vouchers, item, priceVnd, now);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
