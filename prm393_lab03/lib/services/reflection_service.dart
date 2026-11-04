import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reflection.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}/reflections/{yyyy-MM}
abstract interface class ReflectionService {
  /// null while the month has no reflection yet
  Stream<Reflection?> watch(String uid, String monthKey);

  Future<void> save(String uid, Reflection reflection);
}

class FirestoreReflectionService implements ReflectionService {
  final FirestorePaths _paths;

  FirestoreReflectionService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<Reflection?> watch(String uid, String monthKey) => guardStream(
    _paths
        .reflection(uid, monthKey)
        .snapshots()
        .map((doc) => doc.exists ? Reflection.fromFirestore(doc) : null),
  );

  @override
  Future<void> save(String uid, Reflection reflection) => guard(
    () => awaitWrite(
      _paths.reflection(uid, reflection.month).set({
        ...reflection.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ),
  );
}
