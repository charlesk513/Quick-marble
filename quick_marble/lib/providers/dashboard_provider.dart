import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client.dart';
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
  return _buildStats(
    clients: ref.watch(visibleClientsProvider),
    quotations: ref.watch(visibleQuotationsProvider),
    contracts: ref.watch(visibleContractsProvider),
  );
});

final officeDashboardStatsProvider =
    Provider<List<OfficeDashboardStats>>((ref) {
  final offices = ref.watch(activeOfficesProvider);
  final clients = ref.watch(visibleClientsProvider);
  final quotations = ref.watch(visibleQuotationsProvider);
  final contracts = ref.watch(visibleContractsProvider);

  final result = offices.map((office) {
    return OfficeDashboardStats(
      officeId: office.id,
      officeName: office.name,
      stats: _buildStats(
        clients: clients.where((c) => c.officeId == office.id).toList(),
        quotations:
            quotations.where((q) => q.officeId == office.id).toList(),
        contracts:
            contracts.where((c) => c.officeId == office.id).toList(),
      ),
    );
  }).toList()
    ..sort((a, b) => a.officeName.compareTo(b.officeName));

  return result;
});

DashboardStats _buildStats({
  required List<Client> clients,
  required List<Quotation> quotations,
  required List<Contract> contracts,
}) {
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
    quotationValue:
        quotations.fold<double>(0, (sum, q) => sum + q.total),
    contractValue:
        contracts.fold<double>(0, (sum, c) => sum + c.value),
    paidValue:
        contracts.fold<double>(0, (sum, c) => sum + c.totalPaid),
    outstandingBalance:
        contracts.fold<double>(0, (sum, c) => sum + c.balance),
  );
}
