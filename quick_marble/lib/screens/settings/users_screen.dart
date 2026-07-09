import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/themes/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/office.dart';
import '../../providers/office_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_router.dart';
import '../../services/user_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);
    final officesAsync = ref.watch(officesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.settings),
        ),
        title: const Text('Users'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context, ref),
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add User'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Failed to load users: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No staff yet',
              message: 'Add your first team member using the button below.',
            );
          }
          final offices = officesAsync.valueOrNull ?? [];
          final sorted = [...users]..sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final user = sorted[index];
              final officeName = user.assignedOfficeId == null
                  ? 'All offices'
                  : offices
                      .firstWhere(
                        (o) => o.id == user.assignedOfficeId,
                        orElse: () => Office(
                          id: user.assignedOfficeId!,
                          name: user.assignedOfficeId!,
                          location: '',
                          isActive: true,
                          createdAt: DateTime.now(),
                        ),
                      )
                      .name;

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: user.isActive
                        ? AppColors.green.withValues(alpha: 0.15)
                        : Colors.grey[300],
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            user.isActive ? AppColors.green : Colors.grey[600],
                      ),
                    ),
                  ),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text('${user.role.label} · $officeName\n${user.email}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: user.isActive,
                        activeThumbColor: AppColors.green,
                        onChanged: (value) =>
                            _toggleActive(context, ref, user, value),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showUserForm(context, ref, user: user),
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
    AppUser user,
    bool newValue,
  ) async {
    if (!newValue) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Deactivate ${user.name}?',
        message: 'They will no longer be able to sign in. This does not delete '
            'their past records or activity history.',
        confirmLabel: 'Deactivate',
        isDestructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref
          .read(userControllerProvider.notifier)
          .setUserActive(user.uid, newValue);
    } on UserException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
      );
    }
  }

  void _showUserForm(BuildContext context, WidgetRef ref, {AppUser? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserFormSheet(user: user),
    );
  }
}

class _UserFormSheet extends ConsumerStatefulWidget {
  final AppUser? user;
  const _UserFormSheet({this.user});

  @override
  ConsumerState<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends ConsumerState<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late UserRole _role;
  String? _officeId;
  bool _isSubmitting = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _role = widget.user?.role ?? UserRole.salesOfficer;
    _officeId = widget.user?.assignedOfficeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role != UserRole.administrator && _officeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an office for this role.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(userControllerProvider.notifier);
      if (_isEditing) {
        await controller.updateUser(widget.user!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _role,
          assignedOfficeId: _role == UserRole.administrator ? null : _officeId,
          clearAssignedOfficeId: _role == UserRole.administrator,
        ));
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated.')),
        );
      } else {
        await controller.createUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _role,
          assignedOfficeId: _role == UserRole.administrator ? null : _officeId,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        _showTempPasswordDialog(context, _emailController.text.trim());
      }
    } on UserException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showTempPasswordDialog(BuildContext context, String email) {
    // In production this account is created via a Cloud Function which
    // generates a real temporary password (or sends a Firebase invite
    // link). Shown here so the flow is realistic even before Firebase
    // wiring lands.
    final tempPassword = _generateTempPassword();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Created'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share these temporary sign-in details with $email:'),
            const SizedBox(height: 12),
            SelectableText('Email: $email'),
            SelectableText('Temporary password: $tempPassword'),
            const SizedBox(height: 12),
            Text(
              'They should change this password after first login.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final rand = Random();
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final offices = ref.watch(activeOfficesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit User' : 'Add User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled:
                    !_isEditing, // email is the login identifier; keep it immutable here
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  helperText:
                      _isEditing ? 'Email cannot be changed here' : null,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Phone is required'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _role = value;
                    if (value == UserRole.administrator) _officeId = null;
                  });
                },
              ),
              if (_role != UserRole.administrator) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue:
                      offices.any((o) => o.id == _officeId) ? _officeId : null,
                  decoration:
                      const InputDecoration(labelText: 'Assigned Office'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Select office'),
                    ),
                    ...offices.map(
                      (o) => DropdownMenuItem<String?>(
                        value: o.id,
                        child: Text(o.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _officeId = value),
                  validator: (v) => v == null ? 'Select an office' : null,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
