import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/client_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../routes/app_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(visibleClientsProvider);
    final quotations = ref.watch(visibleQuotationsProvider);
    final contracts = ref.watch(visibleContractsProvider);

    final q = query.toLowerCase().trim();

    final matchingClients = q.isEmpty
        ? []
        : clients.where((c) {
            return '${c.name} ${c.phone} ${c.email} ${c.address}'
                .toLowerCase()
                .contains(q);
          }).toList();

    final matchingQuotations = q.isEmpty
        ? []
        : quotations.where((quote) {
            return '${quote.number} ${quote.clientName} ${quote.notes}'
                .toLowerCase()
                .contains(q);
          }).toList();

    final matchingContracts = q.isEmpty
        ? []
        : contracts.where((contract) {
            return '${contract.number} ${contract.clientName} ${contract.quotationNumber} ${contract.notes}'
                .toLowerCase()
                .contains(q);
          }).toList();

    final hasResults = matchingClients.isNotEmpty ||
        matchingQuotations.isNotEmpty ||
        matchingContracts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Search'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search client, quotation, contract...',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          if (q.isEmpty)
            const Center(child: Text('Type to search records.'))
          else if (!hasResults)
            const Center(child: Text('No results found.'))
          else ...[
            ...matchingClients.map(
              (client) => _SearchTile(
                icon: Icons.person_outline,
                title: client.name,
                subtitle: 'Client · ${client.phone}',
                onTap: () => context.go(AppRoutes.clients),
              ),
            ),
            ...matchingQuotations.map(
              (quote) => _SearchTile(
                icon: Icons.request_quote_outlined,
                title: quote.number,
                subtitle: 'Quotation · ${quote.clientName}',
                onTap: () => context.go(AppRoutes.quotations),
              ),
            ),
            ...matchingContracts.map(
              (contract) => _SearchTile(
                icon: Icons.assignment_turned_in_outlined,
                title: contract.number,
                subtitle: 'Contract / Project · ${contract.clientName}',
                onTap: () => context.push('/project/${contract.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
