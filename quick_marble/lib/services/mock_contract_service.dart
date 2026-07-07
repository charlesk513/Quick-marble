import 'dart:async';

import '../models/contract.dart';
import '../models/quotation.dart';
import 'contract_service.dart';

class MockContractService implements ContractService {
  final _controller = StreamController<List<Contract>>.broadcast();

  int _lastSequence = 1;

  final List<Contract> _contracts = [
    Contract(
      payments: const [],
      amountPaid: 0,
      documentName: '',
      notes: '',
      updatedAt: DateTime(2026, 7, 4),
      id: 'contract-1',
      number: 'QMC-2026-000001',
      quotationId: 'quote-1',
      quotationNumber: 'QM-2026-000001',
      officeId: 'nansana',
      clientName: 'Mugisha Apartments',
      value: 3068000,
      status: ContractStatus.active,
      startDate: DateTime(2026, 7, 4),
      completionDate: null,
      createdAt: DateTime(2026, 7, 4),
    ),
  ];

  @override
  Stream<List<Contract>> watchContracts() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<Contract> createFromQuotation(Quotation quotation) async {
    final existing =
        _contracts.where((c) => c.quotationId == quotation.id).toList();

    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();

    _lastSequence++;

    final contract = Contract(
      payments: const [],
      id: 'contract-${now.microsecondsSinceEpoch}',
      number: 'QMC-${now.year}-${_lastSequence.toString().padLeft(6, '0')}',
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
    );

    _contracts.insert(0, contract);
    _emit();

    return contract;
  }

  @override
  Future<void> updateContract(Contract contract) async {
    final index = _contracts.indexWhere((item) => item.id == contract.id);

    if (index == -1) return;

    _contracts[index] = contract.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> updateStatus(String contractId, ContractStatus status) async {
    final index = _contracts.indexWhere((item) => item.id == contractId);

    if (index == -1) return;

    _contracts[index] = _contracts[index].copyWith(
      status: status,
      completionDate:
          status == ContractStatus.completed ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    _emit();
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
    final index = _contracts.indexWhere((item) => item.id == contractId);

    if (index == -1) return;

    final contract = _contracts[index];

    final payment = ContractPayment(
      id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      method: method,
      reference: reference,
      notes: notes,
      paidAt: paidAt,
    );

    _contracts[index] = contract.copyWith(
      payments: [payment, ...contract.payments],
      updatedAt: DateTime.now(),
    );

    _emit();
  }

  void _emit() {
    final copy = [..._contracts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _controller.add(List.unmodifiable(copy));
  }
}
