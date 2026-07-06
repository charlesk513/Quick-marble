import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_item.dart';
import '../services/material_service.dart';
import '../services/mock_material_service.dart';

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MockMaterialService();
});

final materialsStreamProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(materialServiceProvider).watchMaterials();
});

final activeMaterialsProvider = Provider<List<MaterialItem>>((ref) {
  final materials = ref.watch(materialsStreamProvider).valueOrNull ?? [];
  return materials.where((material) => material.isActive).toList();
});

class MaterialController extends StateNotifier<AsyncValue<void>> {
  final MaterialService _service;

  MaterialController(this._service) : super(const AsyncValue.data(null));

  Future<void> createMaterial({
    required String name,
    required String category,
    required double costPerUnit,
    required double sellingPricePerUnit,
    required String unitLabel,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createMaterial(
        name: name,
        category: category,
        costPerUnit: costPerUnit,
        sellingPricePerUnit: sellingPricePerUnit,
        unitLabel: unitLabel,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMaterial(MaterialItem material) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateMaterial(material);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setMaterialActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _service.setMaterialActive(id, isActive);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final materialControllerProvider =
    StateNotifierProvider<MaterialController, AsyncValue<void>>((ref) {
  return MaterialController(ref.watch(materialServiceProvider));
});
