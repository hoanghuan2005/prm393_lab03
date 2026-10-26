import 'package:flutter/foundation.dart';

import '../core/utils/month_key.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../services/analytics_service.dart';
import '../services/report_service.dart';
import '../services/report_share_service.dart';
import 'deferred_notify.dart';

enum ReportStatus { idle, generating, ready, shared, error }

/// Monthly PDF report: generated on the device and shared through the system share sheet
/// (decision D7: no Cloud Storage). uid, user name and data come from the ProxyProvider.
class ReportViewModel extends ChangeNotifier with DeferredNotify {
  final ReportService reportService;
  final ReportShareService shareService;
  final AppAnalyticsService analyticsService;

  ReportStatus _status = ReportStatus.idle;
  String? _errorMessage;
  String? _uid;
  String _userName = '';
  List<PurchaseItem> _purchases = const [];
  List<WishlistItem> _wishlistItems = const [];

  /// Last generated PDF; reused by "Thử lại" / "Xem trước" until the data changes
  Uint8List? _bytes;
  DateTime? _bytesMonth;
  int _itemCount = 0;

  ReportViewModel({
    required this.reportService,
    required this.shareService,
    required this.analyticsService,
  });

  ReportStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _status == ReportStatus.generating;

  /// Called by the provider whenever the signed-in user changes; clears the last report
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _clear();
    notifyLater();
  }

  /// Data from AuthViewModel / PurchaseViewModel / WishlistViewModel
  void updateSources({
    required String userName,
    required List<PurchaseItem> purchases,
    required List<WishlistItem> wishlistItems,
  }) {
    // Getters return fresh list copies, so compare contents (models implement ==)
    final changed =
        !listEquals(purchases, _purchases) ||
        !listEquals(wishlistItems, _wishlistItems);
    _userName = userName;
    _purchases = purchases;
    _wishlistItems = wishlistItems;
    if (changed && _status != ReportStatus.generating) {
      _bytes = null;
      _bytesMonth = null;
    }
  }

  void _clear() {
    _status = ReportStatus.idle;
    _errorMessage = null;
    _bytes = null;
    _bytesMonth = null;
  }

  static String fileNameFor(DateTime month) =>
      'why-i-buy_${monthKey(month)}.pdf';

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Builds the PDF for [month] unless the same one is already in memory
  Future<Uint8List?> _ensurePdf(DateTime month) async {
    final cached = _bytes;
    if (cached != null &&
        _bytesMonth != null &&
        _sameMonth(_bytesMonth!, month)) {
      return cached;
    }
    _status = ReportStatus.generating;
    _errorMessage = null;
    notifyListeners();
    try {
      final purchases = _purchases
          .where((p) => _sameMonth(p.occurredAt, month))
          .toList();
      final decided = _wishlistItems
          .where((i) => i.decidedAt != null && _sameMonth(i.decidedAt!, month))
          .toList();
      final bytes = await reportService.generateMonthlyReportPdf(
        userName: _userName,
        month: month,
        purchases: purchases,
        decidedItems: decided,
      );
      _bytes = bytes;
      _bytesMonth = month;
      _itemCount = purchases.length + decided.length;
      _status = ReportStatus.ready;
      notifyListeners();
      return bytes;
    } catch (e) {
      debugPrint('Report generate error: $e');
      _fail('Chưa tạo được báo cáo PDF. Bấm "Thử lại".');
      return null;
    }
  }

  /// Generates (or reuses) the PDF for [month] and opens the share sheet
  Future<bool> generateAndShare(DateTime month) async {
    if (_uid == null || isBusy) return false;
    final bytes = await _ensurePdf(month);
    if (bytes == null) return false;
    try {
      final shared = await shareService.sharePdf(bytes, fileNameFor(month));
      if (!shared) {
        _fail('Chưa chia sẻ được báo cáo. Bấm "Thử lại".');
        return false;
      }
      _status = ReportStatus.shared;
      notifyListeners();
      await analyticsService.logExportReport(
        fileFormat: 'pdf',
        itemCount: _itemCount,
      );
      return true;
    } catch (e) {
      debugPrint('Report share error: $e');
      _fail('Chưa chia sẻ được báo cáo. Bấm "Thử lại".');
      return false;
    }
  }

  /// Opens the print / preview dialog for [month]
  Future<void> preview(DateTime month) async {
    if (_uid == null || isBusy) return;
    final bytes = await _ensurePdf(month);
    if (bytes == null) return;
    try {
      await shareService.previewPdf(bytes);
    } catch (e) {
      debugPrint('Report preview error: $e');
      _fail('Chưa mở được bản xem trước. Bấm "Thử lại".');
    }
  }

  void _fail(String message) {
    _status = ReportStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _clear();
    notifyListeners();
  }
}
