import '../models/app_user.dart';

/// Abstraction over the authentication backend so the rest of the app
/// never talks to FirebaseAuth directly. This lets us wire real Firebase
/// in once the project is created, without touching UI or controllers.
abstract class AuthService {
  /// Emits the current signed-in user (or null) whenever auth state changes.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
