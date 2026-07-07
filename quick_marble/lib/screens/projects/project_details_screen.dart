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
          Text('Jobs / Installation Tasks',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No jobs scheduled for this project yet.'),
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
    final progress =
        contract.value <= 0 ? 0.0 : contract.totalPaid / contract.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contract.number,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(contract.clientName),
            Text('Quotation: ${contract.quotationNumber}'),
            Text('Status: ${contract.status.label}'),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 10),
            _MoneyLine(label: 'Contract value', amount: contract.value),
            _MoneyLine(label: 'Paid', amount: contract.totalPaid),
            _MoneyLine(label: 'Balance', amount: contract.balance, bold: true),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final Job job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.engineering_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat.yMMMd().format(job.installationDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(job.status.label)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Team: ${job.installer}'),
            Text('Location: ${job.location}'),
            if (job.notes.isNotEmpty) Text('Notes: ${job.notes}'),
            const SizedBox(height: 10),
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
