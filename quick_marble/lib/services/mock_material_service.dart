import 'dart:async';

import '../models/material_item.dart';
import 'material_service.dart';

class MockMaterialService implements MaterialService {
  final _controller = StreamController<List<MaterialItem>>.broadcast();

  final List<MaterialItem> _materials = [
    const MaterialItem(
      id: 'black-galaxy',
      name: 'Black Galaxy Granite',
      category: 'Granite',
      costPerUnit: 180000,
      sellingPricePerUnit: 280000,
      unitLabel: 'per 60cm',
      isActive: true,
    ),
    const MaterialItem(
      id: 'absolute-black',
      name: 'Absolute Black Granite',
      category: 'Granite',
      costPerUnit: 160000,
      sellingPricePerUnit: 250000,
      unitLabel: 'per 60cm',
      isActive: true,
    ),
    const MaterialItem(
      id: 'white-marble',
      name: 'White Marble',
      category: 'Marble',
      costPerUnit: 220000,
      sellingPricePerUnit: 350000,
      unitLabel: 'per 60cm',
      isActive: true,
    ),
  ];

  @override
  Stream<List<MaterialItem>> watchMaterials() async* {
    final copy = [..._materials]..sort((a, b) => a.name.compareTo(b.name));
    yield List.unmodifiable(copy);
    yield* _controller.stream;
  }

  @override
  Future<MaterialItem> createMaterial({
    required String name,
    required String category,
    required double costPerUnit,
    required double sellingPricePerUnit,
    required String unitLabel,
  }) async {
    final material = MaterialItem(
      id: 'material-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: category,
      costPerUnit: costPerUnit,
      sellingPricePerUnit: sellingPricePerUnit,
      unitLabel: unitLabel,
      isActive: true,
    );

    _materials.insert(0, material);
    _emit();
    return material;
  }

  @override
  Future<void> updateMaterial(MaterialItem material) async {
    final index = _materials.indexWhere((item) => item.id == material.id);
    if (index == -1) return;
    _materials[index] = material;
    _emit();
  }

  @override
  Future<void> setMaterialActive(String materialId, bool isActive) async {
    final index = _materials.indexWhere((item) => item.id == materialId);
    if (index == -1) return;
    _materials[index] = _materials[index].copyWith(isActive: isActive);
    _emit();
  }

  void _emit() {
    final copy = [..._materials]..sort((a, b) => a.name.compareTo(b.name));
    _controller.add(List.unmodifiable(copy));
  }
}
