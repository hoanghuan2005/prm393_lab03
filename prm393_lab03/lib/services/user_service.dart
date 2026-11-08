import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_fields.dart';
import '../models/user_profile.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}: profile and settings
abstract interface class UserService {
  /// Creates users/{uid} on first sign-in; later calls only refresh name/anonymous flag
  Future<void> ensureUserDocument(
    String uid, {
    String? displayName,
    String? email,
    required bool isAnonymous,
  });

  /// Emits default settings while the document does not exist yet
  Stream<UserSettings> watchSettings(String uid);

  Future<void> updateSettings(String uid, UserSettings settings);

  /// users/{uid}.role: 'user' (also when missing), 'staff' or 'admin'
  Stream<String> watchRole(String uid);
}

class FirestoreUserService implements UserService {
  final FirestorePaths _paths;

  FirestoreUserService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<void> ensureUserDocument(
    String uid, {
    String? displayName,
    String? email,
    required bool isAnonymous,
  }) => guard(() async {
    final ref = _paths.user(uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.update({
        'displayName': displayName,
        'email': email,
        'isAnonymous': isAnonymous,
      });
      return;
    }
    await ref.set({
      ...UserProfile(
        uid: uid,
        displayName: displayName,
        isAnonymous: isAnonymous,
      ).toMap(),
      'email': email,
      // Every account starts as a plain user; only an admin changes it (firestore.rules)
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Stream<UserSettings> watchSettings(String uid) => guardStream(
    _paths
        .user(uid)
        .snapshots()
        .map((doc) => UserProfile.fromFirestore(doc).settings),
  );

  @override
  Stream<String> watchRole(String uid) => guardStream(
    _paths
        .user(uid)
        .snapshots()
        .map((doc) => readString(doc.data()?['role']) ?? 'user'),
  );

  @override
  Future<void> updateSettings(String uid, UserSettings settings) => guard(
    () => awaitWrite(
      _paths.user(uid).set({
        'settings': settings.toMap(),
      }, SetOptions(merge: true)),
    ),
  );
}
