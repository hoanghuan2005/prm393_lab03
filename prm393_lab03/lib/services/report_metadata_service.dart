import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';
import 'service_guard.dart';

/// One generated PDF report. The file itself stays on the device (decision D7:
/// no Cloud Storage); Firestore keeps only these figures (Final 4).
class ReportRecord {
  /// `yyyy-MM`
  final String month;

  /// Purchases plus decided wishlist items in the report
  final int itemCount;

  /// File size, rounded up to whole kB
  final int sizeKb;

  /// The system share sheet accepted the file
  final bool shared;

  const ReportRecord({
    required this.month,
    required this.itemCount,
    required this.sizeKb,
    required this.shared,
  });

  static int kbOf(int bytes) => (bytes + 1023) ~/ 1024;
}

/// users/{uid}/reports/{id}: written once per share, never edited
abstract interface class ReportMetadataService {
  Future<void> record(String uid, ReportRecord report);
}

class FirestoreReportMetadataService implements ReportMetadataService {
  final FirestorePaths _paths;

  FirestoreReportMetadataService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<void> record(String uid, ReportRecord report) => guard(
    () => awaitWrite(
      _paths.reports(uid).add({
        'month': report.month,
        'itemCount': report.itemCount,
        'sizeKb': report.sizeKb,
        'shared': report.shared,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    ),
  );
}
