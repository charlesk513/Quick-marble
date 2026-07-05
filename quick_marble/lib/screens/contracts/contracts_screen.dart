import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contract.dart';
import '../../providers/contract_provider.dart';
import '../../widgets/empty_state.dart';
import '../shared/money_text.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(visibleContractsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Contracts')),
      body: contracts.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'No contracts yet',
              message: 'Approve a quotation, then create a contract from it.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              itemBuilder: (context, index) => _ContractCard(contract: contracts[index]),
            ),
    );
  }
}

class _ContractCard extends ConsumerWidget {
  final Contract contract;
  const _ContractCard({required this.contract});

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
                Expanded(child: Text(contract.number, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(contract.status.label)),
              ],
            ),
            Text(contract.clientName),
            Text('From ${contract.quotationNumber}'),
            const SizedBox(height: 8),
            MoneyText(contract.value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (contract.status == ContractStatus.pending)
                  OutlinedButton(
                    onPressed: () => ref.read(contractControllerProvider.notifier).updateStatus(contract.id, ContractStatus.active),
                    child: const Text('Activate'),
                  ),
                if (contract.status == ContractStatus.active)
                  OutlinedButton(
                    onPressed: () => ref.read(contractControllerProvider.notifier).updateStatus(contract.id, ContractStatus.completed),
                    child: const Text('Mark Complete'),
                  ),
                if (contract.status != ContractStatus.completed && contract.status != ContractStatus.cancelled)
                  OutlinedButton(
                    onPressed: () => ref.read(contractControllerProvider.notifier).updateStatus(contract.id, ContractStatus.cancelled),
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
