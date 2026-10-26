import 'package:flutter/foundation.dart';

// TODO(B10): firebase_storage đã bị gỡ khỏi pubspec (nhóm không dùng Cloud
// Storage). Lớp này chỉ còn là stub để ReportViewModel/main.dart vẫn biên dịch;
// B10 sẽ xoá hẳn StorageService và chuyển chia sẻ PDF sang package `printing`.

/// Upload progress callback: progress (0.0 to 1.0)
typedef ProgressCallback = void Function(double progress);

/// Service abstraction for Firebase Cloud Storage
class StorageService {
  StorageService();

  /// Upload a generated file (e.g. PDF report) to per-user path: reports/{userId}/{fileName}
  Future<String> uploadUserReport({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    // TODO(B10): bản cũ dùng FirebaseStorage.ref().putData(...) — đã tạm tắt.
    throw UnsupportedError('Cloud Storage không còn được dùng (xem B10).');
  }
}
