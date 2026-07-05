import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_theme.dart';
import '../../models/office.dart';
import '../../providers/office_provider.dart';
import '../../services/office_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

class OfficesScreen extends ConsumerWidget {
  const OfficesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officesAsync = ref.watch(officesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Offices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOfficeForm(context, ref),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Office'),
      ),
      body: officesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Failed to load offices: $err')),
        data: (offices) {
          if (offices.isEmpty) {
            return const EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'No offices yet',
              message: 'Add your first branch using the button below.',
            );
          }
          final sorted = [...offices]..sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final office = sorted[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(office.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(office.location),
                  leading: CircleAvatar(
                    backgroundColor: office.isActive
                        ? AppColors.green.withOpacity(0.15)
                        : Colors.grey[300],
                    child: Icon(
                      Icons.store_mall_directory_outlined,
                      color: office.isActive ? AppColors.green : Colors.grey[600],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: office.isActive,
                        activeColor: AppColors.green,
                        onChanged: (value) => _toggleActive(context, ref, office, value),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showOfficeForm(context, ref, office: office),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Office office,
    bool newValue,
  ) async {
    if (!newValue) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Disable ${office.name}?',
        message: 'Staff assigned to this office will no longer be able to '
            'create new records here. Existing records are unaffected.',
        confirmLabel: 'Disable',
        isDestructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref.read(officeControllerProvider.notifier).setOfficeActive(office.id, newValue);
    } on OfficeException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
      );
    }
  }

  void _showOfficeForm(BuildContext context, WidgetRef ref, {Office? office}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OfficeFormSheet(office: office),
    );
  }
}

class _OfficeFormSheet extends ConsumerStatefulWidget {
  final Office? office;
  const _OfficeFormSheet({this.office});

  @override
  ConsumerState<_OfficeFormSheet> createState() => _OfficeFormSheetState();
}

class _OfficeFormSheetState extends ConsumerState<_OfficeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  bool _isSubmitting = false;

  bool get _isEditing => widget.office != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name ?? '');
    _locationController = TextEditingController(text: widget.office?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(officeControllerProvider.notifier);
      if (_isEditing) {
        await controller.updateOffice(widget.office!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
        ));
      } else {
        await controller.createOffice(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Office updated.' : 'Office added.')),
      );
    } on OfficeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Office' : 'Add Office',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Office Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Office'),
            ),
          ],
        ),
      ),
    );
  }
}
