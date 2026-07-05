import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contract.dart';
import '../models/quotation.dart';
import 'client_provider.dart';
import 'contract_provider.dart';
import 'quotation_provider.dart';

class DashboardStats {
  final int clients;
  final int quotations;
  final int pendingQuotations;
  final int approvedQuotations;
  final int contracts;
  final int completedContracts;
  final double quotationValue;
  final double contractValue;

  const DashboardStats({
    required this.clients,
    required this.quotations,
    required this.pendingQuotations,
    required this.approvedQuotations,
    required this.contracts,
    required this.completedContracts,
    required this.quotationValue,
    required this.contractValue,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final clients = ref.watch(visibleClientsProvider);
  final quotations = ref.watch(visibleQuotationsProvider);
  final contracts = ref.watch(visibleContractsProvider);
  return DashboardStats(
    clients: clients.length,
    quotations: quotations.length,
    pendingQuotations: quotations.where((q) => q.status == QuotationStatus.pendingApproval).length,
    approvedQuotations: quotations.where((q) => q.status == QuotationStatus.approved).length,
    contracts: contracts.length,
    completedContracts: contracts.where((c) => c.status == ContractStatus.completed).length,
    quotationValue: quotations.fold(0, (sum, q) => sum + q.total),
    contractValue: contracts.fold(0, (sum, c) => sum + c.value),
  );
});
