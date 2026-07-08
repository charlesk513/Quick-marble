import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../providers/contract_provider.dart';
import '../../routes/app_router.dart';
import '../shared/money_text.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _query = '';
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final contracts = ref.watch(visibleContractsProvider);

    final filtered = contracts.where((contract) {
      final searchable =
          '${contract.number} ${contract.clientName} ${contract.quotationNumber} ${contract.notes}'
              .toLowerCase();

      final matchesSearch = searchable.contains(_query.toLowerCase());

      final completed = contract.status == ContractStatus.completed;
      final matchesTab = _showCompleted ? completed : !completed;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Projects'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search project, client, contract',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  selected: {_showCompleted},
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Active'),
                      icon: Icon(Icons.work_outline),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Completed'),
                      icon: Icon(Icons.verified_outlined),
                    ),
                  ],
                  onSelectionChanged: (value) {
                    setState(() => _showCompleted = value.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _showCompleted
                          ? 'No completed projects yet.'
                          : 'No active projects yet.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contract = filtered[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.work_outline),
                          ),
                          title: Text(contract.clientName),
                          subtitle: Text(
                            '${contract.number}\n'
                            'Quotation: ${contract.quotationNumber}\n'
                            'Status: ${contract.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              MoneyText(
                                contract.balance,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Balance'),
                            ],
                          ),
                          onTap: () => context.push('/project/${contract.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
