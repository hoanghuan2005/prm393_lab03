import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// One row of the web user list, read from `users/{uid}`.
class UserSummary {
  final String uid;
  final String? displayName;
  final String? email;
  final AppRole role;
  final bool isAnonymous;
  final DateTime? createdAt;

  const UserSummary({
    required this.uid,
    this.displayName,
    this.email,
    this.role = AppRole.user,
    this.isAnonymous = false,
    this.createdAt,
  });

  factory UserSummary.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return UserSummary(
      uid: doc.id,
      displayName: readText(data['displayName']),
      email: readText(data['email']),
      role: AppRole.fromKey(data['role']),
      isAnonymous: data['isAnonymous'] == true,
      createdAt: readDate(data['createdAt']),
    );
  }

  String get label =>
      displayName ?? email ?? (isAnonymous ? 'Khách (ẩn danh)' : 'Người dùng');
}

/// What a user has in the app: admins only (firestore.rules), so null for staff
class UserActivity {
  final int wishlistItems;
  final int purchases;

  const UserActivity({required this.wishlistItems, required this.purchases});

  /// "Cài app nhưng chưa dùng": nothing saved, nothing bought
  bool get isDormant => wishlistItems == 0 && purchases == 0;
}
