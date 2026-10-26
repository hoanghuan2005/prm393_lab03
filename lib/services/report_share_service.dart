import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Hands a generated PDF to the system. Reports stay on the device and are shared
/// with the `printing` package — no Cloud Storage on the Spark plan (decision D7).
abstract interface class ReportShareService {
  /// Opens the system share sheet; true when the platform accepted the share
  Future<bool> sharePdf(Uint8List bytes, String fileName);

  /// Opens the system print / preview dialog
  Future<bool> previewPdf(Uint8List bytes);
}

class PrintingReportShareService implements ReportShareService {
  @override
  Future<bool> sharePdf(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);

  @override
  Future<bool> previewPdf(Uint8List bytes) =>
      Printing.layoutPdf(onLayout: (_) async => bytes);
}
