import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/material_item.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_material_service.dart';
import '../services/material_service.dart';

final materialServiceProvider = Provider<MaterialService>((ref) {
  return FirebaseMaterialService();
});

final materialsStreamProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(materialServiceProvider).watchMaterials();
});

final activeMaterialsProvider = Provider<List<MaterialItem>>((ref) {
  final materials = ref.watch(materialsStreamProvider).valueOrNull ?? [];
  return materials.where((material) => material.isActive).toList();
});

class MaterialController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final MaterialService _service;

  MaterialController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  MaterialItem? _findMaterial(String id) {
    final materials = _ref.read(materialsStreamProvider).valueOrNull ??
        const <MaterialItem>[];

    for (final material in materials) {
      if (material.id == id) return material;
    }

    return null;
  }

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

      await _addLog(
        action: ActivityAction.created,
        entityLabel: name,
        message: 'Created material $name in category $category.',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateMaterial(MaterialItem material) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateMaterial(material);

      await _addLog(
        action: ActivityAction.updated,
        entityLabel: material.name,
        message: 'Updated material ${material.name}.',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setMaterialActive(
    String id,
    bool isActive,
  ) async {
    state = const AsyncValue.loading();
    final material = _findMaterial(id);

    try {
      await _service.setMaterialActive(id, isActive);

      if (material != null) {
        await _addLog(
          action:
              isActive ? ActivityAction.activated : ActivityAction.cancelled,
          entityLabel: material.name,
          message: isActive
              ? 'Reactivated material ${material.name}.'
              : 'Deactivated material ${material.name}.',
        );
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _addLog({
    required ActivityAction action,
    required String entityLabel,
    required String message,
  }) async {
    final actor = _ref.read(currentUserProvider);

    try {
      await _ref.read(activityLogServiceProvider).addLog(
            officeId: actor?.assignedOfficeId ?? '',
            actorName: actor?.name ?? 'System',
            action: action,
            entityType: 'Material',
            entityLabel: entityLabel,
            message: message,
          );
    } catch (_) {
      // Audit logging must not make the main material action fail.
    }
  }
}

final materialControllerProvider =
    StateNotifierProvider<MaterialController, AsyncValue<void>>((ref) {
  return MaterialController(
    ref,
    ref.watch(materialServiceProvider),
  );
});
