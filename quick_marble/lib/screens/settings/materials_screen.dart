import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/material_item.dart';
import '../../providers/material_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(materialsStreamProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMaterialDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Material'),
      ),
      body: materials.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No materials',
              message: 'Add your first granite or marble material.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];

                return Card(
                  child: ListTile(
                    title: Text(material.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(material.category),
                        Text(
                          'Cost: UGX ${material.costPerUnit.toStringAsFixed(0)}',
                        ),
                        Text(
                          'Selling: UGX ${material.sellingPricePerUnit.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: material.isActive,
                      onChanged: (value) {
                        ref
                            .read(materialControllerProvider.notifier)
                            .setMaterialActive(material.id, value);
                      },
                    ),
                    onTap: () =>
                        _showMaterialDialog(context, ref, material: material),
                  ),
                );
              },
            ),
    );
  }

  static Future<void> _showMaterialDialog(
    BuildContext context,
    WidgetRef ref, {
    MaterialItem? material,
  }) async {
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(text: material?.name ?? '');
    final category = TextEditingController(text: material?.category ?? '');
    final cost = TextEditingController(
      text: material?.costPerUnit.toStringAsFixed(0) ?? '',
    );
    final selling = TextEditingController(
      text: material?.sellingPricePerUnit.toStringAsFixed(0) ?? '',
    );
    final unit = TextEditingController(
      text: material?.unitLabel ?? 'per 60cm',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          material == null ? 'New Material' : 'Edit Material',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Material name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost Price'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: selling,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Selling Price'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              if (material == null) {
                await ref
                    .read(materialControllerProvider.notifier)
                    .createMaterial(
                      name: name.text.trim(),
                      category: category.text.trim(),
                      costPerUnit: double.parse(cost.text),
                      sellingPricePerUnit: double.parse(selling.text),
                      unitLabel: unit.text.trim(),
                    );
              } else {
                await ref
                    .read(materialControllerProvider.notifier)
                    .updateMaterial(
                      material.copyWith(
                        name: name.text.trim(),
                        category: category.text.trim(),
                        costPerUnit: double.parse(cost.text),
                        sellingPricePerUnit: double.parse(selling.text),
                        unitLabel: unit.text.trim(),
                      ),
                    );
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
