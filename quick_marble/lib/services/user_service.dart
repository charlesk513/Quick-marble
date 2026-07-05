import '../models/app_user.dart';

/// Abstraction over the staff directory (the Firestore `users` collection
/// in production). This is intentionally separate from [AuthService]:
/// AuthService owns *credentials* (email/password, sign-in), while
/// UserService owns *profiles* (name, role, office, active status) —
/// exactly how Firebase Auth and Firestore are split in the real backend.
abstract class UserService {
  /// Emits the full staff list whenever any user is added or changed.
  Stream<List<AppUser>> watchUsers();

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? assignedOfficeId,
  });

  Future<void> updateUser(AppUser user);

  Future<void> setUserActive(String uid, bool isActive);
}

class UserException implements Exception {
  final String message;
  const UserException(this.message);

  @override
  String toString() => message;
}
