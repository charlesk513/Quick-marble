import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AppUser? _currentUser;
  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<fb.User?>? _authSubscription;

  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthState,
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(error, stackTrace);
      },
    );
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  Future<void> _handleAuthState(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _controller.add(null);
      return;
    }

    try {
      final user = await _loadUserProfile(firebaseUser.uid);

      if (!user.isActive) {
        await _auth.signOut();
        _currentUser = null;
        _controller.add(null);
        return;
      }

      _currentUser = user;
      _controller.add(user);
    } catch (error, stackTrace) {
      _currentUser = null;
      _controller.addError(error, stackTrace);
    }
  }

  Future<AppUser> _loadUserProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists || document.data() == null) {
      throw const AuthException('User profile not found.');
    }

    return AppUser.fromMap(document.id, document.data()!);
  }

  Future<void> _recordLogin(AppUser user) async {
    try {
      final document = _firestore.collection('activity_logs').doc();

      await document.set({
        'officeId': user.assignedOfficeId ?? '',
        'actorName': user.name,
        'action': 'login',
        'entityType': 'User',
        'entityLabel': user.name,
        'message': '${user.name} signed in as ${user.role.label}.',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Login must still succeed if activity logging temporarily fails.
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      final user = await _loadUserProfile(firebaseUser.uid);

      if (!user.isActive) {
        await _auth.signOut();
        throw const AuthException('This account has been deactivated.');
      }

      _currentUser = user;
      _controller.add(user);

      await _recordLogin(user);

      return user;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_friendlyMessage(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _controller.close();
  }
}
