import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client.dart';
import 'client_service.dart';

class FirebaseClientService implements ClientService {
  final FirebaseFirestore _firestore;

  FirebaseClientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('clients');

  @override
  Stream<List<Client>> watchClients() {
    return _collection.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Client.fromMap(doc.id, doc.data()))
              .toList(),
        );
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
    final doc = _collection.doc();

    final client = Client(
      id: doc.id,
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

    await doc.set(client.toMap());
    return client;
  }

  @override
  Future<void> updateClient(Client client) async {
    await _collection.doc(client.id).update(
          client.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  @override
  Future<void> setClientActive(String clientId, bool isActive) async {
    await _collection.doc(clientId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
