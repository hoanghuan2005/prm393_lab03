import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/voucher.dart';

class VoucherService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  List<Voucher> _vouchers = defaultVouchers;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  VoucherService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _initFirestoreListener();
  }

  List<Voucher> get allVouchers => List.unmodifiable(_vouchers);

  void _initFirestoreListener() {
    try {
      _subscription = _firestore
          .collection('vouchers')
          .snapshots()
          .listen((snapshot) {
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
      }, onError: (e) {
        debugPrint('VoucherService listener fallback to defaults: $e');
      });
    } catch (e) {
      debugPrint('VoucherService init error: $e');
    }
  }

  /// Tìm voucher tốt nhất (tiết kiệm nhiều tiền nhất) phù hợp với sản phẩm
  Voucher? findBestVoucher({required int priceVnd, String? platform}) {
    final valid = _vouchers.where((v) => v.canApplyTo(priceVnd: priceVnd, itemPlatform: platform)).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => b.discountAmount.compareTo(a.discountAmount));
    return valid.first;
  }

  /// Lấy toàn bộ voucher có thể áp dụng cho sản phẩm này
  List<Voucher> getApplicableVouchers({required int priceVnd, String? platform}) {
    return _vouchers
        .where((v) => v.canApplyTo(priceVnd: priceVnd, itemPlatform: platform))
        .toList();
  }

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
      platform: 'Shopee',
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
      platform: 'Shopee',
      discountAmount: 25000,
      minOrder: 0,
      validUntil: '2026-11-12',
      affiliateUrl: 'https://shopee.vn/m/mien-phi-van-chuyen',
      isActive: true,
      category: 'Tất cả',
    ),
    const Voucher(
      id: 'vouch_1111_03',
      code: 'TECH1111',
      title: 'Voucher Công Nghệ & Điện Tử Giảm 100K đơn 500K',
      platform: 'Shopee',
      discountAmount: 100000,
      minOrder: 500000,
      validUntil: '2026-11-15',
      affiliateUrl: 'https://shopee.vn/m/cong-nghe-giam-soc',
      isActive: true,
      category: 'Công nghệ',
    ),
    const Voucher(
      id: 'vouch_laz_01',
      code: 'LAZADA1111',
      title: 'Lazada 11.11 Triệu Deal - Giảm 40K đơn 200K',
      platform: 'Lazada',
      discountAmount: 40000,
      minOrder: 200000,
      validUntil: '2026-11-13',
      affiliateUrl: 'https://www.lazada.vn',
      isActive: true,
      category: 'Tất cả',
    ),
    const Voucher(
      id: 'vouch_fashion_01',
      code: 'FASHION30K',
      title: 'Voucher Thời Trang Nam Nữ Giảm 30K',
      platform: 'Shopee',
      discountAmount: 30000,
      minOrder: 100000,
      validUntil: '2026-11-20',
      affiliateUrl: 'https://shopee.vn',
      isActive: true,
      category: 'Thời trang',
    ),
  ];
}
