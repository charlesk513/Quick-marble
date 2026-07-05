import 'dart:async';
import '../models/app_user.dart';
import 'user_service.dart';

/// In-memory implementation of [UserService], seeded to match the demo
/// accounts in [MockAuthService] so testing stays consistent. Swap for a
/// Firestore-backed implementation once Firebase is configured.
///
/// NOTE for the Firebase-wiring stage: creating another user's account
/// must NOT be done with `createUserWithEmailAndPassword` on the client,
/// because that silently signs the admin out and into the new account.
/// Use a Cloud Function (callable, running with the Admin SDK) to create
/// the Firebase Auth user and its Firestore profile together instead.
class MockUserService implements UserService {
  final _controller = StreamController<List<AppUser>>.broadcast();

  final List<AppUser> _users = [
    AppUser(
      uid: 'admin-1',
      name: 'Owner Admin',
      email: 'admin@quickmarble.ug',
      phone: '+256700000001',
      role: UserRole.administrator,
      assignedOfficeId: null,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    AppUser(
      uid: 'manager-nansana-1',
      name: 'Nansana Manager',
      email: 'manager.nansana@quickmarble.ug',
      phone: '+256700000002',
      role: UserRole.manager,
      assignedOfficeId: 'nansana',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    AppUser(
      uid: 'sales-kajjansi-1',
      name: 'Kajjansi Sales Officer',
      email: 'sales.kajjansi@quickmarble.ug',
      phone: '+256700000003',
      role: UserRole.salesOfficer,
      assignedOfficeId: 'kajjansi',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  int _sequence = 0;

  MockUserService() {
    scheduleMicrotask(() => _emit());
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_users));
    }
  }

  @override
  Stream<List<AppUser>> watchUsers() => _controller.stream;

  @override
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? assignedOfficeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final trimmedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      throw const UserException('Name is required.');
    }
    if (!trimmedEmail.contains('@')) {
      throw const UserException('Enter a valid email address.');
    }
    if (role != UserRole.administrator &&
        (assignedOfficeId == null || assignedOfficeId.isEmpty)) {
      throw const UserException('Managers and Sales Officers must be assigned an office.');
    }
    final duplicate = _users.any((u) => u.email.toLowerCase() == trimmedEmail);
    if (duplicate) {
      throw const UserException('A user with this email already exists.');
    }

    _sequence++;
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}_$_sequence',
      name: name.trim(),
      email: trimmedEmail,
      phone: phone.trim(),
      role: role,
      assignedOfficeId: role == UserRole.administrator ? null : assignedOfficeId,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _emit();
    return user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.uid == user.uid);
    if (index == -1) {
      throw const UserException('User not found.');
    }
    if (user.role != UserRole.administrator &&
        (user.assignedOfficeId == null || user.assignedOfficeId!.isEmpty)) {
      throw const UserException('Managers and Sales Officers must be assigned an office.');
    }
    _users[index] = user;
    _emit();
  }

  @override
  Future<void> setUserActive(String uid, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index == -1) {
      throw const UserException('User not found.');
    }
    _users[index] = _users[index].copyWith(isActive: isActive);
    _emit();
  }
}
