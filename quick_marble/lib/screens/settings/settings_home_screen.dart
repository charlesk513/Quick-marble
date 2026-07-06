import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/company_settings_provider.dart';
import '../../routes/app_router.dart';

/// Entry point for admin-only management screens. Only reachable via a
/// route guard that checks `isAdministrator` (see app_router.dart), so
/// this screen doesn't need to re-check the role itself.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(companySettingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsTile(
            icon: Icons.store_mall_directory_outlined,
            title: 'Manage Offices',
            subtitle: 'Add branches, edit details, enable or disable',
            onTap: () => context.push(AppRoutes.settingsOffices),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.people_outline,
            title: 'Manage Users',
            subtitle: 'Add staff, assign roles and offices',
            onTap: () => context.push(AppRoutes.settingsUsers),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Materials',
            subtitle: 'Granite, marble, prices and units',
            onTap: () => context.push(AppRoutes.settingsMaterials),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable VAT'),
                    subtitle: const Text('Apply VAT to quotations and reports'),
                    value: settings.vatEnabled,
                    onChanged: (value) {
                      ref
                          .read(companySettingsProvider.notifier)
                          .setVatEnabled(value);
                    },
                  ),
                  TextFormField(
                    initialValue: (settings.vatRate * 100).toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'VAT rate (%)',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: settings.vatEnabled,
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed == null) return;
                      ref
                          .read(companySettingsProvider.notifier)
                          .setVatRate(parsed / 100);
                    },
                  ),
                ],
              ),
            ),
          ),
          const _SettingsTile(
            icon: Icons.business_outlined,
            title: 'Company Profile',
            subtitle: 'Coming soon',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: disabled
              ? Colors.grey[300]
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            icon,
            color: disabled
                ? Colors.grey[600]
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: disabled ? null : const Icon(Icons.chevron_right),
        enabled: !disabled,
        onTap: onTap,
      ),
    );
  }
}
