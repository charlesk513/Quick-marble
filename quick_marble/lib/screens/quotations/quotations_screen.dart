import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/quotation.dart';
import '../../providers/client_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../widgets/empty_state.dart';
import '../shared/money_text.dart';

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotations = ref.watch(visibleQuotationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuotationSheet(context, ref),
        icon: const Icon(Icons.request_quote_outlined),
        label: const Text('New Quote'),
      ),
      body: quotations.isEmpty
          ? const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'No quotations yet',
              message:
                  'Create quotations with VAT, approval status and contract conversion.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: quotations.length,
              itemBuilder: (context, index) =>
                  _QuotationCard(quotation: quotations[index]),
            ),
    );
  }

  Future<void> _showQuotationSheet(BuildContext context, WidgetRef ref) async {
    final clients =
        ref.read(visibleClientsProvider).where((c) => c.isActive).toList();
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add a client first.')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    var client = clients.first;
    final description = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final unitPrice = TextEditingController();
    final notes = TextEditingController();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Quotation',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: client.id,
                    decoration: const InputDecoration(labelText: 'Client'),
                    items: clients
                        .map((item) => DropdownMenuItem(
                            value: item.id, child: Text(item.name)))
                        .toList(),
                    onChanged: (value) => setModalState(() =>
                        client = clients.firstWhere((c) => c.id == value)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: description,
                      decoration:
                          const InputDecoration(labelText: 'Item description'),
                      validator: _required),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              controller: quantity,
                              decoration:
                                  const InputDecoration(labelText: 'Qty'),
                              keyboardType: TextInputType.number,
                              validator: _required)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                              controller: unitPrice,
                              decoration: const InputDecoration(
                                  labelText: 'Unit price'),
                              keyboardType: TextInputType.number,
                              validator: _required)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: notes,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final item = QuotationItem(
                          description: description.text.trim(),
                          quantity: double.tryParse(quantity.text.trim()) ?? 1,
                          unitPrice:
                              double.tryParse(unitPrice.text.trim()) ?? 0,
                        );
                        await ref
                            .read(quotationControllerProvider.notifier)
                            .createQuotation(
                              officeId: client.officeId,
                              clientId: client.id,
                              clientName: client.name,
                              items: [item],
                              notes: notes.text.trim(),
                            );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Save Quotation'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}

class _QuotationCard extends ConsumerWidget {
  final Quotation quotation;
  const _QuotationCard({required this.quotation});

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
                    child: Text(quotation.number,
                        style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(quotation.status.label)),
              ],
            ),
            Text(quotation.clientName),
            const SizedBox(height: 8),
            ...quotation.items.map((item) => Text(
                '${item.description} · ${item.quantity} × ${formatUgx(item.unitPrice)}')),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total incl. VAT'),
                MoneyText(quotation.total,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (quotation.status == QuotationStatus.draft)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(quotationControllerProvider.notifier)
                        .updateStatus(
                            quotation.id, QuotationStatus.pendingApproval),
                    child: const Text('Submit'),
                  ),
                if (quotation.status == QuotationStatus.pendingApproval) ...[
                  OutlinedButton(
                    onPressed: () => ref
                        .read(quotationControllerProvider.notifier)
                        .updateStatus(quotation.id, QuotationStatus.approved),
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(quotationControllerProvider.notifier)
                        .updateStatus(quotation.id, QuotationStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ],
                if (quotation.status == QuotationStatus.approved)
                  ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(contractControllerProvider.notifier)
                          .createFromQuotation(quotation);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contract created.')));
                      }
                    },
                    child: const Text('Create Contract'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
