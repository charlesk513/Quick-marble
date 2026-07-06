import '../models/contract.dart';
import '../models/quotation.dart';

abstract class ContractService {
  Stream<List<Contract>> watchContracts();
  Future<Contract> createFromQuotation(Quotation quotation);
  Future<void> updateContract(Contract contract);
  Future<void> updateStatus(String contractId, ContractStatus status);
}
