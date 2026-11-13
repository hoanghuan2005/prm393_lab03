import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/crash_report.dart';
import 'shared_paths.dart';

/// Crash reports the mobile app writes (`crashes`); staff read them live and
/// mark them resolved. Reports are never edited or deleted.
abstract class CrashReportService {
  /// Newest first, at most [limit]
  Stream<List<CrashReport>> watchRecent({int limit = 200});

  /// Mark resolved (true) or open again (false)
  Future<void> setResolved(String id, bool resolved, {required String byUid});
}

class FirestoreCrashReportService implements CrashReportService {
  final SharedPaths _paths;

  FirestoreCrashReportService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<CrashReport>> watchRecent({int limit = 200}) => _paths
      .crashes()
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(CrashReport.fromFirestore).toList());

  @override
  Future<void> setResolved(
    String id,
    bool resolved, {
    required String byUid,
  }) => _paths.crash(id).update({
    'isResolved': resolved,
    'resolvedAt': FieldValue.serverTimestamp(),
    'resolvedBy': byUid,
  });
}
