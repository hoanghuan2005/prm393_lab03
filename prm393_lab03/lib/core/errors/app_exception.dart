/// App-level error with a stable [code] (for logs/analytics) and a message safe to show users
class AppException implements Exception {
  final String code;
  final String messageVi;

  const AppException(this.code, this.messageVi);

  static const unknown = AppException(
    'unknown',
    'Đã có lỗi, vui lòng thử lại.',
  );

  @override
  String toString() => 'AppException($code): $messageVi';
}
