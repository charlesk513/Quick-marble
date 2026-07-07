import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/quotation.dart';
import '../providers/auth_provider.dart';
import '../services/contract_service.dart';
import '../services/mock_contract_service.dart';

final contractServiceProvider = Provider<ContractService>((ref) {
  return MockContractService();
});

final contractsStreamProvider = StreamProvider<List<Contract>>((ref) {
  return ref.watch(contractServiceProvider).watchContracts();
});

final visibleContractsProvider = Provider<List<Contract>>((ref) {
  final user = ref.watch(currentUserProvider);
  final contracts = ref.watch(contractsStreamProvider).valueOrNull ?? [];

  if (user == null) return [];
  if (user.isAdministrator) return contracts;

  return contracts.where((c) => c.officeId == user.assignedOfficeId).toList();
});

class ContractController extends StateNotifier<AsyncValue<void>> {
  final ContractService _service;

  ContractController(this._service) : super(const AsyncValue.data(null));

  Future<void> createFromQuotation(Quotation quotation) async {
    state = const AsyncValue.loading();
    try {
      await _service.createFromQuotation(quotation);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateContract(Contract contract) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateContract(contract);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addPayment({
    required String contractId,
    required double amount,
    required PaymentMethod method,
    required String reference,
    required String notes,
    required DateTime paidAt,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.addPayment(
        contractId: contractId,
        amount: amount,
        method: method,
        reference: reference,
        notes: notes,
        paidAt: paidAt,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, ContractStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final contractControllerProvider =
    StateNotifierProvider<ContractController, AsyncValue<void>>((ref) {
  return ContractController(ref.watch(contractServiceProvider));
});
