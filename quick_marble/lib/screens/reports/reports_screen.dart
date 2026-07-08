import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/contract_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/app_router.dart';
import '../shared/money_text.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final contracts = ref.watch(visibleContractsProvider);

    final activeProjects =
        contracts.where((contract) => !contract.isPaidFully).length;

    final completedProjects =
        contracts.where((contract) => contract.isPaidFully).length;

    final paidAmount =
        contracts.fold<double>(0, (sum, contract) => sum + contract.totalPaid);

    final outstandingAmount =
        contracts.fold<double>(0, (sum, contract) => sum + contract.balance);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Business Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _ReportRow(label: 'Clients', value: stats.clients.toString()),
          _ReportRow(label: 'Quotations', value: stats.quotations.toString()),
          _ReportRow(
            label: 'Pending quotations',
            value: stats.pendingQuotations.toString(),
          ),
          _ReportRow(
            label: 'Approved quotations',
            value: stats.approvedQuotations.toString(),
          ),
          _ReportRow(label: 'Contracts', value: stats.contracts.toString()),
          _ReportRow(
            label: 'Active projects',
            value: activeProjects.toString(),
          ),
          _ReportRow(
            label: 'Completed projects',
            value: completedProjects.toString(),
          ),
          const SizedBox(height: 12),
          _MoneyReportRow(
            label: 'Quotation value',
            amount: stats.quotationValue,
          ),
          _MoneyReportRow(
            label: 'Contract value',
            amount: stats.contractValue,
          ),
          _MoneyReportRow(
            label: 'Paid amount',
            amount: paidAmount,
          ),
          _MoneyReportRow(
            label: 'Outstanding balance',
            amount: outstandingAmount,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Business report PDF export coming next.'),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export Business Report PDF'),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _MoneyReportRow extends StatelessWidget {
  final String label;
  final double amount;

  const _MoneyReportRow({
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: MoneyText(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
