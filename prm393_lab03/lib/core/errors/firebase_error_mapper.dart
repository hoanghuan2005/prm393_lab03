import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

const _network = AppException(
  'network',
  'Không có kết nối mạng. Kiểm tra mạng rồi thử lại.',
);

/// The user closed or cancelled a sign-in flow; shared by every sign-in method
const signInCancelled = AppException(
  'sign-in-cancelled',
  'Bạn đã huỷ đăng nhập. Chọn lại cách đăng nhập khi sẵn sàng.',
);

/// Firebase code kept in AppException.code
const accountExistsCode = 'account-exists-with-different-credential';

/// The email already has an account with another sign-in method. The app cannot know
/// which one (Firebase hides it), so the message names none.
const accountExistsOtherMethod = AppException(
  accountExistsCode,
  'Email này đã có tài khoản với cách đăng nhập khác. Đăng nhập bằng cách bạn đã dùng trước đó (Google, GitHub hoặc email), rồi vào Cá nhân → Tài khoản liên kết để thêm cách mới.',
);

/// Converts errors from Firebase Auth, Firestore and Firebase AI Logic into [AppException]
AppException mapFirebaseError(Object e) {
  if (e is AppException) return e;
  if (e is FirebaseAuthException) return _mapAuth(e);
  if (e is FirebaseException) return _mapFirebase(e);
  if (e is FirebaseAIException) return _mapAi(e);
  if (_looksLikeNetwork(e.toString())) return _network;
  return AppException(
    AppException.unknown.code,
    AppException.unknown.messageVi,
    cause: e,
  );
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
    case 'web-context-cancelled':
    case 'sign-in-cancelled':
    case 'canceled':
      return signInCancelled;
    case 'popup-blocked':
      return const AppException(
        'popup-blocked',
        'Trình duyệt đã chặn cửa sổ đăng nhập. Cho phép cửa sổ bật lên rồi bấm "Thử lại".',
      );
    case accountExistsCode:
      return accountExistsOtherMethod;
    case 'credential-already-in-use':
      return const AppException(
        'credential-already-in-use',
        'Tài khoản này đã có dữ liệu Why I Buy riêng nên không liên kết được. Đăng nhập bằng tài khoản đó, xoá dữ liệu hoặc tài khoản, rồi thử lại.',
      );
    case 'provider-already-linked':
      return const AppException(
        'provider-already-linked',
        'Cách đăng nhập này đã được liên kết.',
      );
    case 'email-already-in-use':
      return const AppException(
        'email-already-in-use',
        'Email của tài khoản này đang thuộc một tài khoản Why I Buy khác.',
      );
    case 'requires-recent-login':
      return const AppException(
        'requires-recent-login',
        'Vui lòng đăng xuất và đăng nhập lại rồi thử liên kết.',
      );
    case 'no-such-provider':
      return const AppException(
        'no-such-provider',
        'Cách đăng nhập này chưa được liên kết.',
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
        cause: e,
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
        cause: e,
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
