import '../models/client.dart';

abstract class ClientService {
  Stream<List<Client>> watchClients();
  Future<Client> createClient({
    required String officeId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String notes,
  });
  Future<void> updateClient(Client client);
  Future<void> setClientActive(String clientId, bool isActive);
}
