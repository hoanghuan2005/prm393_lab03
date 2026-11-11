import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/voucher.dart';
import '../models/voucher_matcher.dart';
import '../models/wishlist_item.dart';

class VoucherService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  List<Voucher> _vouchers = defaultVouchers;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  VoucherService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _initFirestoreListener();
  }

  List<Voucher> get allVouchers => List.unmodifiable(_vouchers);

  static const String sourceFirestore = 'firestore';
  static const String sourceSample = 'mẫu';

  /// Where [allVouchers] comes from, for testers: [sourceFirestore] once the
  /// listener got active vouchers, otherwise [sourceSample] ([defaultVouchers])
  String get source =>
      identical(_vouchers, defaultVouchers) ? sourceSample : sourceFirestore;

  /// Number of vouchers in use
  int get count => _vouchers.length;

  void _initFirestoreListener() {
    try {
      _subscription = _firestore
          .collection('vouchers')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final live = snapshot.docs
                    .map((doc) => Voucher.fromFirestore(doc.data(), doc.id))
                    .where((v) => v.isActive)
                    .toList();
                if (live.isNotEmpty) {
                  _vouchers = live;
                  notifyListeners();
                }
              }
            },
            onError: (e) {
              debugPrint('VoucherService listener fallback to defaults: $e');
            },
          );
    } catch (e) {
      debugPrint('VoucherService init error: $e');
    }
  }

  /// Tìm voucher tốt nhất (tiết kiệm nhiều tiền nhất) phù hợp với sản phẩm
  Voucher? findBestVoucher({
    required WishlistItem item,
    required int priceVnd,
    required DateTime now,
  }) => VoucherMatcher.best(_vouchers, item, priceVnd, now);

  /// Lấy toàn bộ voucher có thể áp dụng cho sản phẩm này
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

  static final List<Voucher> defaultVouchers = [
    const Voucher(
      id: 'vouch_1111_01',
      code: 'SHOPEE1111',
      title: 'Shopee Siêu Sale 11.11 - Giảm 50K cho đơn từ 250K',
      discountAmount: 50000,
      minOrder: 250000,
      validUntil: '2026-11-12',
      affiliateUrl: 'https://shopee.vn/m/11-11-sieu-sale',
      isActive: true,
      category: 'Tất cả',
    ),
    const Voucher(
      id: 'vouch_1111_02',
      code: 'FREESHIP0D',
      title: 'Mã Miễn Phí Vận Chuyển Đơn Từ 0Đ Toàn Sàn',
      discountAmount: 25000,
      minOrder: 0,
      validUntil: '2026-11-12',
      affiliateUrl: 'https://shopee.vn/m/mien-phi-van-chuyen',
      isActive: true,
      category: 'Tất cả',
      type: Voucher.typeFreeship,
    ),
    const Voucher(
      id: 'vouch_1111_03',
      code: 'TECH1111',
      title: 'Voucher Công Nghệ & Điện Tử Giảm 100K đơn 500K',
      discountAmount: 100000,
      minOrder: 500000,
      validUntil: '2026-11-15',
      affiliateUrl: 'https://shopee.vn/m/cong-nghe-giam-soc',
      isActive: true,
      category: 'Công nghệ',
    ),
    const Voucher(
      id: 'vouch_fashion_01',
      code: 'FASHION30K',
      title: 'Voucher Thời Trang Nam Nữ Giảm 30K',
      discountAmount: 30000,
      minOrder: 100000,
      validUntil: '2026-11-20',
      affiliateUrl: 'https://shopee.vn',
      isActive: true,
      category: 'Thời trang',
    ),
    const Voucher(
      id: 'vouch_perseper_01',
      code: 'PERSEPER15K',
      title: 'Voucher Độc Quyền Shop Perseper Giảm 15K',
      discountAmount: 15000,
      minOrder: 50000,
      validUntil: '2026-11-30',
      affiliateUrl: 'https://shopee.vn',
      isActive: true,
      category: 'Thời trang',
      shopName: 'Perseper',
    ),
    const Voucher(
      id: 'vouch_xmmn_01',
      code: 'XMMN20K',
      title: 'Voucher Tri Ân Khách Hàng Shop XMMN Giảm 20K',
      discountAmount: 20000,
      minOrder: 100000,
      validUntil: '2026-11-30',
      affiliateUrl: 'https://shopee.vn',
      isActive: true,
      category: 'Thời trang',
      shopName: 'XMMN',
    ),
  ];
}
