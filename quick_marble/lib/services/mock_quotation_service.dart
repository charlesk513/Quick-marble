import 'dart:async';

import '../models/quotation.dart';
import 'quotation_service.dart';

class MockQuotationService implements QuotationService {
  final _controller = StreamController<List<Quotation>>.broadcast();
  int _lastSequence = 2;

  final List<Quotation> _quotations = [
    Quotation(
      id: 'quote-1',
      number: 'QM-2026-000001',
      officeId: 'nansana',
      clientId: 'client-1',
      clientName: 'Mugisha Apartments',
      items: const [
        QuotationItem(
            description: 'Black galaxy granite countertop',
            quantity: 8,
            unitPrice: 280000),
        QuotationItem(
            description: 'Transport and installation',
            quantity: 1,
            unitPrice: 350000),
      ],
      status: QuotationStatus.approved,
      notes: 'Kitchen tops and sink opening.',
      createdAt: DateTime(2026, 7, 2),
      updatedAt: DateTime(2026, 7, 2),
    ),
    Quotation(
      id: 'quote-2',
      number: 'QM-2026-000002',
      officeId: 'kajjansi',
      clientId: 'client-2',
      clientName: 'Kajjansi Homes Ltd',
      items: const [
        QuotationItem(
            description: 'Reception counter marble finish',
            quantity: 1,
            unitPrice: 4500000),
      ],
      status: QuotationStatus.pendingApproval,
      notes: 'Awaiting manager approval.',
      createdAt: DateTime(2026, 7, 3),
      updatedAt: DateTime(2026, 7, 3),
    ),
  ];

  @override
  Stream<List<Quotation>> watchQuotations({String? officeId}) {
    return _controller.stream.map((quotations) {
      if (officeId == null || officeId.isEmpty) {
        return quotations;
      }

      return quotations
          .where((quotation) => quotation.officeId == officeId)
          .toList();
    });
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
    _lastSequence++;
    final quotation = Quotation(
      id: 'quote-${now.microsecondsSinceEpoch}',
      number: 'QM-${now.year}-${_lastSequence.toString().padLeft(6, '0')}',
      officeId: officeId,
      clientId: clientId,
      clientName: clientName,
      items: items,
      status: QuotationStatus.draft,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _quotations.insert(0, quotation);
    _emit();
    return quotation;
  }

  @override
  Future<void> updateQuotation(Quotation quotation) async {
    final index = _quotations.indexWhere((item) => item.id == quotation.id);
    if (index == -1) return;
    _quotations[index] = quotation.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> updateStatus(String quotationId, QuotationStatus status) async {
    final index = _quotations.indexWhere((item) => item.id == quotationId);
    if (index == -1) return;
    _quotations[index] =
        _quotations[index].copyWith(status: status, updatedAt: DateTime.now());
    _emit();
  }

  void _emit() {
    final copy = [..._quotations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _controller.add(List.unmodifiable(copy));
  }
}
