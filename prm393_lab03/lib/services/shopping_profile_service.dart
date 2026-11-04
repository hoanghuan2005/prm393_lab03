import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/owned_item.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// Shopping profile (spec 7.2, A-12): users/{uid}/ownedItems and the style / brand
/// tags on users/{uid}. Everything is optional and typed by the user.
abstract interface class ShoppingProfileService {
  /// Newest first
  Stream<List<OwnedItem>> watchOwnedItems(String uid);

  /// An empty [OwnedItem.id] creates a new document
  Future<void> saveOwnedItem(String uid, OwnedItem item);

  Future<void> deleteOwnedItem(String uid, String id);

  Stream<ShoppingTags> watchTags(String uid);

  Future<void> saveTags(String uid, ShoppingTags tags);
}

class FirestoreShoppingProfileService implements ShoppingProfileService {
  final FirestorePaths _paths;

  FirestoreShoppingProfileService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<List<OwnedItem>> watchOwnedItems(String uid) => guardStream(
    _paths
        .ownedItems(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(OwnedItem.fromFirestore).toList()),
  );

  @override
  Future<void> saveOwnedItem(String uid, OwnedItem item) => guard(() {
    final name = item.name.trim();
    if (name.isEmpty || name.length > OwnedItem.nameMaxLength) {
      throw const AppException(
        'invalid-owned-item',
        'Tên đồ đang dùng cần từ 1 đến 60 ký tự.',
      );
    }
    final note = item.note?.trim();
    if (note != null && note.length > OwnedItem.noteMaxLength) {
      throw const AppException(
        'invalid-owned-item',
        'Ghi chú tối đa 100 ký tự.',
      );
    }
    final ref = _paths.ownedItems(uid).doc(item.id.isEmpty ? null : item.id);
    return awaitWrite(
      ref.set({
        ...item.toMap(),
        'name': name,
        'note': note == null || note.isEmpty ? null : note,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  });

  @override
  Future<void> deleteOwnedItem(String uid, String id) =>
      guard(() => awaitWrite(_paths.ownedItems(uid).doc(id).delete()));

  @override
  Stream<ShoppingTags> watchTags(String uid) => guardStream(
    _paths
        .user(uid)
        .snapshots()
        .map((s) => ShoppingTags.fromMap(s.data() ?? const {})),
  );

  @override
  Future<void> saveTags(String uid, ShoppingTags tags) => guard(
    () =>
        awaitWrite(_paths.user(uid).set(tags.toMap(), SetOptions(merge: true))),
  );
}
