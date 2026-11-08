import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/user_summary.dart';

abstract class UserDirectoryService {
  /// Every profile; staff and admins may read them (firestore.rules)
  Stream<List<UserSummary>> watchUsers();

  /// Item and purchase counts of one user (count() queries). Admins only.
  Future<UserActivity> activityOf(String uid);
}

class FirestoreUserDirectoryService implements UserDirectoryService {
  final SharedPaths _paths;

  FirestoreUserDirectoryService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<UserSummary>> watchUsers() => _paths.users().snapshots().map(
    // Sorted here: orderBy('createdAt') would drop profiles without the field
    (s) => s.docs.map(UserSummary.fromFirestore).toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      ),
  );

  @override
  Future<UserActivity> activityOf(String uid) async {
    final user = _paths.user(uid);
    final counts = await Future.wait([
      user.collection('wishlistItems').count().get(),
      user.collection('purchases').count().get(),
    ]);
    return UserActivity(
      wishlistItems: counts[0].count ?? 0,
      purchases: counts[1].count ?? 0,
    );
  }
}
