import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/office_provider.dart';
import '../../widgets/empty_state.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(visibleClientsProvider).where((client) {
      final text = '${client.name} ${client.phone} ${client.address}'.toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search clients by name, phone or location',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: clients.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No clients yet',
                    message: 'Add clients for each office before creating quotations.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: clients.length,
                    itemBuilder: (context, index) => _ClientCard(
                      client: clients[index],
                      onEdit: () => _showClientSheet(context, client: clients[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClientSheet(BuildContext context, {Client? client}) async {
    final user = ref.read(currentUserProvider);
    final offices = ref.read(activeOfficesProvider);
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: client?.name ?? '');
    final phone = TextEditingController(text: client?.phone ?? '');
    final email = TextEditingController(text: client?.email ?? '');
    final address = TextEditingController(text: client?.address ?? '');
    final notes = TextEditingController(text: client?.notes ?? '');
    String officeId = client?.officeId ?? user?.assignedOfficeId ?? (offices.isNotEmpty ? offices.first.id : 'nansana');

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
                  Text(client == null ? 'New Client' : 'Edit Client', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (user?.isAdministrator == true)
                    DropdownButtonFormField<String>(
                      value: officeId,
                      decoration: const InputDecoration(labelText: 'Office'),
                      items: offices.map((office) => DropdownMenuItem(value: office.id, child: Text(office.name))).toList(),
                      onChanged: (value) => setModalState(() => officeId = value ?? officeId),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Client name'), validator: _required),
                  const SizedBox(height: 12),
                  TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, validator: _required),
                  const SizedBox(height: 12),
                  TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email optional'), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Address / Location'), validator: _required),
                  const SizedBox(height: 12),
                  TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final controller = ref.read(clientControllerProvider.notifier);
                        if (client == null) {
                          await controller.createClient(
                            officeId: officeId,
                            name: name.text.trim(),
                            phone: phone.text.trim(),
                            email: email.text.trim(),
                            address: address.text.trim(),
                            notes: notes.text.trim(),
                          );
                        } else {
                          await controller.updateClient(client.copyWith(
                            officeId: officeId,
                            name: name.text.trim(),
                            phone: phone.text.trim(),
                            email: email.text.trim(),
                            address: address.text.trim(),
                            notes: notes.text.trim(),
                          ));
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(client == null ? 'Save Client' : 'Update Client'),
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

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}

class _ClientCard extends ConsumerWidget {
  final Client client;
  final VoidCallback onEdit;
  const _ClientCard({required this.client, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canEdit = user?.canEditOffice(client.officeId) ?? false;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : '?')),
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${client.phone}\n${client.address}', maxLines: 2),
        isThreeLine: true,
        trailing: canEdit ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit) : null,
      ),
    );
  }
}
