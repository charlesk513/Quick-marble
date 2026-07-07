import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../providers/contract_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';
import '../shared/money_text.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  String _query = '';
  ContractStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final contracts = ref.watch(visibleContractsProvider);

    final filtered = contracts.where((contract) {
      final text =
          '${contract.number} ${contract.clientName} ${contract.quotationNumber} ${contract.notes} ${contract.documentName}'
              .toLowerCase();
      final matchesSearch = text.contains(_query.toLowerCase());
      final matchesStatus =
          _statusFilter == null || contract.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final activeCount =
        contracts.where((c) => c.status == ContractStatus.active).length;
    final completedCount =
        contracts.where((c) => c.status == ContractStatus.completed).length;
    final totalValue = contracts.fold<double>(0, (sum, c) => sum + c.value);
    final totalBalance = contracts.fold<double>(0, (sum, c) => sum + c.balance);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Contracts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ContractStatCard(
                        title: 'Active',
                        value: activeCount.toString(),
                        icon: Icons.assignment_turned_in_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ContractStatCard(
                        title: 'Done',
                        value: completedCount.toString(),
                        icon: Icons.verified_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MoneyStatCard(
                        title: 'Value',
                        amount: totalValue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MoneyStatCard(
                        title: 'Balance',
                        amount: totalBalance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search contract, client, quotation',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ContractStatus?>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...ContractStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No contracts found',
                    message:
                        'Approve a quotation, create a contract, or change filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _ContractCard(
                      contract: filtered[index],
                      onEdit: () =>
                          _showContractSheet(context, filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContractSheet(
    BuildContext context,
    Contract contract,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amountPaid =
        TextEditingController(text: contract.amountPaid.toStringAsFixed(0));
    final documentName = TextEditingController(text: contract.documentName);
    final notes = TextEditingController(text: contract.notes);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update ${contract.number}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountPaid,
                  decoration: const InputDecoration(
                    labelText: 'Amount paid',
                    prefixText: 'UGX ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount < 0) return 'Invalid amount';
                    if (amount > contract.value) {
                      return 'Cannot exceed contract value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: documentName,
                  decoration: const InputDecoration(
                    labelText: 'Document name / upload reference',
                    hintText: 'e.g. signed_contract_001.pdf',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Contract Details'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final updated = contract.copyWith(
                        amountPaid: double.parse(amountPaid.text.trim()),
                        documentName: documentName.text.trim(),
                        notes: notes.text.trim(),
                        updatedAt: DateTime.now(),
                      );

                      await ref
                          .read(contractControllerProvider.notifier)
                          .updateContract(updated);

                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractCard extends ConsumerWidget {
  final Contract contract;
  final VoidCallback onEdit;

  const _ContractCard({
    required this.contract,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.number,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(contract.status.label)),
              ],
            ),
            Text(
              contract.clientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('From ${contract.quotationNumber}'),
            const SizedBox(height: 8),
            _AmountRow(label: 'Contract value', value: contract.value),
            _AmountRow(label: 'Paid', value: contract.amountPaid),
            _AmountRow(
              label: 'Balance',
              value: contract.balance,
              bold: true,
            ),
            if (contract.documentName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Document: ${contract.documentName}'),
            ],
            if (contract.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(contract.notes),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Update'),
                ),
                if (contract.status == ContractStatus.pending)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(contractControllerProvider.notifier)
                        .updateStatus(contract.id, ContractStatus.active),
                    child: const Text('Activate'),
                  ),
                if (contract.status == ContractStatus.active)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(contractControllerProvider.notifier)
                        .updateStatus(contract.id, ContractStatus.completed),
                    child: const Text('Mark Complete'),
                  ),
                if (contract.status != ContractStatus.completed &&
                    contract.status != ContractStatus.cancelled)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(contractControllerProvider.notifier)
                        .updateStatus(contract.id, ContractStatus.cancelled),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ContractStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyStatCard extends StatelessWidget {
  final String title;
  final double amount;

  const _MoneyStatCard({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            MoneyText(
              amount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        MoneyText(value, style: style),
      ],
    );
  }
}
