import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_user_service.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return FirebaseUserService();
});

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).watchUsers();
});

class UserController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final UserService _service;

  UserController(this._ref, this._service) : super(const AsyncValue.data(null));

  AppUser? _findUser(String uid) {
    final users =
        _ref.read(usersStreamProvider).valueOrNull ?? const <AppUser>[];

    for (final user in users) {
      if (user.uid == uid) return user;
    }

    return null;
  }

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

      await _addLog(
        officeId: assignedOfficeId ?? '',
        action: ActivityAction.created,
        entityLabel: name,
        message: 'Created ${role.label} account for $name.',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateUser(AppUser user) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateUser(user);

      await _addLog(
        officeId: user.assignedOfficeId ?? '',
        action: ActivityAction.updated,
        entityLabel: user.name,
        message: 'Updated user ${user.name} (${user.role.label}).',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserActive(String uid, bool isActive) async {
    state = const AsyncValue.loading();
    final targetUser = _findUser(uid);

    try {
      await _service.setUserActive(uid, isActive);

      if (targetUser != null) {
        await _addLog(
          officeId: targetUser.assignedOfficeId ?? '',
          action:
              isActive ? ActivityAction.activated : ActivityAction.cancelled,
          entityLabel: targetUser.name,
          message: isActive
              ? 'Reactivated user ${targetUser.name}.'
              : 'Deactivated user ${targetUser.name}.',
        );
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _addLog({
    required String officeId,
    required ActivityAction action,
    required String entityLabel,
    required String message,
  }) async {
    final actor = _ref.read(currentUserProvider);

    try {
      await _ref.read(activityLogServiceProvider).addLog(
            officeId: officeId,
            actorName: actor?.name ?? 'System',
            action: action,
            entityType: 'User',
            entityLabel: entityLabel,
            message: message,
          );
    } catch (_) {
      // Audit logging must not make the main user action fail.
    }
  }
}

final userControllerProvider =
    StateNotifierProvider<UserController, AsyncValue<void>>((ref) {
  return UserController(
    ref,
    ref.watch(userServiceProvider),
  );
});
