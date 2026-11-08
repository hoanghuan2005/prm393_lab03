import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}/hiddenMatches/{productKey}: listings the user marked "Không phải món
/// này" in "Cùng món ở shop khác" (G8). Only the owner reads and writes them.
abstract interface class HiddenMatchService {
  Future<Set<String>> hiddenKeys(String uid);

  Future<void> hide(String uid, String productKey);

  /// "Hoàn tác"
  Future<void> unhide(String uid, String productKey);
}

class FirestoreHiddenMatchService implements HiddenMatchService {
  final FirestorePaths _paths;

  FirestoreHiddenMatchService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Future<Set<String>> hiddenKeys(String uid) => guard(() async {
    final snapshot = await _paths.hiddenMatches(uid).get();
    return {for (final doc in snapshot.docs) doc.id};
  });

  @override
  Future<void> hide(String uid, String productKey) => guard(
    () => awaitWrite(
      _paths.hiddenMatches(uid).doc(productKey).set({
        'hiddenAt': FieldValue.serverTimestamp(),
      }),
    ),
  );

  @override
  Future<void> unhide(String uid, String productKey) => guard(
    () => awaitWrite(_paths.hiddenMatches(uid).doc(productKey).delete()),
  );
}
