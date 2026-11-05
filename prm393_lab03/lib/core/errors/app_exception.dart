/// App-level error with a stable [code] (for logs/analytics) and a message safe to show users
class AppException implements Exception {
  final String code;
  final String messageVi;

  /// Original error this was mapped from; set for unknown or unmapped errors
  final Object? cause;

  const AppException(this.code, this.messageVi, {this.cause});

  static const unknown = AppException(
    'unknown',
    'Đã có lỗi, vui lòng thử lại.',
  );

  @override
  String toString() =>
      'AppException($code): $messageVi${cause == null ? '' : ' <- $cause'}';
}
