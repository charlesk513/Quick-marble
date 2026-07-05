import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/office.dart';
import '../services/office_service.dart';
import '../services/mock_office_service.dart';

/// Single place to swap MockOfficeService -> a Firestore-backed one later.
final officeServiceProvider = Provider<OfficeService>((ref) {
  return MockOfficeService();
});

final officesStreamProvider = StreamProvider<List<Office>>((ref) {
  return ref.watch(officeServiceProvider).watchOffices();
});

/// Convenience: only active offices, sorted by name — used anywhere staff
/// need to pick an office (e.g. the user-assignment dropdown).
final activeOfficesProvider = Provider<List<Office>>((ref) {
  final offices = ref.watch(officesStreamProvider).valueOrNull ?? [];
  final active = offices.where((o) => o.isActive).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return active;
});

class OfficeController extends StateNotifier<AsyncValue<void>> {
  final OfficeService _service;
  OfficeController(this._service) : super(const AsyncValue.data(null));

  Future<void> createOffice({required String name, required String location}) async {
    state = const AsyncValue.loading();
    try {
      await _service.createOffice(name: name, location: location);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateOffice(Office office) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateOffice(office);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setOfficeActive(String officeId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _service.setOfficeActive(officeId, isActive);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final officeControllerProvider =
    StateNotifierProvider<OfficeController, AsyncValue<void>>((ref) {
  return OfficeController(ref.watch(officeServiceProvider));
});
