import 'package:flutter/foundation.dart';

import '../models/wishlist_item.dart';
import '../services/analytics_service.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';

enum ReportStatus { initial, generating, uploading, success, error }

/// ViewModel managing Report Generation and Cloud Storage Upload
class ReportViewModel extends ChangeNotifier {
  final ReportService reportService;
  final StorageService storageService;
  final AppAnalyticsService analyticsService;

  ReportStatus _status = ReportStatus.initial;
  double _uploadProgress = 0.0;
  String? _downloadUrl;
  String? _errorMessage;

  ReportViewModel({
    required this.reportService,
    required this.storageService,
    required this.analyticsService,
  });

  ReportStatus get status => _status;
  double get uploadProgress => _uploadProgress;
  String? get downloadUrl => _downloadUrl;
  String? get errorMessage => _errorMessage;

  /// Generate and upload report to Firebase Cloud Storage under per-user path
  Future<bool> generateAndUploadReport({
    required String userId,
    required String userName,
    required List<WishlistItem> items,
    required int totalSaved,
  }) async {
    _status = ReportStatus.generating;
    _uploadProgress = 0.0;
    _errorMessage = null;
    _downloadUrl = null;
    notifyListeners();

    try {
      // 1. Generate PDF document bytes in memory
      final pdfBytes = await reportService.generateMonthlyReportPdf(
        userName: userName,
        items: items,
        totalSaved: totalSaved,
      );

      _status = ReportStatus.uploading;
      notifyListeners();

      // 2. Upload to Firebase Storage per-user path: reports/{uid}/summary_...
      final fileName = 'summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final url = await storageService.uploadUserReport(
        userId: userId,
        fileName: fileName,
        fileBytes: pdfBytes,
        contentType: 'application/pdf',
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      _downloadUrl = url;
      _status = ReportStatus.success;

      // 3. Log Analytics event per analytics-plan.md
      await analyticsService.logExportReport(
        fileFormat: 'pdf',
        fileSizeKb: (pdfBytes.lengthInBytes / 1024).round(),
        itemCount: items.length,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _status = ReportStatus.error;
      _errorMessage = 'Tải báo cáo lên Cloud Storage thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = ReportStatus.initial;
    _uploadProgress = 0.0;
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }
}
