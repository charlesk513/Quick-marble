import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/company_settings_provider.dart';
import '../../routes/app_router.dart';

class SettingsHomeScreen extends ConsumerStatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  ConsumerState<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends ConsumerState<SettingsHomeScreen> {
  final _vatRateController = TextEditingController();
  bool _rateControllerInitialized = false;

  @override
  void dispose() {
    _vatRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(companySettingsStreamProvider);
    final settings = ref.watch(companySettingsProvider);
    final saveState = ref.watch(companySettingsControllerProvider);

    if (!_rateControllerInitialized) {
      _vatRateController.text = (settings.vatRate * 100).toStringAsFixed(0);
      _rateControllerInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Could not load settings.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(companySettingsStreamProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (_) => ListView(
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
                      subtitle:
                          const Text('Apply VAT to quotations and reports'),
                      value: settings.vatEnabled,
                      onChanged: saveState.isLoading
                          ? null
                          : (value) async {
                              try {
                                await ref
                                    .read(companySettingsControllerProvider
                                        .notifier)
                                    .setVatEnabled(settings, value);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not save VAT setting: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vatRateController,
                      decoration: const InputDecoration(
                        labelText: 'VAT rate (%)',
                        suffixText: '%',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: settings.vatEnabled && !saveState.isLoading,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: !settings.vatEnabled || saveState.isLoading
                            ? null
                            : () async {
                                final parsed = double.tryParse(
                                  _vatRateController.text.trim(),
                                );

                                if (parsed == null ||
                                    parsed < 0 ||
                                    parsed > 100) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter a VAT rate between 0 and 100.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await ref
                                      .read(companySettingsControllerProvider
                                          .notifier)
                                      .setVatRate(settings, parsed / 100);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'VAT settings saved.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not save VAT rate: $error',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: saveState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          saveState.isLoading ? 'Saving...' : 'Save VAT Rate',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SettingsTile(
              icon: Icons.business_outlined,
              title: 'Company Profile',
              subtitle: 'Coming soon',
              onTap: null,
            ),
          ],
        ),
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
