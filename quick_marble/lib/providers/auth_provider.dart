import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _service;

  AuthController(this._service) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await _service.signIn(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _service.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await _service.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
