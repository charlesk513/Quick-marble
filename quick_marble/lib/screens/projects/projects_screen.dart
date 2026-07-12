import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/contract.dart';
import '../../models/job.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
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
    final jobs = ref.watch(jobsProvider);

    final filtered = contracts.where((contract) {
      final contractJobs =
          jobs.where((job) => job.contractId == contract.id).toList();

      final searchable = [
        contract.number,
        contract.clientName,
        contract.quotationNumber,
        contract.notes,
        ...contractJobs.expand(
          (job) => [
            job.installer,
            job.location,
            job.status.label,
          ],
        ),
      ].join(' ').toLowerCase();

      final matchesSearch = searchable.contains(_query.trim().toLowerCase());

      final completed = contract.status == ContractStatus.completed;
      final matchesTab = _showCompleted ? completed : !completed;

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
                    hintText: 'Search project, client, installer, location',
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
                      final contractJobs = jobs
                          .where((job) => job.contractId == contract.id)
                          .toList()
                        ..sort(
                          (a, b) =>
                              a.installationDate.compareTo(b.installationDate),
                        );

                      final currentJob = _currentJob(contractJobs);

                      return _ProjectCard(
                        contract: contract,
                        currentJob: currentJob,
                        onTap: () => context.push('/project/${contract.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Job? _currentJob(List<Job> jobs) {
    if (jobs.isEmpty) return null;

    final active = jobs.where(
      (job) =>
          job.status != JobStatus.completed &&
          job.status != JobStatus.cancelled,
    );

    if (active.isNotEmpty) {
      return active.first;
    }

    return jobs.last;
  }
}

class _ProjectCard extends StatelessWidget {
  final Contract contract;
  final Job? currentJob;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.contract,
    required this.currentJob,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final job = currentJob;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.work_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.clientName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(contract.number),
                      ],
                    ),
                  ),
                  Chip(label: Text(contract.status.label)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.request_quote_outlined,
                text: 'Quotation: ${contract.quotationNumber}',
              ),
              if (job != null) ...[
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.calendar_month_outlined,
                  text:
                      'Installation: ${DateFormat.yMMMd().format(job.installationDate)}',
                ),
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.groups_outlined,
                  text: 'Team: ${job.installer}',
                ),
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: job.location,
                ),
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.flag_outlined,
                  text: 'Job status: ${job.status.label}',
                ),
              ] else ...[
                const SizedBox(height: 7),
                const _InfoLine(
                  icon: Icons.event_busy_outlined,
                  text: 'No job scheduled yet',
                ),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MoneySummary(
                      label: 'Paid',
                      amount: contract.totalPaid,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MoneySummary(
                      label: 'Balance',
                      amount: contract.balance,
                      bold: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _MoneySummary extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _MoneySummary({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 3),
        MoneyText(amount, style: style),
      ],
    );
  }
}
