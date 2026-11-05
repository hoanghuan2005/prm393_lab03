import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale_event.dart';
import 'shared_paths.dart';

abstract class SaleEventService {
  /// Every event (admin), latest sale day first
  Stream<List<SaleEvent>> watchAll();

  /// Published events only (app), earliest sale day first
  Stream<List<SaleEvent>> watchPublished();

  /// Returns the new event id
  Future<String> create({
    required String adminUid,
    required SaleEventDraft draft,
  });

  Future<void> update(String id, SaleEventDraft draft);

  /// Archive or restore; events are never deleted
  Future<void> setStatus(String id, SaleEventStatus status);
}

class FirestoreSaleEventService implements SaleEventService {
  final SharedPaths _paths;

  FirestoreSaleEventService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<SaleEvent>> watchAll() => _paths
      .saleEvents()
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SaleEvent.fromFirestore).toList());

  @override
  Stream<List<SaleEvent>> watchPublished() => _paths
      .saleEvents()
      .where('status', isEqualTo: SaleEventStatus.published.key)
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map(SaleEvent.fromFirestore).toList());

  @override
  Future<String> create({
    required String adminUid,
    required SaleEventDraft draft,
  }) async {
    final ref = _paths.saleEvents().doc();
    await ref.set({
      ...draft.toMap(),
      'status': SaleEventStatus.published.key,
      'source': SaleEventSource.admin.key,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': adminUid,
    });
    return ref.id;
  }

  @override
  Future<void> update(String id, SaleEventDraft draft) => _paths
      .saleEvent(id)
      .update({...draft.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> setStatus(String id, SaleEventStatus status) =>
      _paths.saleEvent(id).update({
        'status': status.key,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
