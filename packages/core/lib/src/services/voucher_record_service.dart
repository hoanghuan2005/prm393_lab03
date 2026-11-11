import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/voucher_record.dart';
import 'shared_paths.dart';

/// Real Shopee vouchers the team enters on the web admin; the app reads the
/// active ones (`vouchers`, decision D-3). Vouchers are archived, never deleted.
abstract class VoucherRecordService {
  /// Every voucher, latest expiry first (no orderBy: old documents without
  /// `updatedAt` must still show so they can be archived)
  Stream<List<VoucherRecord>> watchAll();

  /// Returns the new voucher id
  Future<String> create({required String byUid, required VoucherDraft draft});

  /// Replaces the whole document, so fields of the old admin screen disappear
  Future<void> update(
    String id,
    VoucherDraft draft, {
    required bool isActive,
    required String byUid,
  });

  /// Archive (false) or use again (true)
  Future<void> setActive(String id, bool isActive, {required String byUid});
}

class FirestoreVoucherRecordService implements VoucherRecordService {
  final SharedPaths _paths;

  FirestoreVoucherRecordService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  static Map<String, dynamic> _stamp(String byUid) => {
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': byUid,
  };

  @override
  Stream<List<VoucherRecord>> watchAll() => _paths.vouchers().snapshots().map(
    (s) =>
        s.docs.map(VoucherRecord.fromFirestore).toList()
          ..sort((a, b) => b.draft.validUntil.compareTo(a.draft.validUntil)),
  );

  @override
  Future<String> create({
    required String byUid,
    required VoucherDraft draft,
  }) async {
    final ref = _paths.vouchers().doc();
    await ref.set({...draft.toMap(), 'isActive': true, ..._stamp(byUid)});
    return ref.id;
  }

  @override
  Future<void> update(
    String id,
    VoucherDraft draft, {
    required bool isActive,
    required String byUid,
  }) => _paths.voucher(id).set({
    ...draft.toMap(),
    'isActive': isActive,
    ..._stamp(byUid),
  });

  @override
  Future<void> setActive(String id, bool isActive, {required String byUid}) =>
      _paths.voucher(id).update({'isActive': isActive, ..._stamp(byUid)});
}
