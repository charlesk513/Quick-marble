import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/activity_log.dart';
import '../../providers/activity_log_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _query = '';
  ActivityAction? _actionFilter;

  @override
  Widget build(BuildContext context) {
    final asyncLogs = ref.watch(activityLogsProvider);
    final visibleLogs = ref.watch(visibleActivityLogsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Activity & Notifications'),
      ),
      body: asyncLogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ActivityError(
          message: error.toString(),
          onRetry: () => ref.invalidate(activityLogsProvider),
        ),
        data: (_) {
          final filtered = visibleLogs.where((log) {
            final haystack =
                '${log.actorName} ${log.action.label} ${log.entityType} '
                        '${log.entityLabel} ${log.message}'
                    .toLowerCase();

            final matchesQuery = haystack.contains(_query.trim().toLowerCase());
            final matchesAction =
                _actionFilter == null || log.action == _actionFilter;

            return matchesQuery && matchesAction;
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search activity, user or record',
                      ),
                      onChanged: (value) {
                        setState(() => _query = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ActivityAction?>(
                      initialValue: _actionFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Activity type',
                      ),
                      items: [
                        const DropdownMenuItem<ActivityAction?>(
                          value: null,
                          child: Text('All activity'),
                        ),
                        ...ActivityAction.values.map(
                          (action) => DropdownMenuItem<ActivityAction?>(
                            value: action,
                            child: Text(action.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _actionFilter = value);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_active_outlined,
                        title: 'No activity found',
                        message:
                            'Important actions will appear here as staff use the system.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(activityLogsProvider);
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _ActivityCard(log: filtered[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityLog log;

  const _ActivityCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(log.action);
    final timestamp =
        DateFormat.yMMMd().add_jm().format(log.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visual.color.withValues(alpha: 0.14),
          foregroundColor: visual.color,
          child: Icon(visual.icon),
        ),
        title: Text(
          '${log.action.label} ${log.entityType}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
              if (log.entityLabel.isNotEmpty) log.entityLabel,
              if (log.message.isNotEmpty) log.message,
              '${log.actorName} · $timestamp',
            ].join('\n'),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  _ActivityVisual _visualFor(ActivityAction action) {
    return switch (action) {
      ActivityAction.created => const _ActivityVisual(
          Icons.add_circle_outline,
          Colors.green,
        ),
      ActivityAction.updated => const _ActivityVisual(
          Icons.edit_outlined,
          Colors.blue,
        ),
      ActivityAction.submitted => const _ActivityVisual(
          Icons.send_outlined,
          Colors.indigo,
        ),
      ActivityAction.approved => const _ActivityVisual(
          Icons.check_circle_outline,
          Colors.green,
        ),
      ActivityAction.rejected => const _ActivityVisual(
          Icons.cancel_outlined,
          Colors.red,
        ),
      ActivityAction.cancelled => const _ActivityVisual(
          Icons.block_outlined,
          Colors.red,
        ),
      ActivityAction.completed => const _ActivityVisual(
          Icons.verified_outlined,
          Colors.green,
        ),
      ActivityAction.payment => const _ActivityVisual(
          Icons.payments_outlined,
          Colors.teal,
        ),
      ActivityAction.login => const _ActivityVisual(
          Icons.login_outlined,
          Colors.blueGrey,
        ),
      ActivityAction.uploaded => const _ActivityVisual(
          Icons.cloud_upload_outlined,
          Colors.deepPurple,
        ),
      ActivityAction.generated => const _ActivityVisual(
          Icons.picture_as_pdf_outlined,
          Colors.red,
        ),
      ActivityAction.scheduled => const _ActivityVisual(
          Icons.event_outlined,
          Colors.orange,
        ),
      ActivityAction.activated => const _ActivityVisual(
          Icons.play_circle_outline,
          Colors.green,
        ),
    };
  }
}

class _ActivityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ActivityError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityVisual {
  final IconData icon;
  final Color color;

  const _ActivityVisual(this.icon, this.color);
}
