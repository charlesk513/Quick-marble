import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/project_timeline.dart';
import '../models/quotation.dart';
import '../providers/auth_provider.dart';
import '../providers/project_timeline_provider.dart';
import '../services/contract_service.dart';
import '../services/firebase_contract_service.dart';

final contractServiceProvider = Provider<ContractService>((ref) {
  return FirebaseContractService();
});

final contractsStreamProvider = StreamProvider<List<Contract>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) {
    return Stream.value(const <Contract>[]);
  }

  final officeId = user.isAdministrator ? null : user.assignedOfficeId;

  if (!user.isAdministrator && (officeId == null || officeId.trim().isEmpty)) {
    return Stream.value(const <Contract>[]);
  }

  return ref.watch(contractServiceProvider).watchContracts(
        officeId: officeId,
      );
});

final visibleContractsProvider = Provider<List<Contract>>((ref) {
  return ref.watch(contractsStreamProvider).valueOrNull ?? const <Contract>[];
});

class ContractController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ContractService _service;

  ContractController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  Future<void> createFromQuotation(Quotation quotation) async {
    state = const AsyncValue.loading();

    try {
      final contract = await _service.createFromQuotation(quotation);

      await _ref.read(projectTimelineControllerProvider.notifier).addEvent(
            contractId: contract.id,
            type: ProjectTimelineType.contractCreated,
            title: 'Contract Created',
            description:
                'Contract ${contract.number} created from ${quotation.number}.',
          );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateContract(Contract contract) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateContract(contract);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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

      await _ref.read(projectTimelineControllerProvider.notifier).addEvent(
            contractId: contractId,
            type: ProjectTimelineType.paymentReceived,
            title: 'Payment Received',
            description:
                'Payment of UGX ${amount.toStringAsFixed(0)} received via ${method.label}.',
          );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus(
    String id,
    ContractStatus status,
  ) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final contractControllerProvider =
    StateNotifierProvider<ContractController, AsyncValue<void>>((ref) {
  return ContractController(
    ref,
    ref.watch(contractServiceProvider),
  );
});
