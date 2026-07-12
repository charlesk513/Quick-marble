import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/client.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../services/client_service.dart';
import '../services/firebase_client_service.dart';

final clientServiceProvider = Provider<ClientService>((ref) {
  return FirebaseClientService();
});

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <Client>[]);

  final officeId = user.isAdministrator ? null : user.assignedOfficeId;
  if (!user.isAdministrator && (officeId == null || officeId.trim().isEmpty)) {
    return Stream.value(const <Client>[]);
  }

  return ref.watch(clientServiceProvider).watchClients(officeId: officeId);
});

final visibleClientsProvider = Provider<List<Client>>((ref) {
  return ref.watch(clientsStreamProvider).valueOrNull ?? const <Client>[];
});

class ClientController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ClientService _service;

  ClientController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  Client? _findClient(String id) {
    final clients =
        _ref.read(clientsStreamProvider).valueOrNull ?? const <Client>[];
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

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
      await _addLog(
        officeId: client.officeId,
        action: ActivityAction.created,
        entityLabel: client.name,
        message: 'Created client ${client.name}.',
      );
      state = const AsyncValue.data(null);
      return client;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateClient(client);
      await _addLog(
        officeId: client.officeId,
        action: ActivityAction.updated,
        entityLabel: client.name,
        message: 'Updated client ${client.name}.',
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setClientActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    final client = _findClient(id);
    try {
      await _service.setClientActive(id, isActive);
      if (client != null) {
        await _addLog(
          officeId: client.officeId,
          action:
              isActive ? ActivityAction.activated : ActivityAction.cancelled,
          entityLabel: client.name,
          message: isActive
              ? 'Reactivated client ${client.name}.'
              : 'Deactivated client ${client.name}.',
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
    final user = _ref.read(currentUserProvider);
    try {
      await _ref.read(activityLogServiceProvider).addLog(
            officeId: officeId,
            actorName: user?.name ?? 'System',
            action: action,
            entityType: 'Client',
            entityLabel: entityLabel,
            message: message,
          );
    } catch (_) {
      // Logging must not make the main client action fail.
    }
  }
}

final clientControllerProvider =
    StateNotifierProvider<ClientController, AsyncValue<void>>((ref) {
  return ClientController(ref, ref.watch(clientServiceProvider));
});
