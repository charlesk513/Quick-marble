import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contract.dart';
import '../models/quotation.dart';
import 'contract_service.dart';

class FirebaseContractService implements ContractService {
  final FirebaseFirestore _firestore;

  FirebaseContractService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('contracts');

  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firestore.collection('counters').doc('contracts');

  @override
  Stream<List<Contract>> watchContracts() {
    return _collection.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Contract.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Contract> createFromQuotation(Quotation quotation) async {
    final existing = await _collection
        .where('quotationId', isEqualTo: quotation.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      return Contract.fromMap(doc.id, doc.data());
    }

    final now = DateTime.now();

    final sequence = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      final current = (snapshot.data()?['lastSequence'] as num?)?.toInt() ?? 0;
      final next = current + 1;

      transaction.set(
        _counterDoc,
        {'lastSequence': next},
        SetOptions(merge: true),
      );

      return next;
    });

    final doc = _collection.doc();

    final contract = Contract(
      id: doc.id,
      number: 'QMC-${now.year}-${sequence.toString().padLeft(6, '0')}',
      quotationId: quotation.id,
      quotationNumber: quotation.number,
      officeId: quotation.officeId,
      clientName: quotation.clientName,
      value: quotation.total,
      amountPaid: 0,
      documentName: '',
      notes: '',
      status: ContractStatus.pending,
      startDate: now,
      completionDate: null,
      createdAt: now,
      updatedAt: now,
      payments: const [],
    );

    await doc.set(contract.toMap());

    return contract;
  }

  @override
  Future<void> updateContract(Contract contract) async {
    await _collection.doc(contract.id).update(
          contract.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  @override
  Future<void> updateStatus(String contractId, ContractStatus status) async {
    await _collection.doc(contractId).update({
      'status': status.name,
      'completionDate': status == ContractStatus.completed
          ? DateTime.now().toIso8601String()
          : null,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addPayment({
    required String contractId,
    required double amount,
    required PaymentMethod method,
    required String reference,
    required String notes,
    required DateTime paidAt,
  }) async {
    final doc = _collection.doc(contractId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data() == null) return;

    final contract = Contract.fromMap(snapshot.id, snapshot.data()!);

    final payment = ContractPayment(
      id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      method: method,
      reference: reference,
      notes: notes,
      paidAt: paidAt,
    );

    final updated = contract.copyWith(
      payments: [payment, ...contract.payments],
      updatedAt: DateTime.now(),
    );

    await doc.update(updated.toMap());
  }
}
