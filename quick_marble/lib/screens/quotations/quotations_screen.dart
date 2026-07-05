import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/quotation.dart';
import '../../providers/client_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../widgets/empty_state.dart';
import '../shared/money_text.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  String _query = '';
  QuotationStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final quotations = ref.watch(visibleQuotationsProvider);

    final filtered = quotations.where((q) {
      final text = '${q.number} ${q.clientName} ${q.notes}'
          .toLowerCase()
          .contains(_query.toLowerCase());

      final status = _statusFilter == null || q.status == _statusFilter;

      return text && status;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuotationSheet(context),
        icon: const Icon(Icons.request_quote_outlined),
        label: const Text('New Quote'),
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
                    hintText: 'Search quotation or client',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<QuotationStatus?>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...QuotationStatus.values.map(
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
                    icon: Icons.request_quote_outlined,
                    title: 'No quotations found',
                    message: 'Create a quotation or change your filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _QuotationCard(
                      quotation: filtered[index],
                      onEdit: () => _showQuotationSheet(context,
                          quotation: filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuotationSheet(
    BuildContext context, {
    Quotation? quotation,
  }) async {
    final clients =
        ref.read(visibleClientsProvider).where((c) => c.isActive).toList();

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client first.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    var client = quotation == null
        ? clients.first
        : clients.firstWhere(
            (c) => c.id == quotation.clientId,
            orElse: () => clients.first,
          );

    final notes = TextEditingController(text: quotation?.notes ?? '');

    final itemControllers = <_QuoteItemControllers>[
      if (quotation != null && quotation.items.isNotEmpty)
        ...quotation.items.map(_QuoteItemControllers.fromItem)
      else
        _QuoteItemControllers.empty(),
    ];

    double subtotal() => itemControllers.fold(
          0,
          (sum, item) =>
              sum +
              ((double.tryParse(item.quantity.text.trim()) ?? 0) *
                  (double.tryParse(item.unitPrice.text.trim()) ?? 0)),
        );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final sub = subtotal();
          final vat = sub * Quotation.vatRate;
          final total = sub + vat;

          return Padding(
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
                            quotation == null
                                ? 'New Quotation'
                                : 'Edit ${quotation.number}',
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
                    DropdownButtonFormField<String>(
                      initialValue: client.id,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Client'),
                      items: clients
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          client = clients.firstWhere((c) => c.id == value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ...itemControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Item ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (itemControllers.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setModalState(() {
                                          itemControllers.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              TextFormField(
                                controller: item.description,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.quantity,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: _positiveNumber,
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.unitPrice,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit price',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: _positiveNumber,
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            itemControllers.add(_QuoteItemControllers.empty());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notes,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _TotalsPreview(subtotal: sub, vat: vat, total: total),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          quotation == null
                              ? 'Save Quotation'
                              : 'Update Quotation',
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final items = itemControllers
                              .map(
                                (item) => QuotationItem(
                                  description: item.description.text.trim(),
                                  quantity: double.parse(
                                    item.quantity.text.trim(),
                                  ),
                                  unitPrice: double.parse(
                                    item.unitPrice.text.trim(),
                                  ),
                                ),
                              )
                              .toList();

                          final controller =
                              ref.read(quotationControllerProvider.notifier);

                          if (quotation == null) {
                            await controller.createQuotation(
                              officeId: client.officeId,
                              clientId: client.id,
                              clientName: client.name,
                              items: items,
                              notes: notes.text.trim(),
                            );
                          } else {
                            await controller.updateQuotation(
                              quotation.copyWith(
                                officeId: client.officeId,
                                clientId: client.id,
                                clientName: client.name,
                                items: items,
                                notes: notes.text.trim(),
                              ),
                            );
                          }

                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'Invalid';
    return null;
  }
}

class _QuotationCard extends ConsumerWidget {
  final Quotation quotation;
  final VoidCallback onEdit;

  const _QuotationCard({
    required this.quotation,
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
                    quotation.number,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(quotation.status.label)),
              ],
            ),
            Text(
              quotation.clientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...quotation.items.map(
              (item) => Text(
                '${item.description} · ${item.quantity} × ${formatUgx(item.unitPrice)}',
              ),
            ),
            const Divider(),
            _AmountRow(label: 'Subtotal', value: quotation.subtotal),
            _AmountRow(label: 'VAT 18%', value: quotation.vat),
            _AmountRow(
              label: 'Total',
              value: quotation.total,
              bold: true,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (quotation.status == QuotationStatus.draft)
                  OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                if (quotation.status == QuotationStatus.draft)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(quotationControllerProvider.notifier)
                        .updateStatus(
                          quotation.id,
                          QuotationStatus.pendingApproval,
                        ),
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
                          const SnackBar(content: Text('Contract created.')),
                        );
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

class _TotalsPreview extends StatelessWidget {
  final double subtotal;
  final double vat;
  final double total;

  const _TotalsPreview({
    required this.subtotal,
    required this.vat,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _AmountRow(label: 'Subtotal', value: subtotal),
            _AmountRow(label: 'VAT 18%', value: vat),
            _AmountRow(label: 'Total', value: total, bold: true),
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

class _QuoteItemControllers {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  _QuoteItemControllers({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  factory _QuoteItemControllers.empty() {
    return _QuoteItemControllers(
      description: TextEditingController(),
      quantity: TextEditingController(text: '1'),
      unitPrice: TextEditingController(),
    );
  }

  factory _QuoteItemControllers.fromItem(QuotationItem item) {
    return _QuoteItemControllers(
      description: TextEditingController(text: item.description),
      quantity: TextEditingController(text: item.quantity.toString()),
      unitPrice: TextEditingController(text: item.unitPrice.toStringAsFixed(0)),
    );
  }
}
