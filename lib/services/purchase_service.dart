import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/buying_motive.dart';
import '../models/purchase_item.dart';

/// Service abstraction for purchases using Cloud Firestore
class PurchaseService {
  final FirebaseFirestore _firestore;

  PurchaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _purchasesRef => _firestore.collection('purchases');

  /// Stream user purchases in real-time
  Stream<List<PurchaseItem>> streamUserPurchases(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _purchasesRef.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => PurchaseItem.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return items;
    });
  }

  /// Add a new purchase to Firestore
  Future<PurchaseItem> addPurchase({
    required String userId,
    required String title,
    required double amount,
    required BuyingMotive motive,
    required DateTime dateTime,
    String? note,
  }) async {
    final docRef = await _purchasesRef.add({
      'userId': userId,
      'title': title,
      'amount': amount,
      'motive': motive.key,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return PurchaseItem(
      id: docRef.id,
      userId: userId,
      title: title,
      amount: amount,
      motive: motive,
      dateTime: dateTime,
      note: note,
    );
  }

  /// Update an existing purchase in Firestore
  Future<void> updatePurchase({
    required String purchaseId,
    required String title,
    required double amount,
    required BuyingMotive motive,
    required DateTime dateTime,
    String? note,
  }) async {
    await _purchasesRef.doc(purchaseId).update({
      'title': title,
      'amount': amount,
      'motive': motive.key,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a purchase from Firestore
  Future<void> deletePurchase(String purchaseId) async {
    await _purchasesRef.doc(purchaseId).delete();
  }

  // ==================== BUDGETS COLLECTION ====================
  CollectionReference get _budgetsRef => _firestore.collection('budgets');

  /// Stream user's budget for a specific month (e.g. "2026-10") from Firestore
  Stream<Map<String, dynamic>?> streamMonthlyBudget(
    String userId,
    String month,
  ) {
    if (userId.isEmpty) return Stream.value(null);
    final docId = '${userId}_$month';
    return _budgetsRef.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }

  /// Save or update monthly budget on Cloud Firestore
  Future<void> saveMonthlyBudget({
    required String userId,
    required String month,
    required double monthlyLimit,
    Map<String, double>? categoryBudgets,
  }) async {
    final docId = '${userId}_$month';
    await _budgetsRef.doc(docId).set({
      'userId': userId,
      'month': month,
      'monthlyLimit': monthlyLimit,
      'categoryBudgets': categoryBudgets ?? {},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
