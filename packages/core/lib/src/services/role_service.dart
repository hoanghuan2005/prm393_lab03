import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_role.dart';
import 'shared_paths.dart';

abstract class RoleService {
  /// Role of [uid]; a missing profile or field means [AppRole.user]
  Future<AppRole> roleOf(String uid);

  /// Admin only, never their own role (firestore.rules); changes only `role`
  Future<void> setRole(String uid, AppRole role);
}

class FirestoreRoleService implements RoleService {
  final SharedPaths _paths;

  FirestoreRoleService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Future<AppRole> roleOf(String uid) async {
    // Always ask the server: a cached 'admin' must not survive a role change
    final doc = await _paths
        .user(uid)
        .get(const GetOptions(source: Source.server));
    return AppRole.fromKey(doc.data()?['role']);
  }

  @override
  Future<void> setRole(String uid, AppRole role) =>
      _paths.user(uid).update({'role': role.key});
}
