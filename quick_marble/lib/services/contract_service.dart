import '../models/contract.dart';
import '../models/quotation.dart';

abstract class ContractService {
  Stream<List<Contract>> watchContracts({
    String? officeId,
  });

  Future<Contract> createFromQuotation(Quotation quotation);

  Future<void> updateContract(Contract contract);

  Future<void> updateStatus(
    String contractId,
    ContractStatus status,
  );

  Future<void> addPayment({
    required String contractId,
    required double amount,
    required PaymentMethod method,
    required String reference,
    required String notes,
    required DateTime paidAt,
  });
}
