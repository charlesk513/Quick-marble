import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../providers/auth_provider.dart';
import '../services/activity_log_service.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  return ref.watch(activityLogServiceProvider).watchLogs();
});

final visibleActivityLogsProvider = Provider<List<ActivityLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  final logs = ref.watch(activityLogsProvider).valueOrNull ?? [];

  if (user == null) return [];
  if (user.isAdministrator) return logs;

  return logs.where((log) => log.officeId == user.assignedOfficeId).toList();
});
