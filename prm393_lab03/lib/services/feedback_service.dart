import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// "Gửi góp ý" (Cá nhân → Hỗ trợ & thông tin): users/{uid}/feedback, create only
abstract interface class FeedbackService {
  Future<void> send(String uid, String message);
}

class FirestoreFeedbackService implements FeedbackService {
  static const int maxLength = 1000;

  final FirestorePaths _paths;

  FirestoreFeedbackService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<void> send(String uid, String message) => guard(() async {
    final text = message.trim();
    if (text.isEmpty || text.length > maxLength) {
      throw ArgumentError.value(message, 'message');
    }
    // Saved on this device at once and synced later when offline (E04)
    await awaitWrite(
      _paths.feedback(uid).add({
        'message': text,
        'appVersion': AppConstants.appVersion,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  });
}
