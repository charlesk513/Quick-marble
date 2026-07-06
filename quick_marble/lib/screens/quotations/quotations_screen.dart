import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/client.dart';
import '../../models/material_item.dart';
import '../../models/quotation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/office_provider.dart';
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
                      onEdit: () => _showQuotationSheet(
                        context,
                        quotation: filtered[index],
                      ),
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
    final user = ref.read(currentUserProvider);
    final offices = ref.read(activeOfficesProvider);
    final materials = ref.read(activeMaterialsProvider);
    final clients =
        ref.read(visibleClientsProvider).where((c) => c.isActive).toList();

    final formKey = GlobalKey<FormState>();
    var creatingNewClient = quotation == null && clients.isEmpty;

    Client? selectedClient = clients.isNotEmpty
        ? quotation == null
            ? clients.first
            : clients.firstWhere(
                (c) => c.id == quotation.clientId,
                orElse: () => clients.first,
              )
        : null;

    String newClientOfficeId =
        user?.assignedOfficeId ?? selectedClient?.officeId ?? offices.first.id;

    final newClientName = TextEditingController();
    final newClientPhone = TextEditingController();
    final newClientAddress = TextEditingController();
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
                    if (quotation == null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            const Text('Create new client for this quotation'),
                        value: creatingNewClient,
                        onChanged: (value) {
                          setModalState(() => creatingNewClient = value);
                        },
                      ),
                    if (!creatingNewClient)
                      DropdownButtonFormField<String>(
                        initialValue: selectedClient?.id,
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
                        validator: (value) =>
                            value == null ? 'Select a client' : null,
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            selectedClient =
                                clients.firstWhere((c) => c.id == value);
                          });
                        },
                      )
                    else ...[
                      if (user?.isAdministrator == true)
                        DropdownButtonFormField<String>(
                          initialValue: newClientOfficeId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Office'),
                          items: offices
                              .map(
                                (office) => DropdownMenuItem(
                                  value: office.id,
                                  child: Text(office.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => newClientOfficeId = value);
                          },
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newClientName,
                        decoration:
                            const InputDecoration(labelText: 'Client name'),
                        validator: creatingNewClient ? _required : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newClientPhone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                        validator: creatingNewClient ? _required : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newClientAddress,
                        decoration: const InputDecoration(
                          labelText: 'Address / Location',
                        ),
                        validator: creatingNewClient ? _required : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...itemControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      MaterialItem? selectedMaterial() {
                        if (item.materialId == null) return null;
                        return materials
                            .where((material) => material.id == item.materialId)
                            .firstOrNull;
                      }

                      void recalculateMaterialPrice() {
                        final material = selectedMaterial();
                        if (material == null) return;

                        item.description.text = material.name;
                        item.quantity.text = '1';

                        final width =
                            double.tryParse(item.widthCm.text.trim()) ?? 0;
                        final length =
                            double.tryParse(item.lengthCm.text.trim()) ?? 0;

                        if (width <= 0 || length <= 0) {
                          item.unitPrice.clear();
                          return;
                        }

                        final price = QuotationItem.granitePrice(
                          widthCm: width,
                          lengthCm: length,
                          cost: material.sellingPricePerUnit,
                        );

                        item.unitPrice.text = price.toStringAsFixed(0);
                      }

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
                                          fontWeight: FontWeight.bold),
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
                              SegmentedButton<QuotationItemType>(
                                segments: const [
                                  ButtonSegment(
                                    value: QuotationItemType.manual,
                                    label: Text('Manual'),
                                    icon: Icon(Icons.edit_note),
                                  ),
                                  ButtonSegment(
                                    value: QuotationItemType.material,
                                    label: Text('Material'),
                                    icon: Icon(Icons.square_foot),
                                  ),
                                ],
                                selected: {item.type},
                                onSelectionChanged: (values) {
                                  setModalState(() {
                                    item.type = values.first;
                                    if (item.type ==
                                            QuotationItemType.material &&
                                        materials.isNotEmpty) {
                                      item.materialId ??= materials.first.id;
                                      item.description.text = materials
                                          .firstWhere(
                                            (material) =>
                                                material.id == item.materialId,
                                          )
                                          .name;
                                      item.quantity.text = '1';
                                      recalculateMaterialPrice();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              if (item.type == QuotationItemType.material) ...[
                                DropdownButtonFormField<String>(
                                  initialValue: item.materialId ??
                                      materials.firstOrNull?.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Material'),
                                  items: materials
                                      .map(
                                        (material) => DropdownMenuItem(
                                          value: material.id,
                                          child: Text(material.name),
                                        ),
                                      )
                                      .toList(),
                                  validator: (_) => materials.isEmpty
                                      ? 'Add materials in Settings first'
                                      : null,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setModalState(() {
                                      item.materialId = value;
                                      final material = materials
                                          .firstWhere((m) => m.id == value);
                                      item.description.text = material.name;
                                      item.quantity.text = '1';
                                      recalculateMaterialPrice();
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: item.widthCm,
                                        decoration: const InputDecoration(
                                            labelText: 'Width cm'),
                                        keyboardType: TextInputType.number,
                                        validator: _positiveNumber,
                                        onChanged: (_) {
                                          recalculateMaterialPrice();
                                          setModalState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: item.lengthCm,
                                        decoration: const InputDecoration(
                                            labelText: 'Length cm'),
                                        keyboardType: TextInputType.number,
                                        validator: _positiveNumber,
                                        onChanged: (_) {
                                          recalculateMaterialPrice();
                                          setModalState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: item.unitPrice,
                                  decoration: const InputDecoration(
                                    labelText: 'Calculated price',
                                    prefixText: 'UGX ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: _positiveNumber,
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: item.description,
                                  decoration: const InputDecoration(
                                      labelText: 'Description'),
                                  validator: _required,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: item.quantity,
                                        decoration: const InputDecoration(
                                            labelText: 'Qty'),
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
                                            labelText: 'Unit price'),
                                        keyboardType: TextInputType.number,
                                        validator: _positiveNumber,
                                        onChanged: (_) => setModalState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                                  quantity:
                                      double.parse(item.quantity.text.trim()),
                                  unitPrice:
                                      double.parse(item.unitPrice.text.trim()),
                                  type: item.type,
                                  materialId: item.materialId,
                                  materialName: materials
                                      .where((material) =>
                                          material.id == item.materialId)
                                      .map((material) => material.name)
                                      .firstOrNull,
                                  widthCm:
                                      double.tryParse(item.widthCm.text.trim()),
                                  lengthCm: double.tryParse(
                                      item.lengthCm.text.trim()),
                                ),
                              )
                              .toList();

                          final controller =
                              ref.read(quotationControllerProvider.notifier);

                          if (quotation == null) {
                            final clientForQuote = creatingNewClient
                                ? await ref
                                    .read(clientControllerProvider.notifier)
                                    .createClient(
                                      officeId: newClientOfficeId,
                                      name: newClientName.text.trim(),
                                      phone: newClientPhone.text.trim(),
                                      email: '',
                                      address: newClientAddress.text.trim(),
                                      notes: 'Created from quotation screen.',
                                    )
                                : selectedClient!;

                            await controller.createQuotation(
                              officeId: clientForQuote.officeId,
                              clientId: clientForQuote.id,
                              clientName: clientForQuote.name,
                              items: items,
                              notes: notes.text.trim(),
                            );
                          } else {
                            final clientForQuote = selectedClient!;

                            await controller.updateQuotation(
                              quotation.copyWith(
                                officeId: clientForQuote.officeId,
                                clientId: clientForQuote.id,
                                clientName: clientForQuote.name,
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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
        ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Chip(label: Text(quotation.status.label)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quotation.clientName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...quotation.items.map((item) => _QuotationItemView(item: item)),
              const Divider(height: 24),
              _AmountRow(label: 'Subtotal', value: quotation.subtotal),
              _AmountRow(label: 'VAT 18%', value: quotation.vat),
              _AmountRow(
                label: 'Total',
                value: quotation.total,
                bold: true,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (quotation.status == QuotationStatus.draft)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (quotation.status == QuotationStatus.draft)
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(quotationControllerProvider.notifier)
                          .updateStatus(
                            quotation.id,
                            QuotationStatus.pendingApproval,
                          ),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Submit'),
                    ),
                  if (quotation.status == QuotationStatus.pendingApproval) ...[
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(quotationControllerProvider.notifier)
                          .updateStatus(
                            quotation.id,
                            QuotationStatus.approved,
                          ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(quotationControllerProvider.notifier)
                          .updateStatus(
                            quotation.id,
                            QuotationStatus.rejected,
                          ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Reject'),
                    ),
                  ],
                  if (quotation.status == QuotationStatus.approved)
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(contractControllerProvider.notifier)
                            .createFromQuotation(quotation);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contract created.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Create Contract'),
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

class _QuotationItemView extends StatelessWidget {
  final QuotationItem item;

  const _QuotationItemView({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.type == QuotationItemType.material) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.square_foot, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.materialName ?? item.description,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Width: ${item.widthCm?.toStringAsFixed(0) ?? '-'}cm · '
                    'Length: ${item.lengthCm?.toStringAsFixed(0) ?? '-'}cm',
                  ),
                  Text('Calculated: ${formatUgx(item.unitPrice)}'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.description}\n${item.quantity} × ${formatUgx(item.unitPrice)}',
            ),
          ),
        ],
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
  final TextEditingController widthCm;
  final TextEditingController lengthCm;

  QuotationItemType type;
  String? materialId;

  _QuoteItemControllers({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.widthCm,
    required this.lengthCm,
    required this.type,
    required this.materialId,
  });

  factory _QuoteItemControllers.empty() {
    return _QuoteItemControllers(
      description: TextEditingController(),
      quantity: TextEditingController(text: '1'),
      unitPrice: TextEditingController(),
      widthCm: TextEditingController(),
      lengthCm: TextEditingController(),
      type: QuotationItemType.manual,
      materialId: null,
    );
  }

  factory _QuoteItemControllers.fromItem(QuotationItem item) {
    return _QuoteItemControllers(
      description: TextEditingController(text: item.description),
      quantity: TextEditingController(text: item.quantity.toString()),
      unitPrice: TextEditingController(text: item.unitPrice.toStringAsFixed(0)),
      widthCm:
          TextEditingController(text: item.widthCm?.toStringAsFixed(0) ?? ''),
      lengthCm:
          TextEditingController(text: item.lengthCm?.toStringAsFixed(0) ?? ''),
      type: item.type,
      materialId: item.materialId,
    );
  }
}
