import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

const _network = AppException(
  'network',
  'Không có kết nối mạng. Kiểm tra mạng rồi bấm "Thử lại".',
);

/// Converts errors from Firebase Auth, Firestore and Firebase AI Logic into [AppException]
AppException mapFirebaseError(Object e) {
  if (e is AppException) return e;
  if (e is FirebaseAuthException) return _mapAuth(e);
  if (e is FirebaseException) return _mapFirebase(e);
  if (e is FirebaseAIException) return _mapAi(e);
  if (_looksLikeNetwork(e.toString())) return _network;
  return AppException.unknown;
}

AppException _mapAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return _network;
    case 'user-disabled':
      return const AppException(
        'user-disabled',
        'Tài khoản này đã bị vô hiệu hoá. Liên hệ nhóm phát triển để được hỗ trợ.',
      );
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
    case 'web-context-canceled':
    case 'sign-in-cancelled':
    case 'canceled':
      return const AppException(
        'sign-in-cancelled',
        'Bạn đã huỷ đăng nhập. Bấm "Thử lại" khi sẵn sàng.',
      );
    case 'popup-blocked':
      return const AppException(
        'popup-blocked',
        'Trình duyệt đã chặn cửa sổ đăng nhập. Cho phép cửa sổ bật lên rồi bấm "Thử lại".',
      );
    case 'too-many-requests':
      return const AppException(
        'too-many-requests',
        'Có quá nhiều lần thử. Chờ một lát rồi bấm "Thử lại".',
      );
    default:
      return AppException(
        e.code,
        'Không đăng nhập được. Bấm "Thử lại" sau ít phút.',
      );
  }
}

AppException _mapFirebase(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return const AppException(
        'permission-denied',
        'Bạn không có quyền truy cập dữ liệu này. Thử đăng xuất rồi đăng nhập lại.',
      );
    case 'unavailable':
      return const AppException(
        'unavailable',
        'Máy chủ tạm thời không phản hồi. Kiểm tra mạng rồi bấm "Thử lại".',
      );
    case 'failed-precondition':
      return const AppException(
        'failed-precondition',
        'Chưa thể tải dữ liệu lúc này. Bấm "Thử lại" sau ít phút.',
      );
    case 'not-found':
      return const AppException(
        'not-found',
        'Không tìm thấy dữ liệu. Có thể mục này đã bị xoá.',
      );
    default:
      if (_looksLikeNetwork('${e.code} ${e.message}')) return _network;
      return AppException(
        e.code,
        'Đã có lỗi xảy ra. Bấm "Thử lại" sau ít phút.',
      );
  }
}

AppException _mapAi(FirebaseAIException e) {
  if (e is QuotaExceeded) {
    return const AppException(
      'ai-quota-exceeded',
      'Phần nhận xét AI đã hết lượt dùng hôm nay. Bấm "Thử lại" vào lúc khác.',
    );
  }
  final message = e.message.toLowerCase();
  if (message.contains('blocked')) {
    return const AppException(
      'ai-blocked',
      'AI không viết được nhận xét cho nội dung này. App hiển thị câu mẫu thay thế.',
    );
  }
  if (_looksLikeNetwork(message)) return _network;
  return const AppException(
    'ai-unavailable',
    'Chưa tạo được nhận xét AI lúc này. Bấm "Thử lại" sau ít phút.',
  );
}

bool _looksLikeNetwork(String text) {
  final t = text.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('failed host lookup') ||
      t.contains('network') ||
      t.contains('connection');
}
