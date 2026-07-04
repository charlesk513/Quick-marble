import 'dart:async';
import '../models/app_user.dart';
import 'auth_service.dart';

/// A working in-memory implementation of [AuthService], used while the
/// Firebase project is not yet created. It lets us build and test every
/// screen, role guard, and office-scoping rule against realistic accounts.
///
/// Swap this for `FirebaseAuthService` in `providers/auth_provider.dart`
/// once Firebase is configured — nothing else in the app needs to change,
/// because everything depends on the `AuthService` interface, not this class.
class MockAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  // Seeded demo accounts covering all three roles across offices.
  static final Map<String, _MockAccount> _accounts = {
    'admin@quickmarble.ug': _MockAccount(
      password: 'admin123',
      user: AppUser(
        uid: 'admin-1',
        name: 'Owner Admin',
        email: 'admin@quickmarble.ug',
        phone: '+256700000001',
        role: UserRole.administrator,
        assignedOfficeId: null,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    'manager.nansana@quickmarble.ug': _MockAccount(
      password: 'manager123',
      user: AppUser(
        uid: 'manager-nansana-1',
        name: 'Nansana Manager',
        email: 'manager.nansana@quickmarble.ug',
        phone: '+256700000002',
        role: UserRole.manager,
        assignedOfficeId: 'nansana',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    'sales.kajjansi@quickmarble.ug': _MockAccount(
      password: 'sales123',
      user: AppUser(
        uid: 'sales-kajjansi-1',
        name: 'Kajjansi Sales Officer',
        email: 'sales.kajjansi@quickmarble.ug',
        phone: '+256700000003',
        role: UserRole.salesOfficer,
        assignedOfficeId: 'kajjansi',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
  };

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signIn(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email or password.');
    }
    if (!account.user.isActive) {
      throw const AuthException('This account has been deactivated.');
    }
    _current = account.user;
    _controller.add(_current);
    return account.user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!_accounts.containsKey(email.trim().toLowerCase())) {
      throw const AuthException('No account found for that email.');
    }
    // In the mock, we simply succeed — a real reset email has nothing to send to.
  }
}

class _MockAccount {
  final String password;
  final AppUser user;
  const _MockAccount({required this.password, required this.user});
}
