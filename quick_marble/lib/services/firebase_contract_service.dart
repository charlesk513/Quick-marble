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
  Stream<List<Contract>> watchContracts({
    String? officeId,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (officeId != null && officeId.trim().isNotEmpty) {
      query = query.where(
        'officeId',
        isEqualTo: officeId.trim(),
      );
    }

    query = query.orderBy(
      'updatedAt',
      descending: true,
    );

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (document) => Contract.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<Contract> createFromQuotation(Quotation quotation) async {
    final existing = await _collection
        .where('officeId', isEqualTo: quotation.officeId)
        .where('quotationId', isEqualTo: quotation.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final document = existing.docs.first;
      return Contract.fromMap(
        document.id,
        document.data(),
      );
    }

    final now = DateTime.now();

    final sequence = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      final current = (snapshot.data()?['lastSequence'] as num?)?.toInt() ?? 0;
      final next = current + 1;

      transaction.set(
        _counterDoc,
        {
          'lastSequence': next,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return next;
    });

    final document = _collection.doc();

    final contract = Contract(
      id: document.id,
      number: 'QMC-${now.year}-${sequence.toString().padLeft(6, '0')}',
      quotationId: quotation.id,
      quotationNumber: quotation.number,
      officeId: quotation.officeId,
      clientName: quotation.clientName,
      value: quotation.total,
      amountPaid: 0,
      documentName: '',
      documentUrl: '',
      documentStoragePath: '',
      notes: '',
      status: ContractStatus.pending,
      startDate: now,
      completionDate: null,
      createdAt: now,
      updatedAt: now,
      payments: const [],
    );

    await document.set(contract.toMap());
    return contract;
  }

  @override
  Future<void> updateContract(Contract contract) async {
    final updated = contract.copyWith(
      updatedAt: DateTime.now(),
    );

    await _collection.doc(contract.id).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateStatus(
    String contractId,
    ContractStatus status,
  ) async {
    await _collection.doc(contractId).update({
      'status': status.name,
      'completionDate': status == ContractStatus.completed
          ? FieldValue.serverTimestamp()
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
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
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be greater than zero.',
      );
    }

    final document = _collection.doc(contractId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Contract not found.');
      }

      final contract = Contract.fromMap(
        snapshot.id,
        snapshot.data()!,
      );

      if (amount > contract.balance) {
        throw StateError(
          'Payment cannot exceed the outstanding balance.',
        );
      }

      final payment = ContractPayment(
        id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
        amount: amount,
        method: method,
        reference: reference.trim(),
        notes: notes.trim(),
        paidAt: paidAt,
      );

      final updated = contract.copyWith(
        payments: [payment, ...contract.payments],
        updatedAt: DateTime.now(),
      );

      transaction.set(
        document,
        updated.toMap(),
        SetOptions(merge: true),
      );
    });
  }
}
