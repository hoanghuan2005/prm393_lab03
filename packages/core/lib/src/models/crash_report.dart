import 'firestore_fields.dart';

/// How bad a report is. `fatal` = the app was about to die or an uncaught async
/// error; `error` = a Flutter framework error; `warning` = a handled error.
enum CrashSeverity {
  fatal('fatal', 'Crash'),
  error('error', 'Lỗi'),
  warning('warning', 'Cảnh báo');

  final String key;
  final String label;

  const CrashSeverity(this.key, this.label);

  static CrashSeverity fromKey(Object? key) => CrashSeverity.values.firstWhere(
    (s) => s.key == key,
    orElse: () => CrashSeverity.error,
  );
}

/// One report in `crashes/{id}`, written by the mobile app when it catches an
/// uncaught error (or from the Crashlytics demo buttons) and read on the web
/// admin so the team does not have to open the Firebase Console.
class CrashReport {
  final String id;
  final String feature;
  final String errorCode;
  final String errorMessage;
  final String stackTrace;
  final CrashSeverity severity;

  /// Firebase uid of the user who hit the error (never an email)
  final String userId;
  final String platform;
  final String appVersion;
  final bool isResolved;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const CrashReport({
    required this.id,
    required this.feature,
    required this.errorCode,
    required this.errorMessage,
    this.stackTrace = '',
    this.severity = CrashSeverity.error,
    this.userId = '',
    this.platform = '',
    this.appVersion = '',
    this.isResolved = false,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory CrashReport.fromFirestore(dynamic doc) {
    final data = docData(doc);
    return CrashReport(
      id: doc.id as String,
      feature: readText(data['feature']) ?? 'Không rõ',
      errorCode: readText(data['errorCode']) ?? 'UNKNOWN',
      errorMessage: readText(data['errorMessage']) ?? '',
      stackTrace: readString(data['stackTrace']) ?? '',
      severity: CrashSeverity.fromKey(data['severity']),
      userId: readText(data['userId']) ?? '',
      platform: readText(data['platform']) ?? '',
      appVersion: readText(data['appVersion']) ?? '',
      isResolved: data['isResolved'] == true,
      createdAt: readDate(data['createdAt']),
      resolvedAt: readDate(data['resolvedAt']),
      resolvedBy: readText(data['resolvedBy']),
    );
  }
}
