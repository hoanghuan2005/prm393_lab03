import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Upload progress callback: progress (0.0 to 1.0)
typedef ProgressCallback = void Function(double progress);

/// Service abstraction for Firebase Cloud Storage
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a generated file (e.g. PDF report) to per-user path: reports/{userId}/{fileName}
  Future<String> uploadUserReport({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('UserId cannot be empty for secure per-user storage');
    }

    // Path matches storage.rules: match /reports/{userId}/{allPaths=**}
    final path = 'reports/$userId/$fileName';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
      },
    );

    final uploadTask = ref.putData(fileBytes, metadata);

    // Listen to progress events
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
    }

    final completedSnapshot = await uploadTask;
    final downloadUrl = await completedSnapshot.ref.getDownloadURL();
    debugPrint('Upload successful to $path. Download URL: $downloadUrl');
    return downloadUrl;
  }

  /// List user uploaded reports
  Future<List<Reference>> listUserReports(String userId) async {
    final listResult = await _storage.ref().child('reports/$userId').listAll();
    return listResult.items;
  }
}
