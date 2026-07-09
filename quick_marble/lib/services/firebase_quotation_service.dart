import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quotation.dart';
import 'quotation_service.dart';

class FirebaseQuotationService implements QuotationService {
  final FirebaseFirestore _firestore;

  FirebaseQuotationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('quotations');

  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firestore.collection('counters').doc('quotations');

  @override
  Stream<List<Quotation>> watchQuotations() {
    return _collection.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Quotation.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Quotation> createQuotation({
    required String officeId,
    required String clientId,
    required String clientName,
    required List<QuotationItem> items,
    required String notes,
  }) async {
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

    final quotation = Quotation(
      id: doc.id,
      number: 'QM-${now.year}-${sequence.toString().padLeft(6, '0')}',
      officeId: officeId,
      clientId: clientId,
      clientName: clientName,
      items: items,
      status: QuotationStatus.draft,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(quotation.toMap());

    return quotation;
  }

  @override
  Future<void> updateQuotation(Quotation quotation) async {
    await _collection.doc(quotation.id).update(
          quotation.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  @override
  Future<void> updateStatus(String quotationId, QuotationStatus status) async {
    await _collection.doc(quotationId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
