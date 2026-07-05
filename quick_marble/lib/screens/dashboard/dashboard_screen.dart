import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/themes/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/app_router.dart';
import '../shared/money_text.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return _DashboardContent(user: user);
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final AppUser user;
  const _DashboardContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Marble'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      drawer: _AppDrawer(user: user),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.green,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('A Service On Your Time', style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            user.isAdministrator ? '${user.role.label} · All offices' : '${user.role.label} · ${user.assignedOfficeId}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _StatCard(title: 'Clients', value: stats.clients.toString(), icon: Icons.people_outline),
                _StatCard(title: 'Quotations', value: stats.quotations.toString(), icon: Icons.request_quote_outlined),
                _StatCard(title: 'Pending', value: stats.pendingQuotations.toString(), icon: Icons.pending_actions_outlined),
                _StatCard(title: 'Contracts', value: stats.contracts.toString(), icon: Icons.assignment_turned_in_outlined),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Snapshot', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    _MoneyLine(label: 'Quotation value', amount: stats.quotationValue),
                    _MoneyLine(label: 'Contract value', amount: stats.contractValue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickAction(label: 'Clients', icon: Icons.people_outline, route: AppRoutes.clients),
                _QuickAction(label: 'Quotations', icon: Icons.request_quote_outlined, route: AppRoutes.quotations),
                _QuickAction(label: 'Contracts', icon: Icons.assignment_turned_in_outlined, route: AppRoutes.contracts),
                _QuickAction(label: 'Reports', icon: Icons.bar_chart_outlined, route: AppRoutes.reports),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final double amount;
  const _MoneyLine({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), MoneyText(amount, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  const _QuickAction({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => context.push(route),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  final AppUser user;
  const _AppDrawer({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.green,
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(user.role.label, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                ],
              ),
            ),
            _DrawerTile(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRoutes.dashboard),
            _DrawerTile(icon: Icons.people_outline, label: 'Clients', route: AppRoutes.clients),
            _DrawerTile(icon: Icons.request_quote_outlined, label: 'Quotations', route: AppRoutes.quotations),
            _DrawerTile(icon: Icons.assignment_turned_in_outlined, label: 'Contracts', route: AppRoutes.contracts),
            _DrawerTile(icon: Icons.notifications_active_outlined, label: 'Activity', route: AppRoutes.activity),
            _DrawerTile(icon: Icons.bar_chart_outlined, label: 'Reports', route: AppRoutes.reports),
            if (user.isAdministrator)
              _DrawerTile(icon: Icons.settings_outlined, label: 'Settings', route: AppRoutes.settings),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.red),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerTile({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
