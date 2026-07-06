import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/quotation.dart';
import 'client_provider.dart';
import 'contract_provider.dart';
import 'office_provider.dart';
import 'quotation_provider.dart';

class DashboardStats {
  final int clients;
  final int quotations;
  final int pendingQuotations;
  final int approvedQuotations;
  final int contracts;
  final int activeContracts;
  final int completedContracts;
  final double quotationValue;
  final double contractValue;
  final double paidValue;
  final double outstandingBalance;

  const DashboardStats({
    required this.clients,
    required this.quotations,
    required this.pendingQuotations,
    required this.approvedQuotations,
    required this.contracts,
    required this.activeContracts,
    required this.completedContracts,
    required this.quotationValue,
    required this.contractValue,
    required this.paidValue,
    required this.outstandingBalance,
  });
}

class OfficeDashboardStats {
  final String officeId;
  final String officeName;
  final DashboardStats stats;

  const OfficeDashboardStats({
    required this.officeId,
    required this.officeName,
    required this.stats,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final clients = ref.watch(visibleClientsProvider);
  final quotations = ref.watch(visibleQuotationsProvider);
  final contracts = ref.watch(visibleContractsProvider);

  return _buildStats(clients, quotations, contracts);
});

final officeDashboardStatsProvider =
    Provider<List<OfficeDashboardStats>>((ref) {
  final offices = ref.watch(activeOfficesProvider);
  final clients = ref.watch(visibleClientsProvider);
  final quotations = ref.watch(visibleQuotationsProvider);
  final contracts = ref.watch(visibleContractsProvider);

  return offices.map((office) {
    return OfficeDashboardStats(
      officeId: office.id,
      officeName: office.name,
      stats: _buildStats(
        clients.where((client) => client.officeId == office.id).toList(),
        quotations.where((quote) => quote.officeId == office.id).toList(),
        contracts.where((contract) => contract.officeId == office.id).toList(),
      ),
    );
  }).toList();
});

DashboardStats _buildStats(
  List<dynamic> clients,
  List<Quotation> quotations,
  List<Contract> contracts,
) {
  return DashboardStats(
    clients: clients.length,
    quotations: quotations.length,
    pendingQuotations: quotations
        .where((q) => q.status == QuotationStatus.pendingApproval)
        .length,
    approvedQuotations:
        quotations.where((q) => q.status == QuotationStatus.approved).length,
    contracts: contracts.length,
    activeContracts:
        contracts.where((c) => c.status == ContractStatus.active).length,
    completedContracts:
        contracts.where((c) => c.status == ContractStatus.completed).length,
    quotationValue: quotations.fold<double>(0, (sum, q) => sum + q.total),
    contractValue: contracts.fold<double>(0, (sum, c) => sum + c.value),
    paidValue: contracts.fold<double>(0, (sum, c) => sum + c.amountPaid),
    outstandingBalance: contracts.fold<double>(0, (sum, c) => sum + c.balance),
  );
}
