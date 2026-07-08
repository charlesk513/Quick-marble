import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/contract.dart';
import '../../models/job.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/project_timeline_provider.dart';
import '../../routes/app_router.dart';
import '../shared/money_text.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final String contractId;

  const ProjectDetailsScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsStreamProvider).valueOrNull ?? [];
    final contract =
        contracts.where((item) => item.id == contractId).firstOrNull;

    final jobs = ref
        .watch(jobsProvider)
        .where((job) => job.contractId == contractId)
        .toList()
      ..sort((a, b) => a.installationDate.compareTo(b.installationDate));

    final events = ref.watch(contractTimelineProvider(contractId));

    if (contract == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.projects),
          ),
          title: const Text('Project Details'),
        ),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.projects),
        ),
        title: Text(contract.clientName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleJobDialog(context, ref, contract),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Schedule Job'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          _ProjectSummary(contract: contract),
          const SizedBox(height: 16),
          Text('WORK SCHEDULE', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'No work has been scheduled yet. \nTap "Schedule Job" below to plan the installation.'),
              ),
            )
          else
            ...jobs.map((job) => _JobCard(job: job)),
          const SizedBox(height: 16),
          Text('Project Timeline',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No timeline events yet.'),
              ),
            )
          else
            ...events.map(
              (event) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.timeline_outlined),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.description}\n${DateFormat.yMMMd().add_jm().format(event.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  final Contract contract;

  const _ProjectSummary({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROJECT SUMMARY',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _InfoRow('Client', contract.clientName),
            _InfoRow('Contract', contract.number),
            _InfoRow('Quotation', contract.quotationNumber),
            _InfoRow('Status', contract.status.label),
            const SizedBox(height: 20),
            _MoneyLine(
              label: 'Contract Value',
              amount: contract.value,
            ),
            _MoneyLine(
              label: 'Paid',
              amount: contract.totalPaid,
            ),
            _MoneyLine(
              label: 'Outstanding Balance',
              amount: contract.balance,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(JobStatus status) {
  switch (status) {
    case JobStatus.scheduled:
      return Colors.blue;
    case JobStatus.inProgress:
      return Colors.orange;
    case JobStatus.completed:
      return Colors.green;
    case JobStatus.cancelled:
      return Colors.red;
    case JobStatus.postponed:
      return Colors.purple;
  }
}

class _JobCard extends ConsumerWidget {
  final Job job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat.yMMMd().format(job.installationDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  backgroundColor:
                      _statusColor(job.status).withValues(alpha: 0.15),
                  side: BorderSide.none,
                  label: Text(
                    job.status.label,
                    style: TextStyle(
                      color: _statusColor(job.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _JobInfoLine(
              icon: Icons.groups_outlined,
              text: job.installer,
            ),
            const SizedBox(height: 8),
            _JobInfoLine(
              icon: Icons.location_on_outlined,
              text: job.location,
            ),
            if (job.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _JobInfoLine(
                icon: Icons.sticky_note_2_outlined,
                text: job.notes,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditJobDialog(context, ref, job),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Update'),
                ),
                if (job.status != JobStatus.completed)
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(jobControllerProvider.notifier)
                        .updateStatus(job.id, JobStatus.completed),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JobInfoLine({
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

Future<void> _showScheduleJobDialog(
  BuildContext context,
  WidgetRef ref,
  Contract contract,
) async {
  final formKey = GlobalKey<FormState>();
  final installer = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  DateTime selectedDate = DateTime.now();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Schedule Job - ${contract.number}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Installation Date'),
                  subtitle: Text(selectedDate.toString().split(' ').first),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: installer,
                  decoration:
                      const InputDecoration(labelText: 'Installer / Team'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: location,
                  decoration:
                      const InputDecoration(labelText: 'Installation Location'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await ref.read(jobControllerProvider.notifier).createJob(
                    contract: contract,
                    installationDate: selectedDate,
                    installer: installer.text.trim(),
                    location: location.text.trim(),
                    notes: notes.text.trim(),
                  );

              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save Job'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showEditJobDialog(
  BuildContext context,
  WidgetRef ref,
  Job job,
) async {
  final formKey = GlobalKey<FormState>();
  final installer = TextEditingController(text: job.installer);
  final location = TextEditingController(text: job.location);
  final notes = TextEditingController(text: job.notes);
  DateTime selectedDate = job.installationDate;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Update Job - ${job.contractNumber}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Installation Date'),
                  subtitle: Text(selectedDate.toString().split(' ').first),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: installer,
                  decoration:
                      const InputDecoration(labelText: 'Installer / Team'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: location,
                  decoration:
                      const InputDecoration(labelText: 'Installation Location'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await ref.read(jobControllerProvider.notifier).updateJob(
                    job.copyWith(
                      installationDate: selectedDate,
                      installer: installer.text.trim(),
                      location: location.text.trim(),
                      notes: notes.text.trim(),
                    ),
                  );

              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save Job'),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow(
    this.title,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _MoneyLine({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          MoneyText(amount, style: style),
        ],
      ),
    );
  }
}
