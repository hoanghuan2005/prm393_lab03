import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum AnnouncementStatus {
  published('published', 'Đang hiển thị'),
  archived('archived', 'Đã lưu trữ');

  final String key;
  final String label;

  const AnnouncementStatus(this.key, this.label);

  static AnnouncementStatus fromKey(Object? key) =>
      AnnouncementStatus.values.firstWhere(
        (s) => s.key == key,
        orElse: () => AnnouncementStatus.archived,
      );
}

/// `announcements/{id}`: written on the web admin, shown in every app inbox.
class Announcement {
  static const int maxTitle = 80;
  static const int maxBody = 1000;

  final String id;
  final String title;
  final String body;
  final AnnouncementStatus status;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.status = AnnouncementStatus.published,
    this.createdAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return Announcement(
      id: doc.id,
      title: readText(data['title']) ?? '',
      body: readText(data['body']) ?? '',
      status: AnnouncementStatus.fromKey(data['status']),
      createdAt: readDate(data['createdAt']),
    );
  }
}
