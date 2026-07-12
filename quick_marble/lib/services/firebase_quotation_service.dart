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
  Stream<List<Quotation>> watchQuotations({String? officeId}) {
    Query<Map<String, dynamic>> query = _collection;

    if (officeId != null && officeId.trim().isNotEmpty) {
      query = query.where('officeId', isEqualTo: officeId.trim());
    }

    query = query.orderBy('updatedAt', descending: true);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Quotation.fromMap(doc.id, doc.data()))
              .toList(growable: false),
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
        {
          'lastSequence': next,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return next;
    });

    final doc = _collection.doc();

    final quotation = Quotation(
      id: doc.id,
      number: 'QM-${now.year}-${sequence.toString().padLeft(6, '0')}',
      officeId: officeId.trim(),
      clientId: clientId,
      clientName: clientName.trim(),
      items: items,
      status: QuotationStatus.draft,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(quotation.toMap());
    return quotation;
  }

  @override
  Future<void> updateQuotation(Quotation quotation) async {
    await _collection.doc(quotation.id).set(
          quotation.copyWith(updatedAt: DateTime.now()).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateStatus(
    String quotationId,
    QuotationStatus status,
  ) async {
    await _collection.doc(quotationId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
