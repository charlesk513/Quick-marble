import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/activity_log_provider.dart';
import '../../widgets/empty_state.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(activityLogsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Activity & Notifications')),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'No activity yet',
              message: 'Important actions will appear here once Firebase sync is connected.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.history)),
                    title: Text('${log.action} ${log.entityType}'),
                    subtitle: Text('${log.entityLabel}\n${log.actorName} · ${DateFormat.yMMMd().add_jm().format(log.createdAt)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
