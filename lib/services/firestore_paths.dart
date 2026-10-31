import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, dynamic>;

/// The only place that spells out Firestore paths. Every document lives under users/{uid}.
class FirestorePaths {
  final FirebaseFirestore db;

  const FirestorePaths(this.db);

  CollectionReference<JsonMap> users() => db.collection('users');
  DocumentReference<JsonMap> user(String uid) => users().doc(uid);

  CollectionReference<JsonMap> purchases(String uid) =>
      user(uid).collection('purchases');
  DocumentReference<JsonMap> purchase(String uid, String purchaseId) =>
      purchases(uid).doc(purchaseId);

  CollectionReference<JsonMap> wishlistItems(String uid) =>
      user(uid).collection('wishlistItems');
  DocumentReference<JsonMap> wishlistItem(String uid, String itemId) =>
      wishlistItems(uid).doc(itemId);

  CollectionReference<JsonMap> priceSnapshots(String uid, String itemId) =>
      wishlistItem(uid, itemId).collection('priceSnapshots');

  CollectionReference<JsonMap> decisions(String uid) =>
      user(uid).collection('decisions');

  CollectionReference<JsonMap> budgetGroups(String uid) =>
      user(uid).collection('budgetGroups');
  DocumentReference<JsonMap> budgetGroup(String uid, String groupId) =>
      budgetGroups(uid).doc(groupId);

  /// Document id = month key "yyyy-MM"
  CollectionReference<JsonMap> budgets(String uid) =>
      user(uid).collection('budgets');
  DocumentReference<JsonMap> budget(String uid, String monthKey) =>
      budgets(uid).doc(monthKey);

  /// "Đồ đang dùng" of the shopping profile (spec 7.2)
  CollectionReference<JsonMap> ownedItems(String uid) =>
      user(uid).collection('ownedItems');

  /// Document id = month key "yyyy-MM"
  CollectionReference<JsonMap> reflections(String uid) =>
      user(uid).collection('reflections');
  DocumentReference<JsonMap> reflection(String uid, String monthKey) =>
      reflections(uid).doc(monthKey);
}
