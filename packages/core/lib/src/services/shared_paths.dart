import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, dynamic>;

/// The only place that spells out the paths shared by the app and the web admin.
class SharedPaths {
  final FirebaseFirestore db;

  const SharedPaths(this.db);

  CollectionReference<JsonMap> users() => db.collection('users');
  DocumentReference<JsonMap> user(String uid) => users().doc(uid);

  /// Messages to one user, written by an admin when a suggestion is reviewed
  CollectionReference<JsonMap> inbox(String uid) =>
      user(uid).collection('inbox');

  CollectionReference<JsonMap> saleEvents() => db.collection('saleEvents');
  DocumentReference<JsonMap> saleEvent(String id) => saleEvents().doc(id);

  CollectionReference<JsonMap> saleSuggestions() =>
      db.collection('saleSuggestions');
  DocumentReference<JsonMap> saleSuggestion(String id) =>
      saleSuggestions().doc(id);

  CollectionReference<JsonMap> announcements() =>
      db.collection('announcements');
  DocumentReference<JsonMap> announcement(String id) => announcements().doc(id);

  /// Real Shopee vouchers entered on the web admin; the app reads active ones
  CollectionReference<JsonMap> vouchers() => db.collection('vouchers');
  DocumentReference<JsonMap> voucher(String id) => vouchers().doc(id);

  /// Crash reports written by the app, read and resolved on the web admin
  CollectionReference<JsonMap> crashes() => db.collection('crashes');
  DocumentReference<JsonMap> crash(String id) => crashes().doc(id);
}
