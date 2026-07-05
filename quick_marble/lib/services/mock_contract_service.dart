import 'dart:async';
import '../models/contract.dart';
import '../models/quotation.dart';
import 'contract_service.dart';

class MockContractService implements ContractService {
  final _controller = StreamController<List<Contract>>.broadcast();
  int _lastSequence = 1;
  final List<Contract> _contracts = [
    Contract(
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
    final existing = _contracts.where((c) => c.quotationId == quotation.id).toList();
    if (existing.isNotEmpty) return existing.first;
    final now = DateTime.now();
    _lastSequence++;
    final contract = Contract(
      id: 'contract-${now.microsecondsSinceEpoch}',
      number: 'QMC-${now.year}-${_lastSequence.toString().padLeft(6, '0')}',
      quotationId: quotation.id,
      quotationNumber: quotation.number,
      officeId: quotation.officeId,
      clientName: quotation.clientName,
      value: quotation.total,
      status: ContractStatus.pending,
      startDate: now,
      completionDate: null,
      createdAt: now,
    );
    _contracts.insert(0, contract);
    _emit();
    return contract;
  }

  @override
  Future<void> updateStatus(String contractId, ContractStatus status) async {
    final index = _contracts.indexWhere((item) => item.id == contractId);
    if (index == -1) return;
    _contracts[index] = _contracts[index].copyWith(
      status: status,
      completionDate: status == ContractStatus.completed ? DateTime.now() : null,
    );
    _emit();
  }

  void _emit() {
    final copy = [..._contracts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(List.unmodifiable(copy));
  }
}
