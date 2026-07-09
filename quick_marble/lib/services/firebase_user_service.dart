import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'user_service.dart';

class FirebaseUserService implements UserService {
  final FirebaseFirestore _firestore;

  FirebaseUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Stream<List<AppUser>> watchUsers() {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? assignedOfficeId,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      throw const UserException('Name is required.');
    }

    if (!trimmedEmail.contains('@')) {
      throw const UserException('Enter a valid email address.');
    }

    if (role != UserRole.administrator &&
        (assignedOfficeId == null || assignedOfficeId.isEmpty)) {
      throw const UserException(
        'Managers and Sales Officers must be assigned an office.',
      );
    }

    final duplicate = await _collection
        .where('emailLower', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw const UserException('A user with this email already exists.');
    }

    final doc = _collection.doc();

    final user = AppUser(
      uid: doc.id,
      name: trimmedName,
      email: trimmedEmail,
      phone: phone.trim(),
      role: role,
      assignedOfficeId:
          role == UserRole.administrator ? null : assignedOfficeId,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await doc.set({
      ...user.toMap(),
      'emailLower': trimmedEmail,
    });

    return user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    if (user.role != UserRole.administrator &&
        (user.assignedOfficeId == null || user.assignedOfficeId!.isEmpty)) {
      throw const UserException(
        'Managers and Sales Officers must be assigned an office.',
      );
    }

    await _collection.doc(user.uid).update({
      ...user.toMap(),
      'emailLower': user.email.toLowerCase(),
    });
  }

  @override
  Future<void> setUserActive(String uid, bool isActive) async {
    await _collection.doc(uid).update({
      'isActive': isActive,
    });
  }
}
