import 'dart:async';
import '../models/office.dart';
import 'office_service.dart';

/// In-memory implementation of [OfficeService], seeded with the four
/// offices that exist today. Swap for a Firestore-backed implementation
/// once the Firebase project is created — nothing else needs to change,
/// since every consumer depends on the [OfficeService] interface.
class MockOfficeService implements OfficeService {
  final _controller = StreamController<List<Office>>.broadcast();

  final List<Office> _offices = [
    Office(
      id: 'nansana',
      name: 'Nansana (Main)',
      location: 'Nansana',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Office(
      id: 'kajjansi',
      name: 'Kajjansi Branch',
      location: 'Kajjansi',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Office(
      id: 'buloba',
      name: 'Buloba Branch',
      location: 'Buloba',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Office(
      id: 'bulenga',
      name: 'Bulenga Branch',
      location: 'Bulenga',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  int _sequence = 0;

  MockOfficeService() {
    // Emit the initial seed as soon as someone subscribes.
    scheduleMicrotask(() => _emit());
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_offices));
    }
  }

  @override
  Stream<List<Office>> watchOffices() => _controller.stream;

  @override
  Future<Office> createOffice({
    required String name,
    required String location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const OfficeException('Office name is required.');
    }
    final duplicate = _offices.any(
      (o) => o.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (duplicate) {
      throw const OfficeException('An office with this name already exists.');
    }

    _sequence++;
    final office = Office(
      id: 'office_${DateTime.now().millisecondsSinceEpoch}_$_sequence',
      name: trimmedName,
      location: location.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    _offices.add(office);
    _emit();
    return office;
  }

  @override
  Future<void> updateOffice(Office office) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _offices.indexWhere((o) => o.id == office.id);
    if (index == -1) {
      throw const OfficeException('Office not found.');
    }
    _offices[index] = office;
    _emit();
  }

  @override
  Future<void> setOfficeActive(String officeId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _offices.indexWhere((o) => o.id == officeId);
    if (index == -1) {
      throw const OfficeException('Office not found.');
    }
    _offices[index] = _offices[index].copyWith(isActive: isActive);
    _emit();
  }
}
