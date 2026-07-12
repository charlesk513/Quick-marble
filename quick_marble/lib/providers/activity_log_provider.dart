import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../services/activity_log_service.dart';
import 'auth_provider.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) {
    return Stream.value(const <ActivityLog>[]);
  }

  final officeId = user.isAdministrator ? null : user.assignedOfficeId;

  if (!user.isAdministrator && (officeId == null || officeId.trim().isEmpty)) {
    return Stream.value(const <ActivityLog>[]);
  }

  return ref.watch(activityLogServiceProvider).watchLogs(
        officeId: officeId,
      );
});

final visibleActivityLogsProvider = Provider<List<ActivityLog>>((ref) {
  return ref.watch(activityLogsProvider).valueOrNull ?? const <ActivityLog>[];
});
