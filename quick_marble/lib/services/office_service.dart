import '../models/office.dart';

/// Abstraction over office storage. The rest of the app depends only on
/// this interface, never on a concrete Firestore or mock implementation —
/// mirrors the pattern used by [AuthService].
abstract class OfficeService {
  /// Emits the full list of offices whenever any office changes.
  Stream<List<Office>> watchOffices();

  Future<Office> createOffice({
    required String name,
    required String location,
  });

  Future<void> updateOffice(Office office);

  Future<void> setOfficeActive(String officeId, bool isActive);
}

class OfficeException implements Exception {
  final String message;
  const OfficeException(this.message);

  @override
  String toString() => message;
}
