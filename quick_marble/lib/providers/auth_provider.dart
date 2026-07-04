import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';

/// Single place to swap MockAuthService -> FirebaseAuthService once
/// Firebase is configured. Nothing downstream needs to change.
final authServiceProvider = Provider<AuthService>((ref) {
  return MockAuthService();
});

/// Streams the currently signed-in user (or null), driving route guards
/// and the splash -> login/home decision.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges();
});

/// Convenience synchronous accessor for the current user where a stream
/// isn't practical (e.g. inside imperative button handlers).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _service;
  AuthController(this._service) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() => _service.signOut();

  Future<void> resetPassword(String email) => _service.sendPasswordResetEmail(email);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
