import 'dart:async';

import '../models/client.dart';
import 'client_service.dart';

class MockClientService implements ClientService {
  final _controller = StreamController<List<Client>>.broadcast();
  final List<Client> _clients = [
    Client(
      id: 'client-1',
      officeId: 'nansana',
      name: 'Mugisha Apartments',
      phone: '+256700111222',
      email: 'mugisha@example.com',
      address: 'Nansana',
      notes: 'Interested in black galaxy kitchen tops.',
      isActive: true,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    ),
    Client(
      id: 'client-2',
      officeId: 'kajjansi',
      name: 'Kajjansi Homes Ltd',
      phone: '+256701333444',
      email: '',
      address: 'Kajjansi',
      notes: 'Needs quotation for reception counter.',
      isActive: true,
      createdAt: DateTime(2026, 7, 2),
      updatedAt: DateTime(2026, 7, 2),
    ),
  ];

  @override
  Stream<List<Client>> watchClients({String? officeId}) {
    return _controller.stream.map((clients) {
      if (officeId == null || officeId.isEmpty) {
        return clients;
      }

      return clients.where((client) => client.officeId == officeId).toList();
    });
  }

  @override
  Future<Client> createClient({
    required String officeId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) async {
    final now = DateTime.now();
    final client = Client(
      id: 'client-${now.microsecondsSinceEpoch}',
      officeId: officeId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    _clients.insert(0, client);
    _emit();
    return client;
  }

  @override
  Future<void> updateClient(Client client) async {
    final index = _clients.indexWhere((item) => item.id == client.id);
    if (index == -1) return;
    _clients[index] = client.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> setClientActive(String clientId, bool isActive) async {
    final index = _clients.indexWhere((item) => item.id == clientId);
    if (index == -1) return;
    _clients[index] = _clients[index].copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void _emit() {
    final copy = [..._clients]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _controller.add(List.unmodifiable(copy));
  }
}
