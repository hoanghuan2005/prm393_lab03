import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';
import 'shared_paths.dart';

abstract class AnnouncementService {
  /// Every announcement (admin), latest first
  Stream<List<Announcement>> watchAll();

  /// Published announcements (app inbox), latest first
  Stream<List<Announcement>> watchPublished();

  Future<void> publish({
    required String adminUid,
    required String title,
    required String body,
  });

  /// Archive or restore; announcements are never deleted
  Future<void> setStatus(String id, AnnouncementStatus status);
}

class FirestoreAnnouncementService implements AnnouncementService {
  final SharedPaths _paths;

  FirestoreAnnouncementService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<Announcement>> watchAll() => _paths
      .announcements()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromFirestore).toList());

  @override
  Stream<List<Announcement>> watchPublished() => _paths
      .announcements()
      .where('status', isEqualTo: AnnouncementStatus.published.key)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromFirestore).toList());

  @override
  Future<void> publish({
    required String adminUid,
    required String title,
    required String body,
  }) => _paths.announcements().add({
    'title': title.trim(),
    'body': body.trim(),
    'status': AnnouncementStatus.published.key,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': adminUid,
  });

  @override
  Future<void> setStatus(String id, AnnouncementStatus status) =>
      _paths.announcement(id).update({
        'status': status.key,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
