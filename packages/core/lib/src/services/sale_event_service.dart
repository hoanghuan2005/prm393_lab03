import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale_event.dart';
import 'shared_paths.dart';

/// Every write stamps `updatedAt` / `updatedBy` (firestore.rules checks both).
abstract class SaleEventService {
  /// Every event (staff), latest sale day first
  Stream<List<SaleEvent>> watchAll();

  /// Published events only (app), earliest sale day first
  Stream<List<SaleEvent>> watchPublished();

  /// Returns the new event id. [status] is draft or published.
  Future<String> create({
    required String byUid,
    required SaleEventDraft draft,
    SaleEventStatus status = SaleEventStatus.published,
  });

  Future<void> update(String id, SaleEventDraft draft, {required String byUid});

  /// Publish a draft or archive; events are never deleted and archiving is final
  Future<void> setStatus(
    String id,
    SaleEventStatus status, {
    required String byUid,
  });
}

class FirestoreSaleEventService implements SaleEventService {
  final SharedPaths _paths;

  FirestoreSaleEventService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  static Map<String, dynamic> _stamp(String byUid) => {
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': byUid,
  };

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
    required String byUid,
    required SaleEventDraft draft,
    SaleEventStatus status = SaleEventStatus.published,
  }) async {
    final ref = _paths.saleEvents().doc();
    await ref.set({...draft.toMap(), 'status': status.key, ..._stamp(byUid)});
    return ref.id;
  }

  @override
  Future<void> update(
    String id,
    SaleEventDraft draft, {
    required String byUid,
  }) => _paths.saleEvent(id).update({...draft.toMap(), ..._stamp(byUid)});

  @override
  Future<void> setStatus(
    String id,
    SaleEventStatus status, {
    required String byUid,
  }) => _paths.saleEvent(id).update({'status': status.key, ..._stamp(byUid)});
}
