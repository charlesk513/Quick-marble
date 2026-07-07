import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/activity_log.dart';
import '../../providers/activity_log_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(visibleActivityLogsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Activity & Notifications'),
      ),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'No activity yet',
              message:
                  'Important actions will appear here once Firebase sync is connected.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.history)),
                    title: Text('${log.action.label} ${log.entityType}'),
                    subtitle: Text(
                      '${log.message}\n${log.actorName} · ${DateFormat.yMMMd().add_jm().format(log.createdAt)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
