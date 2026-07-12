import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/activity_log.dart';
import '../../models/contract.dart';
import '../../models/project_timeline.dart';
import '../../providers/activity_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/project_timeline_provider.dart';
import '../../routes/app_router.dart';
import '../../services/contract_pdf_service.dart';
import '../../services/contract_storage_service.dart';
import '../../services/delivery_note_pdf_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../services/receipt_pdf_service.dart';
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
                    const DropdownMenuItem<ContractStatus?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...ContractStatus.values.map(
                      (status) => DropdownMenuItem<ContractStatus?>(
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
    final notes = TextEditingController(text: contract.notes);
    final storageService = ContractStorageService();

    String documentNameValue = contract.documentName;
    String documentUrlValue = contract.documentUrl;
    String documentStoragePathValue = contract.documentStoragePath;
    final originalDocumentStoragePath = contract.documentStoragePath;

    bool isUploading = false;
    bool isSaving = false;

    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
              builder: (context, setModalState) => Padding(
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
                            if (amount == null || amount < 0) {
                              return 'Invalid amount';
                            }
                            if (amount > contract.value) {
                              return 'Cannot exceed contract value';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (documentNameValue.isNotEmpty)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: Text(documentNameValue),
                              subtitle:
                                  const Text('Uploaded contract document'),
                              trailing: documentUrlValue.isEmpty
                                  ? const Icon(Icons.cloud_done_outlined)
                                  : IconButton(
                                      tooltip: 'Open document',
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () async {
                                        final uri =
                                            Uri.tryParse(documentUrlValue);

                                        if (uri == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Invalid document link.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final opened = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );

                                        if (!opened && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not open the document.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                            ),
                          )
                        else
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No contract document uploaded.'),
                          ),
                        const SizedBox(height: 10),
                        if (documentNameValue.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: isUploading || isSaving
                                  ? null
                                  : () {
                                      setModalState(() {
                                        documentNameValue = '';
                                        documentUrlValue = '';
                                        documentStoragePathValue = '';
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text(
                                'Remove Document from Contract',
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    setModalState(() => isUploading = true);

                                    try {
                                      final uploaded =
                                          await storageService.pickAndUpload(
                                        contractId: contract.id,
                                      );

                                      if (uploaded == null) return;

                                      setModalState(() {
                                        documentNameValue = uploaded.name;
                                        documentUrlValue = uploaded.downloadUrl;
                                        documentStoragePathValue =
                                            uploaded.storagePath;
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Document uploaded successfully.'),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Upload failed: $error'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setModalState(
                                            () => isUploading = false);
                                      }
                                    }
                                  },
                            icon: isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              isUploading
                                  ? 'Uploading...'
                                  : documentNameValue.isEmpty
                                      ? 'Choose & Upload Document'
                                      : 'Replace Document',
                            ),
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
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save Contract Details',
                            ),
                            onPressed: isSaving || isUploading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setModalState(() => isSaving = true);

                                    try {
                                      final updated = contract.copyWith(
                                        amountPaid: double.parse(
                                            amountPaid.text.trim()),
                                        documentName: documentNameValue,
                                        documentUrl: documentUrlValue,
                                        documentStoragePath:
                                            documentStoragePathValue,
                                        notes: notes.text.trim(),
                                        updatedAt: DateTime.now(),
                                      );

                                      await ref
                                          .read(contractControllerProvider
                                              .notifier)
                                          .updateContract(updated);

                                      final oldDocumentMustBeDeleted =
                                          originalDocumentStoragePath
                                                  .isNotEmpty &&
                                              originalDocumentStoragePath !=
                                                  documentStoragePathValue;

                                      if (oldDocumentMustBeDeleted) {
                                        try {
                                          await storageService.deleteByPath(
                                            originalDocumentStoragePath,
                                          );
                                        } catch (error) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Contract saved, but the previous file could not be removed: $error',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Contract details saved successfully.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not save contract: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setModalState(() => isSaving = false);
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
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
    final pdfService = ContractPdfService();
    final receiptPdfService = ReceiptPdfService();
    final invoicePdfService = InvoicePdfService();
    final deliveryNotePdfService = DeliveryNotePdfService();
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
            _AmountRow(label: 'Paid', value: contract.totalPaid),
            _AmountRow(
              label: 'Balance',
              value: contract.balance,
              bold: true,
            ),
            if (contract.documentName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(contract.documentName),
                  subtitle: const Text('Uploaded contract document'),
                  trailing: contract.documentUrl.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Open document',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final uri = Uri.tryParse(contract.documentUrl);

                            if (uri == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid document link.'),
                                ),
                              );
                              return;
                            }

                            final opened = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );

                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open the document.'),
                                ),
                              );
                            }
                          },
                        ),
                ),
              ),
            ],
            if (contract.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(contract.notes),
            ],
            if (contract.payments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...contract.payments.map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${payment.method.label}'
                          '${payment.reference.isNotEmpty ? ' · ${payment.reference}' : ''}',
                        ),
                      ),
                      MoneyText(
                        payment.amount,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Receipt PDF',
                        icon: const Icon(Icons.receipt_long_outlined),
                        onPressed: () async {
                          await receiptPdfService.printReceipt(
                            contract: contract,
                            payment: payment,
                          );
                          await _addContractActivity(
                            ref,
                            contract: contract,
                            action: ActivityAction.generated,
                            message:
                                'Payment receipt generated for ${contract.number}.',
                          );

                          await ref
                              .read(projectTimelineControllerProvider.notifier)
                              .addEvent(
                                contractId: contract.id,
                                type: ProjectTimelineType.receiptGenerated,
                                title: 'Receipt Generated',
                                description:
                                    'Receipt generated for payment of UGX ${payment.amount.toStringAsFixed(0)}.',
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await pdfService.printContract(contract: contract);
                    await _addContractActivity(
                      ref,
                      contract: contract,
                      action: ActivityAction.generated,
                      message: 'Contract PDF generated for ${contract.number}.',
                    );

                    await ref
                        .read(projectTimelineControllerProvider.notifier)
                        .addEvent(
                          contractId: contract.id,
                          type: ProjectTimelineType.contractCreated,
                          title: 'Contract PDF Generated',
                          description:
                              'Contract PDF generated for ${contract.number}.',
                        );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await invoicePdfService.printInvoice(contract: contract);
                    await _addContractActivity(
                      ref,
                      contract: contract,
                      action: ActivityAction.generated,
                      message: 'Invoice generated for ${contract.number}.',
                    );

                    await ref
                        .read(projectTimelineControllerProvider.notifier)
                        .addEvent(
                          contractId: contract.id,
                          type: ProjectTimelineType.invoiceGenerated,
                          title: 'Invoice Generated',
                          description:
                              'Invoice generated for ${contract.number}.',
                        );
                  },
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Invoice'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await deliveryNotePdfService.printDeliveryNote(
                      contract: contract,
                    );
                    await _addContractActivity(
                      ref,
                      contract: contract,
                      action: ActivityAction.generated,
                      message:
                          'Delivery note generated for ${contract.number}.',
                    );

                    await ref
                        .read(projectTimelineControllerProvider.notifier)
                        .addEvent(
                          contractId: contract.id,
                          type: ProjectTimelineType.deliveryNoteGenerated,
                          title: 'Delivery Note Generated',
                          description:
                              'Delivery note generated for ${contract.number}.',
                        );
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Delivery'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(context, ref, contract),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Add Payment'),
                ),
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

Future<void> _addContractActivity(
  WidgetRef ref, {
  required Contract contract,
  required ActivityAction action,
  required String message,
}) async {
  final user = ref.read(currentUserProvider);
  try {
    await ref.read(activityLogServiceProvider).addLog(
          officeId: contract.officeId,
          actorName: user?.name ?? 'System',
          action: action,
          entityType: 'Contract',
          entityLabel: contract.number,
          message: message,
        );
  } catch (_) {
    // Do not fail the main document action if audit logging fails.
  }
}

Future<void> _showPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  Contract contract,
) async {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final reference = TextEditingController();
  final notes = TextEditingController();
  PaymentMethod method = PaymentMethod.cash;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Add Payment - ${contract.number}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Balance: ${formatUgx(contract.balance)}'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'UGX ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) return 'Invalid amount';
                    if (parsed > contract.balance) {
                      return 'Cannot exceed balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: method,
                  decoration:
                      const InputDecoration(labelText: 'Payment method'),
                  items: PaymentMethod.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => method = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reference,
                  decoration: const InputDecoration(
                    labelText: 'Reference optional',
                  ),
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

              await ref.read(contractControllerProvider.notifier).addPayment(
                    contractId: contract.id,
                    amount: double.parse(amount.text.trim()),
                    method: method,
                    reference: reference.text.trim(),
                    notes: notes.text.trim(),
                    paidAt: DateTime.now(),
                  );

              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save Payment'),
          ),
        ],
      ),
    ),
  );
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
