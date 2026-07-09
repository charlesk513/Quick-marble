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

  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen(_handleAuthState);
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

    final user = await _loadUserProfile(firebaseUser.uid);

    if (!user.isActive) {
      await _auth.signOut();
      throw const AuthException('This account has been deactivated.');
    }

    _currentUser = user;
    _controller.add(user);
  }

  Future<AppUser> _loadUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw const AuthException('User profile not found.');
    }

    return AppUser.fromMap(doc.id, doc.data()!);
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

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
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
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  String _friendlyMessage(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
