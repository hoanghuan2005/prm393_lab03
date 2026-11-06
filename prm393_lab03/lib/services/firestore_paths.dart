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

  /// "Gửi góp ý" messages (create only)
  CollectionReference<JsonMap> feedback(String uid) =>
      user(uid).collection('feedback');

  /// Chrome extensions signed in with this account (pending → approved on the phone)
  CollectionReference<JsonMap> extensionSessions(String uid) =>
      user(uid).collection('extensionSessions');
  DocumentReference<JsonMap> extensionSession(String uid, String sessionId) =>
      extensionSessions(uid).doc(sessionId);

  /// QR linking requests created by the extension (top level: the extension is not the owner yet)
  DocumentReference<JsonMap> extensionPairing(String pairingId) =>
      db.collection('extensionPairings').doc(pairingId);

  /// "Giá người khác ghi": anonymous reports shared by every user (top level, no uid)
  CollectionReference<JsonMap> sharedPriceReports(String productKey) =>
      db.collection('sharedPrices').doc(productKey).collection('reports');

  /// "Biểu đồ giá tham khảo": shared per product (top level, no uid)
  CollectionReference<JsonMap> priceHistory() => db.collection('priceHistory');
  DocumentReference<JsonMap> priceHistoryProduct(String productKey) =>
      priceHistory().doc(productKey);
  CollectionReference<JsonMap> priceHistoryReports(String productKey) =>
      priceHistoryProduct(productKey).collection('reports');

  /// The same item in several shops, grouped by hand
  CollectionReference<JsonMap> productGroups() =>
      db.collection('productGroups');
  DocumentReference<JsonMap> productGroup(String groupId) =>
      productGroups().doc(groupId);

  /// Document id = month key "yyyy-MM"
  CollectionReference<JsonMap> reflections(String uid) =>
      user(uid).collection('reflections');
  DocumentReference<JsonMap> reflection(String uid, String monthKey) =>
      reflections(uid).doc(monthKey);
}
