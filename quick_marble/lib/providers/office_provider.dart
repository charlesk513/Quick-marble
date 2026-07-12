import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/office.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_office_service.dart';
import '../services/office_service.dart';

final officeServiceProvider = Provider<OfficeService>((ref) {
  return FirebaseOfficeService();
});

final officesStreamProvider = StreamProvider<List<Office>>((ref) {
  return ref.watch(officeServiceProvider).watchOffices();
});

final activeOfficesProvider = Provider<List<Office>>((ref) {
  final offices = ref.watch(officesStreamProvider).valueOrNull ?? [];
  final active = offices.where((office) => office.isActive).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return active;
});

class OfficeController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final OfficeService _service;

  OfficeController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  Office? _findOffice(String id) {
    final offices =
        _ref.read(officesStreamProvider).valueOrNull ?? const <Office>[];

    for (final office in offices) {
      if (office.id == id) return office;
    }

    return null;
  }

  Future<void> createOffice({
    required String name,
    required String location,
  }) async {
    state = const AsyncValue.loading();

    try {
      final office = await _service.createOffice(
        name: name,
        location: location,
      );

      await _addLog(
        officeId: office.id,
        action: ActivityAction.created,
        entityLabel: office.name,
        message: 'Created office ${office.name} in ${office.location}.',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateOffice(Office office) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateOffice(office);

      await _addLog(
        officeId: office.id,
        action: ActivityAction.updated,
        entityLabel: office.name,
        message: 'Updated office ${office.name}.',
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setOfficeActive(
    String officeId,
    bool isActive,
  ) async {
    state = const AsyncValue.loading();
    final office = _findOffice(officeId);

    try {
      await _service.setOfficeActive(officeId, isActive);

      if (office != null) {
        await _addLog(
          officeId: office.id,
          action:
              isActive ? ActivityAction.activated : ActivityAction.cancelled,
          entityLabel: office.name,
          message: isActive
              ? 'Reactivated office ${office.name}.'
              : 'Deactivated office ${office.name}.',
        );
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _addLog({
    required String officeId,
    required ActivityAction action,
    required String entityLabel,
    required String message,
  }) async {
    final actor = _ref.read(currentUserProvider);

    try {
      await _ref.read(activityLogServiceProvider).addLog(
            officeId: officeId,
            actorName: actor?.name ?? 'System',
            action: action,
            entityType: 'Office',
            entityLabel: entityLabel,
            message: message,
          );
    } catch (_) {
      // Audit logging must not make the main office action fail.
    }
  }
}

final officeControllerProvider =
    StateNotifierProvider<OfficeController, AsyncValue<void>>((ref) {
  return OfficeController(
    ref,
    ref.watch(officeServiceProvider),
  );
});
