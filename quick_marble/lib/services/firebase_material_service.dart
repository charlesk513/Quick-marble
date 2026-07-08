import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/material_item.dart';
import 'material_service.dart';

class FirebaseMaterialService implements MaterialService {
  final FirebaseFirestore _firestore;

  FirebaseMaterialService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('materials');

  @override
  Stream<List<MaterialItem>> watchMaterials() {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MaterialItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<MaterialItem> createMaterial({
    required String name,
    required String category,
    required double costPerUnit,
    required double sellingPricePerUnit,
    required String unitLabel,
  }) async {
    final doc = _collection.doc();

    final material = MaterialItem(
      id: doc.id,
      name: name,
      category: category,
      costPerUnit: costPerUnit,
      sellingPricePerUnit: sellingPricePerUnit,
      unitLabel: unitLabel,
      isActive: true,
    );

    await doc.set(material.toMap());

    return material;
  }

  @override
  Future<void> updateMaterial(MaterialItem material) async {
    await _collection.doc(material.id).update(material.toMap());
  }

  @override
  Future<void> setMaterialActive(String materialId, bool isActive) async {
    await _collection.doc(materialId).update({
      'isActive': isActive,
    });
  }
}
