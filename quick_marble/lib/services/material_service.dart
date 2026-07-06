import '../models/material_item.dart';

abstract class MaterialService {
  Stream<List<MaterialItem>> watchMaterials();

  Future<MaterialItem> createMaterial({
    required String name,
    required String category,
    required double costPerUnit,
    required double sellingPricePerUnit,
    required String unitLabel,
  });

  Future<void> updateMaterial(MaterialItem material);
  Future<void> setMaterialActive(String materialId, bool isActive);
}
