/// `users/{uid}.role`. A missing or unknown value reads as [AppRole.user].
/// The first admin is set by hand in the Firebase console; only an admin
/// changes roles afterwards, never their own (firestore.rules).
enum AppRole {
  user('user', 'Người dùng'),
  staff('staff', 'Nhân viên'),
  admin('admin', 'Quản trị viên');

  final String key;
  final String label;

  const AppRole(this.key, this.label);

  /// The web admin accepts staff and admins
  bool get canUseWebAdmin => this == staff || this == admin;

  static AppRole fromKey(Object? key) => AppRole.values.firstWhere(
    (r) => r.key == key,
    orElse: () => AppRole.user,
  );
}
