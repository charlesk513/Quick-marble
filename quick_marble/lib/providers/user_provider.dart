import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/mock_user_service.dart';

/// Single place to swap MockUserService -> a Firestore-backed one later.
final userServiceProvider = Provider<UserService>((ref) {
  return MockUserService();
});

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).watchUsers();
});

class UserController extends StateNotifier<AsyncValue<void>> {
  final UserService _service;
  UserController(this._service) : super(const AsyncValue.data(null));

  Future<void> createUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? assignedOfficeId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createUser(
        name: name,
        email: email,
        phone: phone,
        role: role,
        assignedOfficeId: assignedOfficeId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateUser(AppUser user) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateUser(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setUserActive(String uid, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _service.setUserActive(uid, isActive);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final userControllerProvider =
    StateNotifierProvider<UserController, AsyncValue<void>>((ref) {
  return UserController(ref.watch(userServiceProvider));
});
