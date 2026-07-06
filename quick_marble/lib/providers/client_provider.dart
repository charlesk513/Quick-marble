import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client.dart';
import '../providers/auth_provider.dart';
import '../services/client_service.dart';
import '../services/mock_client_service.dart';

final clientServiceProvider = Provider<ClientService>((ref) {
  return MockClientService();
});

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientServiceProvider).watchClients();
});

final visibleClientsProvider = Provider<List<Client>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clients = ref.watch(clientsStreamProvider).valueOrNull ?? [];
  if (user == null) return [];
  if (user.isAdministrator) return clients;
  return clients
      .where((client) => client.officeId == user.assignedOfficeId)
      .toList();
});

class ClientController extends StateNotifier<AsyncValue<void>> {
  final ClientService _service;
  ClientController(this._service) : super(const AsyncValue.data(null));

  Future<Client> createClient({
    required String officeId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = await _service.createClient(
        officeId: officeId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return client;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateClient(client);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setClientActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _service.setClientActive(id, isActive);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final clientControllerProvider =
    StateNotifierProvider<ClientController, AsyncValue<void>>((ref) {
  return ClientController(ref.watch(clientServiceProvider));
});
