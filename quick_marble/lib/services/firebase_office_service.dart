import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/office.dart';
import 'office_service.dart';

class FirebaseOfficeService implements OfficeService {
  final FirebaseFirestore _firestore;

  FirebaseOfficeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('offices');

  @override
  Stream<List<Office>> watchOffices() {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Office.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<Office> createOffice({
    required String name,
    required String location,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw const OfficeException('Office name is required.');
    }

    final duplicate = await _collection
        .where('nameLower', isEqualTo: trimmedName.toLowerCase())
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw const OfficeException('An office with this name already exists.');
    }

    final doc = _collection.doc();

    final office = Office(
      id: doc.id,
      name: trimmedName,
      location: location.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    await doc.set({
      ...office.toMap(),
      'nameLower': trimmedName.toLowerCase(),
    });

    return office;
  }

  @override
  Future<void> updateOffice(Office office) async {
    await _collection.doc(office.id).update({
      ...office.toMap(),
      'nameLower': office.name.toLowerCase(),
    });
  }

  @override
  Future<void> setOfficeActive(String officeId, bool isActive) async {
    await _collection.doc(officeId).update({
      'isActive': isActive,
    });
  }
}
