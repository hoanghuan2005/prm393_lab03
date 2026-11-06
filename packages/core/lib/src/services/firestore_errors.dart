import 'package:cloud_firestore/cloud_firestore.dart';

/// A message a person can act on, for any error thrown by a Firestore call.
String describeFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Tài khoản không có quyền thực hiện thao tác này.';
      case 'unavailable':
        return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
      case 'deadline-exceeded':
        return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
      case 'failed-precondition':
        return 'Firestore chưa có chỉ mục cho truy vấn này '
            '(cần deploy firestore.indexes.json).';
      case 'not-found':
        return 'Dữ liệu không còn tồn tại.';
      case 'resource-exhausted':
        return 'Đã vượt hạn mức miễn phí của Firestore hôm nay.';
    }
    return 'Lỗi Firestore (${error.code}).';
  }
  return 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
}

/// The rules refused the write (no permission, or the document changed state)
bool isPermissionDenied(Object error) =>
    error is FirebaseException && error.code == 'permission-denied';

/// dd/MM/yyyy without depending on intl
String formatDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
