import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/office_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';

enum _ClientStatusFilter { all, active, inactive }

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';
  String? _officeFilter;
  _ClientStatusFilter _statusFilter = _ClientStatusFilter.active;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final offices = ref.watch(activeOfficesProvider);
    final allClients = ref.watch(visibleClientsProvider);

    final clients = allClients.where((client) {
      final searchText =
          '${client.name} ${client.phone} ${client.email} ${client.address} ${client.notes}'
              .toLowerCase();

      final matchesSearch = searchText.contains(_query.toLowerCase());

      final matchesOffice =
          _officeFilter == null || client.officeId == _officeFilter;

      final matchesStatus = switch (_statusFilter) {
        _ClientStatusFilter.all => true,
        _ClientStatusFilter.active => client.isActive,
        _ClientStatusFilter.inactive => !client.isActive,
      };

      return matchesSearch && matchesOffice && matchesStatus;
    }).toList();

    final activeCount = allClients.where((client) => client.isActive).length;
    final inactiveCount = allClients.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Clients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Client'),
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
                      child: _ClientStatCard(
                        title: 'Active',
                        value: activeCount.toString(),
                        icon: Icons.people_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ClientStatCard(
                        title: 'Inactive',
                        value: inactiveCount.toString(),
                        icon: Icons.person_off_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search name, phone, email, location',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_ClientStatusFilter>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: _ClientStatusFilter.all,
                            child: Text('All clients'),
                          ),
                          DropdownMenuItem(
                            value: _ClientStatusFilter.active,
                            child: Text('Active only'),
                          ),
                          DropdownMenuItem(
                            value: _ClientStatusFilter.inactive,
                            child: Text('Inactive only'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    if (user?.isAdministrator == true) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _officeFilter,
                          decoration: const InputDecoration(
                            labelText: 'Office',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All offices'),
                            ),
                            ...offices.map(
                              (office) => DropdownMenuItem<String?>(
                                value: office.id,
                                child: Text(office.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _officeFilter = value);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: clients.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No clients found',
                    message: 'Add clients or change your search filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: clients.length,
                    itemBuilder: (context, index) => _ClientCard(
                      client: clients[index],
                      onEdit: () =>
                          _showClientSheet(context, client: clients[index]),
                      onToggleActive: () =>
                          _toggleClientActive(context, clients[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleClientActive(BuildContext context, Client client) async {
    final action = client.isActive ? 'deactivate' : 'reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} client?'),
        content: Text('Are you sure you want to $action ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(client.isActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(clientControllerProvider.notifier)
        .setClientActive(client.id, !client.isActive);
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

    String? officeId = client?.officeId ??
        user?.assignedOfficeId ??
        (offices.isNotEmpty ? offices.first.id : 'nansana');
    // ignore: unnecessary_null_comparison
    if (officeId == null || !offices.any((office) => office.id == officeId)) {
      officeId = offices.isNotEmpty ? offices.first.id : null;
    }

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
                  Text(
                    client == null ? 'New Client' : 'Edit Client',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (user?.isAdministrator == true)
                    offices.isEmpty
                        ? const Text(
                            'No active offices found. Add an office first.')
                        : DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: officeId ?? offices.first.id,
                            decoration:
                                const InputDecoration(labelText: 'Office'),
                            items: offices
                                .map(
                                  (office) => DropdownMenuItem<String>(
                                    value: office.id,
                                    child: Text(office.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => officeId = value);
                            },
                          ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Client name'),
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    decoration:
                        const InputDecoration(labelText: 'Email optional'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _emailOptional,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    decoration:
                        const InputDecoration(labelText: 'Address / Location'),
                    textInputAction: TextInputAction.next,
                    validator: _required,
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
                      icon: const Icon(Icons.save_outlined),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final controller =
                            ref.read(clientControllerProvider.notifier);

                        if (client == null) {
                          await controller.createClient(
                            officeId: officeId!,
                            name: name.text.trim(),
                            phone: phone.text.trim(),
                            email: email.text.trim(),
                            address: address.text.trim(),
                            notes: notes.text.trim(),
                          );
                        } else {
                          await controller.updateClient(
                            client.copyWith(
                              officeId: officeId!,
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                              email: email.text.trim(),
                              address: address.text.trim(),
                              notes: notes.text.trim(),
                            ),
                          );
                        }

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      label: Text(client == null ? 'Save Client' : 'Update'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // name.dispose();
    // phone.dispose();
    // email.dispose();
    // address.dispose();
    // notes.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _emailOptional(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.contains('@') ? null : 'Enter a valid email';
  }
}

class _ClientStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ClientStatCard({
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
            const SizedBox(width: 10),
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

class _ClientCard extends ConsumerWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _ClientCard({
    required this.client,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final offices = ref.watch(activeOfficesProvider);
    final officeName = offices
        .where((office) => office.id == client.officeId)
        .map((office) => office.name)
        .firstOrNull;

    final canEdit = user?.canEditOffice(client.officeId) ?? false;

    return Opacity(
      opacity: client.isActive ? 1 : 0.55,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text(
              client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            ),
          ),
          title: Text(
            client.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [
                client.phone,
                if (client.email.isNotEmpty) client.email,
                client.address,
                if (officeName != null) officeName,
              ].join('\n'),
            ),
          ),
          isThreeLine: true,
          trailing: canEdit
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggleActive();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        client.isActive ? 'Deactivate' : 'Reactivate',
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
